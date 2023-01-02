This archive contains libraries and scripts needed to restore DTS playback
on LG Smart TVs, such as OLED CX models.

See https://github.com/RootMyTV/RootMyTV.github.io/issues/72 for details.


License and disclaimers:
------------------------

GNU LGPL v2.1 or later (same as the GStreamer project and its plugins)

THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE
SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

THIS SOFTWARE IS *NOT* ENDORSED BY LG OR ANY OF ITS SUBSIDIARIES.


Limitations:
------------

- Root required (https://github.com/RootMyTV/RootMyTV.github.io/issues/85)
- Only mkv playback supported (no .mp4, no .dts).
- Only PCM stereo downmix supported (no multichannel, no passthrough).
- The libraries and scripts have been designed for LG OLED CX models.
  While there is a good chance that, if your TV is not too dissimilar to
  OLED CXs, you might also be able to restore DTS support there, any issue
  that arises from not running this software on an OLED CX is entirely
  yours to troubleshoot and support.


Installation:
-------------

- Open a root shell to your TV (e.g. using ssh)
- Download, extract and run the installer by issuing:
  cd /home/root
  wget https://github.com/lgstreamer/dts_restore/releases/download/1.0/dts_restore_1.0.tgz
  tar -xzvf dts_restore_1.0.tgz
  ./dts_install.sh


Uninstallation:
---------------

- Open a root shell to your TV (e.g. using ssh)
- Run the command: ./home/root/dts_uninstall.sh
- Fully power off or reboot your TV.


Additional notes:
-----------------

- The DTS restoration process does not alter the original LG firmware
  content. All changes are applied in a temporary manner which means that,
  should you want reset media playback to its original behaviour, you can
  just remove the /var/lib/webosbrew/init.d/restore_dts init script or run
  dst_uninstall.sh.
- If you still see the "This video does not support audio" message on first
  attempt, just close the video file and try again.
- If you want to adjust the stereo downmix settings, you can edit the
  [downmix] section from /var/lib/webosbrew/init.d/restore_dts (permanent)
  of /etc/gst/gstcool.conf (temporary).


Source code:
------------

- libgstmatroska.so was compiled from the 1.14.4 LG 'gst-plugins-good'
  source for OLED CX models, with matroska audio DTS demuxing re-enabled.
  The complete source for it, along with compilation instructions, can be
  found at: https://github.com/lgstreamer/gst-plugins-good
- libgstlibav.so was compiled from the 1.14.4 LG 'gst-libav' source for
  OLED CX models with the following changes applied for DTS (dca) decoding:
  * Force stereo downmix always.
  * Force integer output always.
  * Allow the reading of downmix coefficient from gstcool.conf.
  The complete source for it, along with compilation instructions, can be
  found at: https://github.com/lgstreamer/gst-libav
