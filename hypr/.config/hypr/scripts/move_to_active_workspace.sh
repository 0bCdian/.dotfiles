#/bin/bash
ACTIVE_WORKSPACE="$(hyprctl activeworkspace -j | jq -r .name)"
hyprctl dispatch movetoworkspace "$ACTIVE_WORKSPACE"
