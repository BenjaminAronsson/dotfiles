#!/usr/bin/env bash

choice=$(printf "  Shutdown\n  Reboot\n  Suspend\n  Logout" \
    | wofi --show dmenu \
           --prompt "Power" \
           --width 320 --height 220 \
           --no-actions \
           --insensitive)

case "$choice" in
    *Shutdown) systemctl poweroff ;;
    *Reboot)   systemctl reboot ;;
    *Suspend)  systemctl suspend ;;
    *Logout)   hyprctl dispatch exit 0 ;;
esac
