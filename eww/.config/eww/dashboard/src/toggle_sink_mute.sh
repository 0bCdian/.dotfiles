#!/bin/bash
amixer set Master toggle
is_sink_muted=$(pamixer --get-mute)
sink_icon=""
if [[ $is_sink_muted == "true" ]]; then
    sink_icon=" "
else
    sink_icon=" "
fi
echo "$is_sink_muted $sink_icon"
eww update sink_icon="$sink_icon"