#!/usr/bin/env bash

current=$(brightnessctl get)
max=$(brightnessctl max)
current_pct=$(( current * 100 / max ))

choice=$(printf "  10%%\n  25%%\n  50%%\n  75%%\n  100%%\n  Current: %d%%" \
    "$current_pct" \
    | wofi --show dmenu \
           --prompt "Brightness" \
           --width 320 --height 240 \
           --no-actions \
           --insensitive)

case "$choice" in
    *10%)  brightnessctl set 10% ;;
    *25%)  brightnessctl set 25% ;;
    *50%)  brightnessctl set 50% ;;
    *75%)  brightnessctl set 75% ;;
    *100%) brightnessctl set 100% ;;
esac
