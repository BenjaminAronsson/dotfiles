-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Idle handling: dim, lock, screens off, suspend. See hypr/hypridle.conf.
    -- Guarded so a config reload does not stack up a second daemon.
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")

    -- Low-battery warnings, power-profile switching and emergency suspend.
    --
    -- Deliberately unguarded: the script takes an flock on itself and exits if
    -- another instance holds it. A `pgrep -f battery-monitor.sh || ...` guard
    -- here does not work and previously meant the monitor never started at all
    -- — hl.exec_cmd runs this through a shell, that shell's command line has to
    -- contain the script name in order to launch it, and pgrep -f matches the
    -- parent shell. See the comment in battery-monitor.sh.
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/battery-monitor.sh &")

    -- Re-resolve the desk once the dock has settled.
    --
    -- variables.lua reads EDID at config *load*. If the dock's DP links come up
    -- after Hyprland has loaded, no serial matches, MONITOR1..3 all fall back to
    -- the laptop panel, and every workspace rule points there. With the lid
    -- closed liddock then sweeps all of 1-10 onto whichever external it happens
    -- to find first, which looks like "my workspaces are all on one screen".
    -- One reload after the outputs are awake re-resolves the roles.
    --
    -- Two guards, both load-bearing:
    --   * only when we resolved to "undocked" *and* externals actually turned
    --     up, so a correctly-detected desk is never reloaded out from under you;
    --   * a marker in the instance's runtime dir, because an unrecognised screen
    --     (hotel TV, meeting room projector) still resolves to "undocked" after
    --     the reload and would otherwise reload forever. This event fires on
    --     reload too -- same reason hypridle above needs its pgrep guard. The
    --     marker path contains $HYPRLAND_INSTANCE_SIGNATURE, so it is unique per
    --     compositor start and survives reloads within one session.
    if LOCATION == "undocked" then
        hl.exec_cmd([[sh -c '
            marker="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.desk-reloaded"
            [ -e "$marker" ] && exit 0
            sleep 4
            [ "$(hyprctl monitors | grep -c "^Monitor")" -gt 1 ] || exit 0
            touch "$marker"
            hyprctl reload
        ' &]])
    end

    -- Report which desk we resolved to, so a misdetected dock is obvious
    -- rather than showing up later as workspaces on the wrong screen.
    hl.exec_cmd(string.format(
        "sh -c 'sleep 2 && notify-send -t 4000 -u low \"Hyprland ready\" \"Location: %s\"'",
        LOCATION or "unknown"))
end)
