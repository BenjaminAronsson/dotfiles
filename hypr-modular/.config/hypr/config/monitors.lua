-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Every screen from both desks is listed here. Rules for monitors that are not
-- plugged in are simply ignored, so one file covers home, office and undocked
-- with no editing. Which of these becomes MONITOR1/2/3 is worked out in
-- variables.lua by reading EDID serials.
--
-- Both desks use the same physical arrangement, left to right:
--
--   +----------+  +----------+  +----------+
--   |  laptop  |  |   main   |  |  right   |
--   | MONITOR3 |  | MONITOR1 |  | MONITOR2 |
--   +----------+  +----------+  +----------+
--   x=0           x=1920        x=3840

-- Laptop panel, left at both desks
hl.monitor({
    output = "desc:LG Display 0x06B3",
    mode = "preferred",
    position = LAPTOP_POSITION,
    scale = 1,
})

-- Home desk
hl.monitor({
    output = "desc:Dell Inc. DELL P2419HC 1W6YK03",
    mode = "preferred",
    position = "1920x0",
    scale = 1,
})
hl.monitor({
    output = "desc:Ancor Communications Inc ASUS VC239 G4LMTJ009579",
    mode = "preferred",
    position = "3840x0",
    scale = 1,
})

-- Office desk. Two identical P2422HE panels, told apart by serial.
hl.monitor({
    output = "desc:Dell Inc. DELL P2422HE H3WW5V3",
    mode = "1920x1080@60",
    position = "1920x0",
    scale = 1,
})
hl.monitor({
    output = "desc:Dell Inc. DELL P2422HE 1G3X5V3",
    mode = "1920x1080@60",
    position = "3840x0",
    scale = 1,
})

-- Catch-all for anything unknown: a meeting room projector, a hotel TV. Placed
-- automatically to the right instead of stacking at 0x0 on top of the laptop.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-- Undocking
-- ---------
-- Nothing here changes when you unplug. Hyprland drops the rules for missing
-- outputs and moves their workspaces onto a monitor that still exists, so
-- windows follow you to the laptop screen; re-docking sends them back.
--
-- Changing desk (home <-> office) needs one extra step: variables.lua resolves
-- MONITOR1/2/3 when the config *loads*, so after docking somewhere new run
--   hyprctl reload
-- to re-home the workspaces. Everything else works without it.
