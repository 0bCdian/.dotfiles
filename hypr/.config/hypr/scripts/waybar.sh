#!/usr/bin/env bash
set -a
source "$(dirname "$0")/.env"
set +a
waybar -c $HOME/.config/waybar/config.jsonc &
waybar -c $HOME/.config/waybar/config2.jsonc &
