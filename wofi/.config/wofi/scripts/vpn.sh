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
    *Connect)
        output=$(nmcli connection up "$VPN_NAME" 2>&1)
        if [[ $? -eq 0 ]]; then
            notify-send "VPN" "Connected to ${VPN_NAME}"
        else
            notify-send -u critical "VPN" "Failed to connect: $output"
        fi
        ;;
    *Disconnect)
        output=$(nmcli connection down "$VPN_NAME" 2>&1)
        if [[ $? -eq 0 ]]; then
            notify-send "VPN" "Disconnected from ${VPN_NAME}"
        else
            notify-send -u critical "VPN" "Failed to disconnect: $output"
        fi
        ;;
    *Status)
        if [[ -n "$status" ]]; then
            notify-send "VPN" "Connected: ${VPN_NAME}"
        else
            notify-send "VPN" "Disconnected"
        fi
        ;;
esac
