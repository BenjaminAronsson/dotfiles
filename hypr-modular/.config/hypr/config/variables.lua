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
-- connected output and looking for known serial numbers.
--
--   MONITOR1  main screen, centre
--   MONITOR2  secondary, right
--   MONITOR3  laptop panel, left
--
-- Those three roles are what binds.lua and workspaces.lua refer to, so the
-- same workspace layout lands on the equivalent screen at either desk.
--
-- Monitors are matched by "desc:" rather than connector name (DP-4 etc)
-- because the connector depends on which dock port the cable happens to hit.
-- List what's attached with:
--   hyprctl monitors all | grep -E '^Monitor|description:'

local LAPTOP      = "desc:LG Display 0x06B3"
local HOME_MAIN   = "desc:Dell Inc. DELL P2419HC 1W6YK03"
local HOME_RIGHT  = "desc:Ancor Communications Inc ASUS VC239 G4LMTJ009579"
local OFFICE_MAIN = "desc:Dell Inc. DELL P2422HE H3WW5V3"
local OFFICE_RIGHT= "desc:Dell Inc. DELL P2422HE 1G3X5V3"

-- Read every connected monitor's EDID into one string. Serial numbers appear
-- in it as plain ASCII, so a substring search is enough to tell the desks
-- apart -- the two office screens are the same model and differ only by
-- serial. Wrapped in pcall so that if sysfs ever looks different this falls
-- back to the home layout instead of failing to load the config at all.
local function connected_edid()
    local ok, blob = pcall(function()
        local p = io.popen("cat /sys/class/drm/*/edid 2>/dev/null | tr -c '[:print:]' ' '")
        if not p then return "" end
        local s = p:read("*a") or ""
        p:close()
        return s
    end)
    return (ok and blob) or ""
end

local edid = connected_edid()

local function attached(serial)
    return edid:find(serial, 1, true) ~= nil
end

-- Pick the first candidate that is actually plugged in; the last entry is the
-- fallback and is used unconditionally.
local function first_attached(candidates, fallback)
    for _, c in ipairs(candidates) do
        if attached(c.serial) then return c.desc end
    end
    return fallback
end

MONITOR1 = first_attached({
    { serial = "1W6YK03", desc = HOME_MAIN   },
    { serial = "H3WW5V3", desc = OFFICE_MAIN },
}, LAPTOP)

MONITOR2 = first_attached({
    { serial = "G4LMTJ009579", desc = HOME_RIGHT   },
    { serial = "1G3X5V3",      desc = OFFICE_RIGHT },
}, LAPTOP)

MONITOR3 = LAPTOP
PRIMARY_MONITOR = MONITOR1

-- Where we think we are. Only used for the startup notification, but handy
-- when a workspace lands somewhere unexpected.
LOCATION = attached("1W6YK03") and "home"
        or attached("H3WW5V3") and "office"
        or "undocked"

-- Workspaces
NUM_WPM = 4 -- Number of workspaces per monitor (Max 10)
