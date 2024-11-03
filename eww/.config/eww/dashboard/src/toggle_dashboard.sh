#!/bin/bash
is_mic_muted=$(pamixer --default-source --get-mute)
is_sink_muted=$(pamixer --get-mute)
mic_icon=""
sink_icon=""
notification_icon=""
if [[ $is_mic_muted == "true" ]]; then
    mic_icon=""
else
    mic_icon=""
fi

if [[ $is_sink_muted == "true" ]]; then
    sink_icon=" "
else
    sink_icon=" "
fi

notification_icon=""

eww open --toggle dashboard
eww update mic_icon="$mic_icon"
eww update sink_icon="$sink_icon"
eww update notification_icon="$notification_icon"
