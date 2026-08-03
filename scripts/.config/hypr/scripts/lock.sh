#!/usr/bin/env bash
# Lock the session using whichever locker this machine actually has.
#
# Shared by both machine profiles so hypridle.conf can stay machine-agnostic:
#   noctalia present (laptop)  -> noctalia's own lock screen, themed from wallpaper
#   otherwise (desktop)        -> hyprlock, themed with Catppuccin Mocha
#
# Guarded so a second trigger while already locked is a no-op.

if pidof hyprlock >/dev/null 2>&1; then
    exit 0
fi

if command -v noctalia >/dev/null 2>&1 && pgrep -x noctalia >/dev/null 2>&1; then
    exec noctalia msg session lock
elif command -v hyprlock >/dev/null 2>&1; then
    exec hyprlock
else
    # Nothing to lock with; at least blank the screen rather than failing open.
    exec hyprctl dispatch dpms off
fi
