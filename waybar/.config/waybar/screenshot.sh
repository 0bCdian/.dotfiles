#!/usr/bin/env bash

dir="$(xdg-user-dir PICTURES)/Screenshots"
before=$(ls "$dir" -1q | wc -l)
if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

notify_view() {
  local before="$1"
  after=$(ls "$dir" -1q | wc -l)
  notify_cmd_shot='dunstify -u low -i gnome-screenshot Rofishot --replace=699'
  if [ "$after" -gt "$before" ]; then
    ${notify_cmd_shot} "Screenshot Saved."
  else
    ${notify_cmd_shot} "Screenshot Not Saved."
  fi
}

generate_filename() {
  now=$(date '+%Y%m%d-%H:%M:%S')
  echo "$dir/satty-$now.png"
}

grim -g "$(slurp -o)" - | satty --filename - --output-filename "$(generate_filename)" && notify_view "$1"
