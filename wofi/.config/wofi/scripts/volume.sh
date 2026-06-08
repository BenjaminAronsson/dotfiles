#!/usr/bin/env bash

current_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
current_pct=$(echo "$current_raw" | awk '{printf "%d", $2 * 100}')
muted=$(echo "$current_raw" | grep -q MUTED && echo "yes" || echo "no")

mute_label="  Mute"
[[ "$muted" == "yes" ]] && mute_label="  Unmute"

choice=$(printf "%s\n  10%%\n  25%%\n  50%%\n  75%%\n  100%%\n  Current: %d%%" \
    "$mute_label" "$current_pct" \
    | wofi --show dmenu \
           --prompt "Volume" \
           --width 320 --height 260 \
           --no-actions \
           --insensitive)

case "$choice" in
    *Mute|*mute)   wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    *Unmute)       wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 ;;
    *10%)          wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.10 ;;
    *25%)          wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.25 ;;
    *50%)          wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.50 ;;
    *75%)          wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.75 ;;
    *100%)         wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.00 ;;
esac
