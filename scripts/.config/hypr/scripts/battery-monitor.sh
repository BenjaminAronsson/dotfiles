#!/usr/bin/env bash
# battery-monitor.sh — low-battery notifications, power-profile switching and
# emergency suspend.
# Thresholds are env-overridable for testing (e.g. WARN=100 to force a fire).
#
# Uses notify-send rather than dunstify so the same script works on both
# machines: dunst on the desktop, noctalia on the laptop. Both implement the
# freedesktop notification spec, including --replace-id.
BAT="${BAT:-/sys/class/power_supply/BAT0}"   # overridable to fake a battery
INTERVAL="${INTERVAL:-30}"
WARN="${WARN:-20}"
CRIT="${CRIT:-10}"
EMERG="${EMERG:-5}"
GRACE="${GRACE:-60}"
NID=9001   # fixed notification id so alerts replace rather than stack

# Power profiles, applied as the power source changes. Nothing else does this:
# on GNOME or Plasma the desktop shell drives power-profiles-daemon, and
# Hyprland has no equivalent, so without this the machine sits in whatever
# profile it booted with — usually `performance`, on battery, forever.
AC_PROFILE="${AC_PROFILE:-performance}"
BAT_PROFILE="${BAT_PROFILE:-balanced}"
LOW_PROFILE="${LOW_PROFILE:-power-saver}"   # below CRIT, buy back some runtime

# No battery (desktop) — nothing to monitor.
[ -d "$BAT" ] || exit 0

# Only ever one instance, enforced here rather than by a guard at the call site.
# A `pgrep -f battery-monitor.sh || battery-monitor.sh &` guard cannot work: the
# launcher's own command line has to contain the script name in order to launch
# it, pgrep -f searches full command lines, and pgrep excludes itself but not
# its parent shell — so the guard always finds the shell asking the question,
# concludes the monitor is up, and silently never starts it. That is exactly how
# this went unnoticed. The lock is held on fd 9 and released by the kernel when
# the process dies, so a crash cannot wedge it.
LOCK="${LOCK:-${XDG_RUNTIME_DIR:-/tmp}/battery-monitor.lock}"
exec 9>"$LOCK" || exit 1
flock -n 9 || exit 0

warned=0; critted=0
profile=""   # last profile *we* set; "" means we have not set one yet

notify() { # urgency, summary, body, [timeout]
    notify-send -u "$1" -r "$NID" ${4:+-t "$4"} "$2" "$3"
}

# Switch profile only when the wanted one differs from what we last applied.
# Two consequences worth knowing: a profile you pick by hand (noctalia, or
# `powerprofilesctl set ...`) sticks until the power source actually changes,
# rather than being stamped back every INTERVAL seconds; and if the set fails —
# no daemon, or a machine without that profile — `profile` is left alone, so it
# is simply retried on the next poll instead of being recorded as done.
set_profile() {
    [ "$1" = "$profile" ] && return
    command -v powerprofilesctl >/dev/null 2>&1 || return
    powerprofilesctl set "$1" >/dev/null 2>&1 || return
    profile="$1"
    logger -t battery-monitor "power profile -> $1"
}

# Tell the user what will actually happen, rather than promising hibernation on
# a machine that cannot hibernate. Mirrors the choice sleep.sh will make.
sleep_verb() {
    if [ "$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager CanHibernate 2>/dev/null)" = 's "yes"' ]; then
        echo "Hibernating"
    else
        echo "Suspending"
    fi
}

read_bat() {
    status=$(cat "$BAT/status" 2>/dev/null)
    cap=$(cat "$BAT/capacity" 2>/dev/null)
}

while true; do
    read_bat
    if [ "$status" = "Discharging" ]; then
        if [ "${cap:-100}" -le "$CRIT" ]; then
            set_profile "$LOW_PROFILE"
        else
            set_profile "$BAT_PROFILE"
        fi

        if [ "${cap:-100}" -le "$EMERG" ]; then
            notify critical "Battery critically low (${cap}%)" \
                "$(sleep_verb) in ${GRACE}s — plug in now to cancel." 0
            sleep "$GRACE"
            read_bat
            if [ "$status" = "Discharging" ] && [ "${cap:-100}" -le "$EMERG" ]; then
                "$(dirname "$0")/sleep.sh" emergency
            fi
        elif [ "${cap:-100}" -le "$CRIT" ] && [ "$critted" -eq 0 ]; then
            notify critical "Battery critical: ${cap}%" "Plug in your charger."
            critted=1
        elif [ "${cap:-100}" -le "$WARN" ] && [ "$warned" -eq 0 ]; then
            notify normal "Battery low: ${cap}%" "Consider plugging in."
            warned=1
        fi
    else
        # charging / full / not-charging (charge limit reached) — all mean the
        # adapter is in, so take the brakes off and reset so the next discharge
        # cycle alerts again
        set_profile "$AC_PROFILE"
        warned=0; critted=0
    fi
    sleep "$INTERVAL"
done
