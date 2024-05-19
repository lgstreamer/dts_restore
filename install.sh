#!/usr/bin/env sh
# DTS playback restoration script for LG OLED CX
# Copyright (c) 2022-2024 Pete Batard <pete@akeo.ie>
# See https://github.com/RootMyTV/RootMyTV.github.io/issues/72#issuecomment-1343204028

# Get the path where the script is located.
# Adapted from https://github.com/rmyorston/busybox-w32/issues/154
LAST_COMMAND="$_"  # IMPORTANT: This must be the first command in the script
ps_output="$(ps -o pid,comm | grep -Fw $$)"
for cs in $ps_output; do
  CURRENT_SHELL=$cs
done;
if [[ -n "$BASH_SOURCE" ]]; then
  SCRIPT="${BASH_SOURCE[0]}"
elif [[ "$0" != "$CURRENT_SHELL" ]] && [[ "$0" != "-$CURRENT_SHELL" ]]; then
  SCRIPT="$0"
elif [[ -n "$LAST_COMMAND" ]]; then
  SCRIPT="$LAST_COMMAND"
else
  echo "Could not get script path - Aborting";
  exit 1
fi;

SCRIPT=$(realpath "$SCRIPT" 2>&-)
SCRIPT_DIR=$(dirname "$SCRIPT")

# Set the directory where the GST plugins are located
GST_SRC=$SCRIPT_DIR/gst

# Validate that we have the relevant init.d directory
INIT_DIR=/var/lib/webosbrew/init.d
if [[ ! -d $INIT_DIR ]]; then
  echo "$INIT_DIR/ is missing - Aborting"
  exit 1
fi

# Validate that there is a GStreamer registry to override
if [[ -z "$GST_REGISTRY_1_0" ]] || [[ ! -f "$GST_REGISTRY_1_0" ]]; then
  echo "Could not locate the GStreamer registry on this environment - Aborting"
  echo
  echo "If needed, please make sure that you use an ssh session and not a"
  echo "telnet session when running this installer, as telnet is missing the"
  echo "required environmental variables and is known to cause this issue..."
  exit 1
fi

# Validate that the media player isn't running
MEDIA_PLAYER_INSTANCES=`ps -ef | grep [s]tarfish-media | wc -l`
if [[ $MEDIA_PLAYER_INSTANCES -gt 1 ]]; then
  echo "Cannot install while media player is running - Aborting"
  exit 1
fi

# Validate that the libraries we need are there
for lib in libgstmatroska.so libgstlibav.so; do
  if [[ ! -f "$GST_SRC/$lib" ]]; then
    echo "$GST_SRC/$lib is missing - Aborting"
    exit 1
  fi
done

# Display a notice if not installing on the expected platform
GST_VERSION=`gst-inspect-1.0 --version | grep GStreamer | cut -d " " -f 2`
WEBOS_VERSION=`nyx-cmd OSInfo query webos_release`
MODEL_NAME=`nyx-cmd DeviceInfo query product_id`
if [[ "$GST_VERSION" != "1.14.4" || "${WEBOS_VERSION::1}" != "5" || "${MODEL_NAME::4}" != "OLED" || "${MODEL_NAME:6:2}" != "CX" ]]; then
  echo
  echo "This installer was designed specifically for LG OLED CX TVs running"
  echo "webOS 5.x with Gstreamer 1.14.4. However, you are trying run it on a(n)"
  echo "$MODEL_NAME TV with webOS $WEBOS_VERSION and GStreamer $GST_VERSION."
  echo
  echo "While installing this software on an incompatible platform should not"
  echo "cause irreversible damage, if you choose to proceed, you do acknowledge"
  echo "that, because you are not using the relevant target system:"
  echo "1. The software may not work as expected, if at all."
  echo "2. You may lose existing features and/or functionality."
  echo "3. The entire responsibility for trying this software on an unsupported"
  echo "   platform lies entirely with you."
  echo
  read -r -p "Do you wish to proceed? [y/N] " response
  case "$response" in
  [yY][eE][sS]|[yY]) 
    ;;
  *)
    exit 1
    ;;
  esac
fi

# Create the init script
echo "Creating $SCRIPT_DIR/init_dts.sh"
cat <<EOS > $SCRIPT_DIR/init_dts.sh
#!/bin/bash

# Override the GST plugins that were nerfed by LG
for lib in libgstmatroska.so libgstlibav.so; do
  if [[ -f $GST_SRC/\$lib ]]; then
    echo "Installing /usr/lib/gstreamer-1.0/\$lib override"
    mount -n --bind -o ro $GST_SRC/\$lib /usr/lib/gstreamer-1.0/\$lib
  fi
done

# Override the GST registry
if [[ -f $GST_REGISTRY_1_0 ]]; then
  echo "Installing $GST_REGISTRY_1_0 override"
  export GST_REGISTRY_1_0=/tmp/gst_1_0_registry.arm.bin
  /usr/bin/gst-inspect-1.0 > /var/tmp/gst-inspect.log
  chmod 666 \$GST_REGISTRY_1_0
  chown :compositor \$GST_REGISTRY_1_0
  mount -n --bind \$GST_REGISTRY_1_0 $GST_REGISTRY_1_0
fi

# Override /etc/gst/gstcool.conf
if [[ ! -f /tmp/gstcool.conf ]]; then
  echo "Installing /etc/gst/gstcool.conf override"
  if [[ -f /etc/gst/gstcool.conf ]]; then
    sed "s/avdec_dca=0/avdec_dca=290/" /etc/gst/gstcool.conf > /tmp/gstcool.conf
    cat <<EOT >> /tmp/gstcool.conf

[downmix]
front=1.25
center=0.75
lfe=0.75
rear=0.75
rear2=0.70
EOT
    mount -n --bind /tmp/gstcool.conf /etc/gst/gstcool.conf
  fi
fi
EOS
chmod 755 $SCRIPT_DIR/init_dts.sh

# Install/link the init script into the webosbrew init directory
echo "Creating $INIT_DIR/restore_dts symbolic link"
# The $INIT_DIR script must *NOT* have a .sh extension
ln -s $SCRIPT_DIR/init_dts.sh $INIT_DIR/restore_dts

if [[ ! -f /tmp/gstcool.conf ]]; then
  echo "Running $INIT_DIR/restore_dts"
  source $INIT_DIR/restore_dts || exit 1
  echo "DTS playback has been permanently re-enabled - Enjoy!"
fi
