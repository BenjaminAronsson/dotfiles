#!/bin/sh
# Flip which hot-desk external hosts workspaces 1-4 vs 5-8, for desks
# deskresolve.lua doesn't recognise by EDID serial -- see its doc comment on
# connected_external_connectors(). Bound to SUPER+SHIFT+M in each profile.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}"
flag="$state_dir/hypr-generic-desk-swap"

mkdir -p "$state_dir"
if [ -e "$flag" ]; then
    rm -f "$flag"
else
    touch "$flag"
fi

hyprctl reload
