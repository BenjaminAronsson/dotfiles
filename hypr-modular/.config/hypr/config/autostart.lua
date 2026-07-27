-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Idle handling: dim, lock, screens off, suspend. See hypr/hypridle.conf.
    -- Guarded so a config reload does not stack up a second daemon.
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")

    -- Low-battery warnings and emergency suspend.
    hl.exec_cmd("pgrep -f battery-monitor.sh >/dev/null || " ..
        os.getenv("HOME") .. "/.config/hypr/scripts/battery-monitor.sh &")

    -- Report which desk we resolved to, so a misdetected dock is obvious
    -- rather than showing up later as workspaces on the wrong screen.
    hl.exec_cmd(string.format(
        "sh -c 'sleep 2 && notify-send -t 4000 -u low \"Hyprland ready\" \"Location: %s\"'",
        LOCATION or "unknown"))
end)
