#!/usr/bin/env bash

SCRIPTS="$HOME/.config/wofi/scripts"

choice=$(printf "  Apps\n  Power\n  Volume\n  Brightness\n  Calculator\n  VPN" \
    | wofi --show dmenu \
           --prompt "Menu" \
           --width 320 --height 270 \
           --no-actions \
           --insensitive)

case "$choice" in
    *Apps)        wofi --show drun ;;
    *Power)       "$SCRIPTS/powermenu.sh" ;;
    *Volume)      "$SCRIPTS/volume.sh" ;;
    *Brightness)  "$SCRIPTS/brightness.sh" ;;
    *Calculator)  "$SCRIPTS/calc.sh" ;;
    *VPN)         "$SCRIPTS/vpn.sh" ;;
esac
