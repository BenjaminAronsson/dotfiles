#!/usr/bin/env bash

VPN_NAME="Centiro SSTP VPN"

status=$(nmcli -t -f NAME,STATE connection show --active | grep "^${VPN_NAME}:")

if [[ -n "$status" ]]; then
    label="  Connected"
    options=$(printf " Disconnect\n  Status")
else
    label="  Disconnected"
    options=$(printf " Connect\n  Status")
fi

choice=$(echo "$options" | wofi --show dmenu \
    --prompt "$label" \
    --width 320 --height 140 \
    --no-actions \
    --insensitive)

case "$choice" in
    *Connect)    nmcli connection up "$VPN_NAME" ;;
    *Disconnect) nmcli connection down "$VPN_NAME" ;;
    *Status)
        if [[ -n "$status" ]]; then
            notify-send "VPN" "Connected: ${VPN_NAME}"
        else
            notify-send "VPN" "Disconnected"
        fi
        ;;
esac
