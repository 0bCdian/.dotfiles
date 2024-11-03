#!/bin/bash
mic_source=$(pactl info | grep "Default Source" | awk '{print $3}')
pamixer --source "$mic_source" -t
is_muted=$(pamixer --default-source --get-mute)
mic_icon=""
if [[ $is_muted == "true" ]]; then
    mic_icon=""
else
    mic_icon=""
fi
eww update mic_icon=$mic_icon