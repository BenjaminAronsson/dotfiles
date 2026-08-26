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

-- Hot-desking fallback for any desk that isn't home or office (open-landscape
-- seating, meeting rooms) -- there is no known EDID serial to match, so the
-- two externals are told apart by DRM connector name instead. That name
-- depends on which dock port each cable happens to land on, not on physical
-- left/right position, so which one becomes MONITOR1 vs MONITOR2 is
-- essentially arbitrary from one desk to the next. M.toggle_generic_swap()
-- (bind it to a key) flips the two without editing config.
local GENERIC_SWAP_STATE_DIR = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local GENERIC_SWAP_FILE = GENERIC_SWAP_STATE_DIR .. "/hypr-generic-desk-swap"

local function generic_swap_wanted()
    local f = io.open(GENERIC_SWAP_FILE, "r")
    if f then f:close(); return true end
    return false
end

function M.toggle_generic_swap()
    if generic_swap_wanted() then
        os.remove(GENERIC_SWAP_FILE)
    else
        os.execute("mkdir -p '" .. GENERIC_SWAP_STATE_DIR .. "'")
        local f = io.open(GENERIC_SWAP_FILE, "w")
        if f then f:close() end
    end
    os.execute("hyprctl reload")
end

-- Every DRM connector currently reporting "connected", minus the laptop's
-- built-in panel (eDP-*), sorted by connector name for an order that is at
-- least stable across reloads even though it isn't tied to physical position.
local function connected_external_connectors()
    local ok, blob = pcall(function()
        local p = io.popen([[for f in /sys/class/drm/*/status; do
            d=$(basename "$(dirname "$f")")
            [ "$(cat "$f" 2>/dev/null)" = connected ] && echo "$d"
        done 2>/dev/null]])
        if not p then return "" end
        local s = p:read("*a") or ""
        p:close()
        return s
    end)

    local list = {}
    if ok then
        for line in blob:gmatch("[^\r\n]+") do
            local connector = line:match("^card%d+%-(.+)$") or line
            if not connector:match("^eDP") then
                table.insert(list, connector)
            end
        end
    end
    table.sort(list)
    return list
end

-- laptop_desc: this profile's own laptop panel identifier, used as the
-- fallback for MONITOR1/2 when nothing else is attached (undocked).
--
-- Returns MONITOR1 (main, centre), MONITOR2 (secondary, right), LOCATION
-- ("home" | "office" | "generic" | "undocked"), and COMPLETE -- false
-- whenever either monitor slot had to fall back to the laptop panel, which
-- also covers a *partially* settled dock (e.g. the main monitor's EDID was
-- readable but the second one's DP link hadn't finished training yet). A
-- caller should treat COMPLETE == false as "re-check once more monitors
-- show up" regardless of what LOCATION says -- see
-- schedule_reload_if_incomplete() below.
function M.resolve(laptop_desc)
    local edid = connected_edid()

    local function attached(serial)
        return edid:find(serial, 1, true) ~= nil
    end

    -- Pick the first candidate that is actually plugged in; the fallback is
    -- used unconditionally if neither desk is attached. Also reports whether
    -- a real match was found, so the caller can tell "this slot is
    -- genuinely empty" apart from "this monitor's DP link just hasn't
    -- finished training yet" -- see the `complete` return of resolve() below.
    local function first_attached(candidates, fallback)
        for _, c in ipairs(candidates) do
            if attached(c.serial) then return c.desc, true end
        end
        return fallback, false
    end

    if attached("1W6YK03") or attached("H3WW5V3") then
        -- monitor1 always matches here -- it's the same serial pair that
        -- decided we're in this branch at all.
        local monitor1 = first_attached({
            { serial = "1W6YK03", desc = HOME_MAIN   },
            { serial = "H3WW5V3", desc = OFFICE_MAIN },
        }, laptop_desc)

        local monitor2, monitor2_matched = first_attached({
            { serial = "G4LMTJ009579", desc = HOME_RIGHT   },
            { serial = "1G3X5V3",      desc = OFFICE_RIGHT },
        }, laptop_desc)

        local location = attached("1W6YK03") and "home" or "office"
        return monitor1, monitor2, location, monitor2_matched
    end

    -- Neither known desk: fall back generically instead of collapsing both
    -- MONITOR1 and MONITOR2 onto the laptop panel, which is what happened
    -- here before and is why an unrecognised desk showed everything on one
    -- screen even with two externals plugged in.
    local externals = connected_external_connectors()
    if #externals >= 2 then
        local first, second = externals[2], externals[1]
        if generic_swap_wanted() then
            first, second = second, first
        end
        return first, second, "generic", true
    elseif #externals == 1 then
        -- Only one DRM connector has come up so far -- could be a genuine
        -- single-external desk, or the second one is still link-training.
        -- Not complete: let the caller re-check once another monitor shows up.
        return externals[1], laptop_desc, "generic", false
    end

    return laptop_desc, laptop_desc, "undocked", false
end

-- Re-resolve the desk once the dock has settled, if resolve() came back
-- incomplete at config load. resolve() reads EDID/connector state once, at
-- load time -- if the dock's DP links come up after Hyprland has started, a
-- monitor slot falls back to the laptop panel and every workspace rule tied
-- to it points there instead. With the lid closed, liddock then sweeps
-- everything onto whichever external it finds first, which looks like "my
-- workspaces are all on one screen". A reload after the outputs are awake
-- re-resolves the roles correctly.
--
-- This covers two cases, both signalled by resolve()'s `complete` return
-- being false:
--   * fully undocked at load time (LOCATION == "undocked"), the original bug;
--   * *partially* docked at load time -- a known desk (or one external, in
--     the generic-desk case) was matched, but the second monitor's slot fell
--     back to the laptop panel because that link hadn't trained yet. This one
--     used to slip through because the old guard only checked
--     LOCATION == "undocked", so a desk that got *half* detected was never
--     re-resolved and MONITOR2 stayed pinned to the laptop panel all session.
--
-- Reacts to the real monitor.added event instead of polling on a fixed
-- schedule. A timed retry loop (2 checks/8s, then widened to 4 checks/16s
-- after it still missed the office dock) kept losing the race against this
-- dock's variable-length DP link training and reappeared as this exact bug
-- both times -- any fixed budget is eventually too short for some boot.
-- Firing off the actual "a monitor just showed up" event has no such budget
-- to run out: it doesn't matter whether the dock takes 5s or 50s.
--
-- Call from each profile's "hyprland.start" autostart handler, passing the
-- `complete` value resolve() already returned at load. hyprland.start fires
-- on every config reload, not just compositor boot (see the hypridle pgrep
-- guard above for the same reason), so this can be called many times per
-- session.
--
-- Two guards, both load-bearing:
--   * only when resolve() returned complete == false -- a fully detected
--     desk is never reloaded out from under it;
--   * a marker in the instance's runtime dir, because an unrecognised single
--     screen (hotel TV, meeting room projector) stays incomplete forever and
--     would otherwise register a fresh listener and reload every single time
--     hyprland.start fires. The marker path contains
--     $HYPRLAND_INSTANCE_SIGNATURE, so it is unique per compositor start and
--     survives reloads within one session (a plain Lua flag would not --
--     reload re-executes this whole module). A listener left registered
--     without ever firing again (no second monitor ever shows up) is
--     harmless -- it's event-driven, not a poll, so it costs nothing while
--     idle.
function M.schedule_reload_if_incomplete(complete)
    if complete then return end

    local marker = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr/" ..
        (os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "") .. "/.desk-reloaded"

    local function already_reloaded()
        local f = io.open(marker, "r")
        if f then f:close(); return true end
        return false
    end

    if already_reloaded() then return end

    hl.on("monitor.added", function()
        if already_reloaded() then return end
        -- Give the new output a moment to finish link training and expose a
        -- readable EDID before re-resolving -- same settle delay liddock.lua
        -- uses after monitor events.
        hl.timer(function()
            if already_reloaded() then return end
            local f = io.open(marker, "w")
            if f then f:close() end
            os.execute("hyprctl reload")
        end, { timeout = 1000, type = "oneshot" })
    end)
end

return M
