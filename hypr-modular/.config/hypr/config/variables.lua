-- Hyprland default apps

TERMINAL     = "kitty"
FILE_MANAGER = "dolphin"
BROWSER      = "chromium"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

--------------------------------------------------------------------------
-- Monitors
--------------------------------------------------------------------------
-- This laptop docks in two places, so rather than hardcode one set of
-- screens, we work out which desk we're at by reading the EDID of every
-- connected output and looking for known serial numbers. That resolution is
-- shared with the classic profile, which docks at the same two desks -- see
-- hypr-shared/shared/deskresolve.lua.
--
--   MONITOR1  main screen, centre
--   MONITOR2  secondary, right
--   MONITOR3  laptop panel, left
--
-- Those three roles are what binds.lua and workspaces.lua refer to, so the
-- same workspace layout lands on the equivalent screen at either desk.
--
-- List what's attached with:
--   hyprctl monitors all | grep -E '^Monitor|description:'

local LAPTOP = "desc:LG Display 0x06B3"

MONITOR1, MONITOR2, LOCATION = require("shared.deskresolve").resolve(LAPTOP)

MONITOR3 = LAPTOP
PRIMARY_MONITOR = MONITOR1

-- Where the laptop panel sits. Shared with monitors.lua, which declares the
-- rule, and liddock.lua, which re-applies it when the lid opens. Both must
-- agree: an "auto" position in either place puts the panel to the *right* of
-- the externals, because auto means "wherever there is free space".
LAPTOP_POSITION = "0x0"

-- LOCATION ("home" | "office" | "undocked") comes back from resolve() above.
-- Only used for the startup notification, but handy when a workspace lands
-- somewhere unexpected.

-- Workspaces
NUM_WPM = 4 -- Number of workspaces per monitor (Max 10)
