#!/bin/bash

is_paused=$(swaync-client -d -sw)
notification_icon=""

if [ "$is_paused" = "true" ]
then notification_icon="󰂛" 
else
notification_icon="󰂚"
fi

eww update notification_icon=$notification_icon
