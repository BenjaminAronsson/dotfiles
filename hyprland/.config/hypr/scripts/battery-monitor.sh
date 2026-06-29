#!/usr/bin/env bash
# battery-monitor.sh — low-battery notifications + emergency suspend.
# Thresholds are env-overridable for testing (e.g. WARN=100 to force a fire).
BAT=/sys/class/power_supply/BAT0
INTERVAL="${INTERVAL:-30}"
WARN="${WARN:-20}"
CRIT="${CRIT:-10}"
EMERG="${EMERG:-5}"
GRACE="${GRACE:-60}"
NID=9001   # fixed dunstify id so alerts replace rather than stack

warned=0; critted=0

read_bat() {
    status=$(cat "$BAT/status" 2>/dev/null)
    cap=$(cat "$BAT/capacity" 2>/dev/null)
}

while true; do
    read_bat
    if [ "$status" = "Discharging" ]; then
        if [ "${cap:-100}" -le "$EMERG" ]; then
            dunstify -u critical -r "$NID" -t 0 \
                "Battery critically low (${cap}%)" \
                "Suspending in ${GRACE}s — plug in now to cancel."
            sleep "$GRACE"
            read_bat
            if [ "$status" = "Discharging" ] && [ "${cap:-100}" -le "$EMERG" ]; then
                systemctl suspend
            fi
        elif [ "${cap:-100}" -le "$CRIT" ] && [ "$critted" -eq 0 ]; then
            dunstify -u critical -r "$NID" \
                "Battery critical: ${cap}%" "Plug in your charger."
            critted=1
        elif [ "${cap:-100}" -le "$WARN" ] && [ "$warned" -eq 0 ]; then
            dunstify -u normal -r "$NID" \
                "Battery low: ${cap}%" "Consider plugging in."
            warned=1
        fi
    else
        # charging / full — reset so the next discharge cycle alerts again
        warned=0; critted=0
    fi
    sleep "$INTERVAL"
done
