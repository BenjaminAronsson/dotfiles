#!/bin/sh
# Swap the left/right positions of the two external monitors, then put
# workspaces 1-4 on whichever screen is now left and 5-8 on the right.
# The laptop panel (eDP) is ignored because liddock keeps it enabled even with
# the lid closed. Does nothing unless exactly two external monitors are active.
set -- $(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP") | not)
    | "\(.name) \(.width)x\(.height)@\(.refreshRate) \(.x)x\(.y) \(.scale) \(.x)"')
[ "$#" -eq 10 ] || exit 0
# After the swap, the monitor that was on the right ends up on the left.
if [ "$5" -gt "${10}" ]; then left=$1 right=$6; else left=$6 right=$1; fi
hyprctl eval "
hl.monitor({ output = '$1', mode = '$2', position = '$8', scale = $4 })
hl.monitor({ output = '$6', mode = '$7', position = '$3', scale = $9 })
"
for i in 1 2 3 4 5 6 7 8; do
    [ "$i" -le 4 ] && mon=$left || mon=$right
    hyprctl dispatch "hl.dsp.workspace.move({ workspace = '$i', monitor = '$mon' })"
done >/dev/null
hyprctl dispatch "hl.dsp.focus({ workspace = 5 })" >/dev/null
hyprctl dispatch "hl.dsp.focus({ workspace = 1 })" >/dev/null
# Moving the screens leaves the wallpaper and bar undrawn until something
# forces a repaint, so force one.
hyprctl dispatch "hl.dsp.force_renderer_reload()" >/dev/null
# hyprpaper doesn't redraw after the move either; restart it (see
# ensure_wallpaper in hypr-classic for why not reload). The laptop profile
# has no hyprpaper, so this is a no-op there.
pgrep -x hyprpaper >/dev/null && { pkill -x hyprpaper; setsid -f /usr/local/bin/hyprpaper >/dev/null 2>&1; }
