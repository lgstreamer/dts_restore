#!/bin/bash

# DTS playback restoration script for LG OLED CX
# Copyright (c) 2022-2023 Pete Batard <pete@akeo.ie>
# See https://github.com/RootMyTV/RootMyTV.github.io/issues/72#issuecomment-1343204028

# Validate that we have the relevant init.d directory
INIT_DIR=/var/lib/webosbrew/init.d
if [[ ! -d $INIT_DIR ]]; then
  echo "$INIT_DIR/ is missing - Aborting"
  exit 1
fi

if [[ ! -f $INIT_DIR/restore_dts ]]; then
  echo "$INIT_DIR/restore_dts is missing - Nothing to uninstall!"
  exit 1
fi

rm $INIT_DIR/restore_dts
echo "DTS playback has been uninstalled - Please reboot your TV"
