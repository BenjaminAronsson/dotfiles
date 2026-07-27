#!/usr/bin/env bash
# sleep.sh — go to sleep using the deepest mode this machine actually supports.
#
# Shared by both machines, and by hypridle and battery-monitor.sh, so that one
# config can ship everywhere without assuming hibernation works.
#
# Why this exists: hibernation needs disk-backed swap at least the size of RAM,
# plus a resume= kernel parameter. The laptop currently has neither — its only
# swap is zram, which lives in RAM and therefore cannot hold a hibernation
# image. There, logind reports CanHibernate=na and `systemctl hibernate` fails.
# Hardcoding hibernate meant the low-battery safety net silently did nothing.
#
# Check what the current machine can do:
#   busctl call org.freedesktop.login1 /org/freedesktop/login1 \
#       org.freedesktop.login1.Manager CanHibernate
#
# Usage: sleep.sh [idle|emergency]
#   idle       used by hypridle after a long timeout — prefers suspend-then-hibernate
#   emergency  used by battery-monitor at critical charge — prefers hibernate,
#              since suspend still drains and the point is to survive

MODE="${1:-idle}"

can() { # systemd capability check: "yes" means usable now
    [ "$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager "$1" 2>/dev/null)" = 's "yes"' ]
}

case "$MODE" in
    emergency)
        # Battery is nearly gone: hibernate survives a full power loss,
        # suspend does not. Fall back only if hibernation is unavailable.
        if can CanHibernate; then
            exec systemctl hibernate
        else
            logger -t sleep.sh "hibernate unavailable (no disk swap); suspending instead"
            exec systemctl suspend
        fi
        ;;
    *)
        if can CanSuspendThenHibernate; then
            exec systemctl suspend-then-hibernate
        else
            exec systemctl suspend
        fi
        ;;
esac
