#!/usr/bin/env bash
TEMP_STDIN="$(mktemp)"
sleep 0.1
grimblast copysave area >"$TEMP_STDIN"
IMG="$(cat $TEMP_STDIN)"
notify-send -a "grimblast" -i "$IMG" "Screenshot Taken" $IMG &
disown
