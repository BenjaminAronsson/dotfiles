-- Multi-desk monitor resolution. Shared by both machines.
--
-- Both laptops dock at the same two desks (home and office), so rather than
-- hardcode one set of screens, each works out which desk it is at by reading
-- the EDID of every connected output and looking for known serial numbers.
-- The four desk monitors are declared once here instead of forked into each
-- profile's own variables/hyprland file -- liddock.lua already learned that
-- lesson the hard way (see its history: a duplicated position = "auto" bug).
--
-- Monitors are matched by "desc:" rather than connector name (DP-4 etc)
-- because the connector depends on which dock port the cable happens to hit.
-- List what's attached with:
--   hyprctl monitors all | grep -E '^Monitor|description:'

local M = {}

local HOME_MAIN    = "desc:Dell Inc. DELL P2419HC 1W6YK03"
local HOME_RIGHT   = "desc:Ancor Communications Inc ASUS VC239 G4LMTJ009579"
local OFFICE_MAIN  = "desc:Dell Inc. DELL P2422HE H3WW5V3"
local OFFICE_RIGHT = "desc:Dell Inc. DELL P2422HE 1G3X5V3"

M.HOME_MAIN    = HOME_MAIN
M.HOME_RIGHT   = HOME_RIGHT
M.OFFICE_MAIN  = OFFICE_MAIN
M.OFFICE_RIGHT = OFFICE_RIGHT

-- Read every connected monitor's EDID into one string. Serial numbers appear
-- in it as plain ASCII, so a substring search is enough to tell the desks
-- apart -- the two office screens are the same model and differ only by
-- serial. Wrapped in pcall so that if sysfs ever looks different this falls
-- back to the laptop-only layout instead of failing to load the config at all.
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

-- laptop_desc: this profile's own laptop panel identifier, used as the
-- fallback for MONITOR1/2 when neither desk is attached (undocked).
--
-- Returns MONITOR1 (main, centre), MONITOR2 (secondary, right), LOCATION
-- ("home" | "office" | "undocked").
function M.resolve(laptop_desc)
    local edid = connected_edid()

    local function attached(serial)
        return edid:find(serial, 1, true) ~= nil
    end

    -- Pick the first candidate that is actually plugged in; the fallback is
    -- used unconditionally if neither desk is attached.
    local function first_attached(candidates, fallback)
        for _, c in ipairs(candidates) do
            if attached(c.serial) then return c.desc end
        end
        return fallback
    end

    local monitor1 = first_attached({
        { serial = "1W6YK03", desc = HOME_MAIN   },
        { serial = "H3WW5V3", desc = OFFICE_MAIN },
    }, laptop_desc)

    local monitor2 = first_attached({
        { serial = "G4LMTJ009579", desc = HOME_RIGHT   },
        { serial = "1G3X5V3",      desc = OFFICE_RIGHT },
    }, laptop_desc)

    local location = attached("1W6YK03") and "home"
                   or attached("H3WW5V3") and "office"
                   or "undocked"

    return monitor1, monitor2, location
end

return M
