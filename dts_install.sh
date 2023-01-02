#!/bin/bash

# DTS playback restoration script for LG OLED CX
# Copyright (c) 2022-2023 Pete Batard <pete@akeo.ie>
# See https://github.com/RootMyTV/RootMyTV.github.io/issues/72#issuecomment-1343204028

# Set the following to the directory where you have the GST plugins
GST_SRC=/home/root/gst

# Validate that we have the relevant init.d directory
INIT_DIR=/var/lib/webosbrew/init.d
if [[ ! -d $INIT_DIR ]]; then
  echo "$INIT_DIR/ is missing - Aborting"
  exit 1
fi

# Validate that there is a GStreamer registry to override
if [[ ! -f $GST_REGISTRY_1_0 ]]; then
  echo "$GST_REGISTRY_1_0 is missing - Aborting"
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
  echo "cause irreversible damage, if you choose to proceed, you do acknowlegde"
  echo "that, because you are not using the relevant target system:"
  echo "1. The software may not work as expected, it at all."
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

echo "Installing $INIT_DIR/restore_dts"

# The script must *NOT* have a .sh extension
cat <<EOS > $INIT_DIR/restore_dts
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

chmod 755 $INIT_DIR/restore_dts
if [[ ! -f /tmp/gstcool.conf ]]; then
  echo "Running $INIT_DIR/restore_dts"
  source $INIT_DIR/restore_dts
  echo "DTS playback has been permanently re-enabled - Enjoy!"
fi