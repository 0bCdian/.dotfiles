#!/bin/bash
sleep 0.5 && (killall hyprpicker || hyprpicker) | tr -d '\n' | wl-copy && notify-send -a 'Hyprpicker' -i 'color' "Hyprpicker" "Color copied!" -e
