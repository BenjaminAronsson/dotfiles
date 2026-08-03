-- Lid / dock handling. Shared by both machines.
--
-- The problem it solves: closing the laptop lid while docked leaves workspaces
-- stranded on a screen you cannot see. Hyprland has no built-in notion of "this
-- output is now inside a closed laptop", so this shuffles workspaces onto an
-- external and puts them back on open.
--
-- This logic is empirically derived -- almost every line below is load-bearing
-- for one of the scenarios in the matrix at the bottom of this file. Read that
-- matrix before changing anything here.
--
-- Both profiles call setup() with their own details:
--
--   hypr-modular  laptop panel matched by "desc:", noctalia owns the wallpaper
--                 and re-applies it across monitor changes itself, so no
--                 after_change hook is passed.
--   hypr-classic  laptop panel matched by connector name, hyprpaper needs a
--                 nudge after every layout change, passed as after_change.
--
-- It used to be duplicated between the two, which is how a position = "auto"
-- bug in enable_edp() came to exist in both copies at once.

local M = {}

-- The ACPI lid button node is firmware-defined -- LID0 is usual but LID and
-- LID1 also occur -- so resolve it once at load instead of hardcoding one name
-- and silently reporting "open" forever on a machine that uses another.
local function find_lid_state_file()
    for _, node in ipairs({ "LID0", "LID", "LID1", "LID2" }) do
        local path = "/proc/acpi/button/lid/" .. node .. "/state"
        local f = io.open(path)
        if f then f:close(); return path end
    end
    return nil
end

local LID_STATE_FILE = find_lid_state_file()

-- opts:
--   laptop_name      connector name used for identity comparisons. Default "eDP-1".
--   laptop_output    what hl.monitor() keys its rule on -- a "desc:" string or a
--                    connector name. Defaults to laptop_name.
--   laptop_position  where the panel sits in the layout. Never "auto"; see enable_edp.
--   park_workspace   workspace parked on the panel while the lid is closed.
--   after_change     called after the layout settles, for compositor-adjacent
--                    state that does not survive monitor changes on its own
--                    (hyprpaper). Optional; defaults to a no-op.
function M.setup(opts)
    opts = opts or {}

    local LAPTOP          = opts.laptop_name     or "eDP-1"
    local LAPTOP_OUTPUT   = opts.laptop_output   or LAPTOP
    local LAPTOP_POSITION = opts.laptop_position or "0x0"
    -- Workspace kept on the panel while the lid is closed so that 1-10 stay on
    -- the externals. Deliberately outside the 1-10 range the profiles assign.
    local LID_PARK_WS     = opts.park_workspace  or "11"
    local after_change    = opts.after_change    or function() end

    local function is_lid_closed()
        if not LID_STATE_FILE then return false end
        local f = io.open(LID_STATE_FILE)
        if not f then return false end
        local s = f:read("*l"); f:close()
        return s ~= nil and s:match("closed") ~= nil
    end

    local function first_external()
        for _, m in ipairs(hl.get_monitors()) do
            if m.name ~= LAPTOP then return m end
        end
    end

    -- Monitor references appear as HL.Monitor userdata, tables, or plain strings
    -- depending on the API call; normalize to the name string
    local function monitor_name(m)
        if m == nil then return nil end
        if type(m) == "string" then return m end
        local ok, name = pcall(function() return m.name end)
        if ok then return name end
        return nil
    end

    local function is_special(name)
        return type(name) == "string" and name:match("^special") ~= nil
    end

    local edp_workspaces = {}    -- restore list; cleared only on restore/reclaim, never by sweeps
    local edp_active_ws  = nil

    -- Monitor:set_workspace() silently no-ops, so activate via the focus dispatchers:
    -- focus the panel -> switch workspace (created on the focused monitor) -> focus back.
    -- All within one synchronous block, so the focus hop is invisible.
    local function activate_ws_on_edp(ws_name)
        if not hl.get_monitor(LAPTOP) then return end
        local prev = hl.get_active_monitor()
        hl.dispatch(hl.dsp.focus({ monitor = LAPTOP }))
        hl.dispatch(hl.dsp.focus({ workspace = tonumber(ws_name) or ws_name }))
        if prev and prev.name ~= LAPTOP then
            hl.dispatch(hl.dsp.focus({ monitor = prev.name }))
        end
    end

    local function park_edp()
        activate_ws_on_edp(LID_PARK_WS)
    end

    -- Always park BEFORE sweeping: an enabled monitor must have an active workspace,
    -- so moving the panel's active workspace away makes Hyprland spawn a fresh one there
    -- (reentrant workspace.created churn that also invalidates workspace objects
    -- mid-iteration). Parked first, all swept workspaces are inactive and move cleanly;
    -- names are still collected before dispatching as a second guard.
    local function park_and_sweep_edp(target)
        if #edp_workspaces == 0 then
            local edp = hl.get_monitor(LAPTOP)
            edp_active_ws = edp and edp.active_workspace and edp.active_workspace.name
            if edp_active_ws == LID_PARK_WS then edp_active_ws = nil end
        end
        park_edp()
        local recorded = {}
        for _, name in ipairs(edp_workspaces) do recorded[name] = true end
        local to_move = {}
        for _, ws in ipairs(hl.get_workspaces()) do
            if monitor_name(ws.monitor) == LAPTOP and ws.name ~= LID_PARK_WS and not is_special(ws.name) then
                table.insert(to_move, ws.name)
            end
        end
        for _, name in ipairs(to_move) do
            if not recorded[name] then table.insert(edp_workspaces, name) end
            hl.dispatch(hl.dsp.workspace.move({ workspace = name, monitor = target.name }))
        end
    end

    -- Re-assert the laptop panel's rule. Keyed on LAPTOP_OUTPUT, which for the
    -- modular profile is the same "desc:" string monitors.lua declared, so this
    -- updates that rule rather than adding a second, higher-priority one that
    -- shadows it forever.
    --
    -- The position must be LAPTOP_POSITION, never "auto": auto means "wherever
    -- there is free space", which is always to the *right* of the externals.
    -- Since this runs on every lid open, an "auto" here silently relocated the
    -- physically-left laptop panel to the far right of the layout.
    local function enable_edp()
        hl.monitor({
            output   = LAPTOP_OUTPUT,
            mode     = "preferred",
            position = LAPTOP_POSITION,
            scale    = 1,
            disabled = false,
        })
    end

    local function restore_edp_workspaces()
        if #edp_workspaces == 0 then return end
        local active_on_external = {}
        for _, m in ipairs(hl.get_monitors()) do
            if m.name ~= LAPTOP and m.active_workspace then
                active_on_external[m.active_workspace.name] = true
            end
        end
        local first_restored
        for _, name in ipairs(edp_workspaces) do
            if not active_on_external[name] then
                hl.dispatch(hl.dsp.workspace.move({ workspace = name, monitor = LAPTOP }))
                if not first_restored then first_restored = name end
            end
        end
        -- Activate the workspace that was active before lid close, falling back to the first restored one
        local target = (edp_active_ws and not active_on_external[edp_active_ws]) and edp_active_ws or first_restored
        if target then activate_ws_on_edp(target) end
        edp_workspaces = {}
        edp_active_ws  = nil
    end

    -- Scenario matrix:
    --   open -> close (no dock)     switch:on Lid      no external -> skip; workspaces stay on the panel
    --   open -> dock -> close       switch:on Lid      park panel @ ws 11 + sweep
    --   open -> close -> dock       monitor.added      park + sweep (fires once per dock monitor)
    --   closed, partial undock      monitor.removed    externals remain -> re-sweep orphans off the panel
    --   closed, full undock         monitor.removed    reclaim all workspaces to the panel
    --   closed + dock -> open       switch:off Lid     restore swept workspaces to the panel
    --   closed -> new workspace     workspace.created  redirect to external
    --   closed -> new window        window.open        redirect; on park ws, move window itself
    --   startup/reload, closed      load timer         park + sweep (reload wipes Lua state)
    --   lid flaps within timers     all timers         re-check lid state before acting
    --   sleep / resume              hypridle           lock + dpms only; monitor events as above
    --
    -- The panel is kept enabled (not disabled) while the lid is closed: disabling it
    -- causes enterUnsafeState() on dock removal -> crash in getViewsForWorkspace
    -- (aquamarine bug).
    hl.bind("switch:on:Lid Switch", function()
        local ext = first_external()
        if not ext then return end
        park_and_sweep_edp(ext)
        hl.timer(function()
            if not is_lid_closed() then return end
            local ext2 = first_external()
            if ext2 then park_and_sweep_edp(ext2) end -- second pass: catch late arrivals
            after_change()
        end, { timeout = 800, type = "oneshot" })
    end, { locked = true })

    hl.bind("switch:off:Lid Switch", function()
        enable_edp()
        hl.timer(function()
            if is_lid_closed() then return end
            restore_edp_workspaces()
            after_change()
        end, { timeout = 800, type = "oneshot" })
    end, { locked = true })

    hl.on("monitor.removed", function()
        if not is_lid_closed() then return end
        if first_external() then
            -- Partial undock: Hyprland rehomes the removed monitor's workspaces on its own,
            -- possibly onto the panel -- sweep after it has finished.
            hl.timer(function()
                if not is_lid_closed() then return end
                local ext = first_external()
                if not ext then return end
                park_and_sweep_edp(ext)
            end, { timeout = 300, type = "oneshot" })
            return
        end
        enable_edp()
        hl.timer(function()
            -- Bail if externals reappeared meanwhile (suspend/resume, dock link retrain)
            if first_external() or not is_lid_closed() then return end
            if not hl.get_monitor(LAPTOP) then return end
            local to_reclaim = {}
            for _, ws in ipairs(hl.get_workspaces()) do
                if not is_special(ws.name) then table.insert(to_reclaim, ws.name) end
            end
            for _, name in ipairs(to_reclaim) do
                hl.dispatch(hl.dsp.workspace.move({ workspace = name, monitor = LAPTOP }))
            end
            local target = edp_active_ws or edp_workspaces[1]
            if not target then
                for _, name in ipairs(to_reclaim) do
                    if name ~= LID_PARK_WS then target = name; break end
                end
            end
            if target then activate_ws_on_edp(target) end
            edp_workspaces = {}
            edp_active_ws  = nil
            after_change()
        end, { timeout = 800, type = "oneshot" })
    end)

    hl.on("monitor.added", function()
        if not is_lid_closed() then return end
        if not hl.get_monitor(LAPTOP) then return end
        local ext = first_external()
        if not ext then return end
        park_and_sweep_edp(ext)
        hl.timer(after_change, { timeout = 800, type = "oneshot" })
    end)

    hl.on("workspace.created", function(ws)
        if not is_lid_closed() then return end
        if monitor_name(ws.monitor) ~= LAPTOP then return end
        if ws.name == LID_PARK_WS or is_special(ws.name) then return end
        local ext = first_external()
        if not ext then return end
        -- Park first: moving the panel's active workspace away would spawn yet another
        -- workspace here and re-trigger this handler (infinite churn)
        park_edp()
        hl.dispatch(hl.dsp.workspace.move({ workspace = ws.name, monitor = ext.name }))
    end)

    hl.on("window.open", function(window)
        if not is_lid_closed() then return end
        local ws = window.workspace
        if not ws or monitor_name(ws.monitor) ~= LAPTOP then return end
        local ext = first_external()
        if not ext then return end
        if ws.name == LID_PARK_WS then
            -- Focus was on the invisible panel (follow_mouse): the park workspace must stay,
            -- so move just the window to the external's visible workspace
            if window.address and ext.active_workspace then
                hl.exec_cmd(string.format("hyprctl dispatch movetoworkspacesilent %s,address:%s",
                    ext.active_workspace.name, window.address))
            end
            return
        end
        hl.dispatch(hl.dsp.workspace.move({ workspace = ws.name, monitor = ext.name }))
    end)

    -- Startup / config reload while lid closed: no event fires and a reload wipes the
    -- restore state above, so sweep once after monitors have settled.
    hl.timer(function()
        if not is_lid_closed() then return end
        local ext = first_external()
        if not ext then return end
        park_and_sweep_edp(ext)
        after_change()
    end, { timeout = 1000, type = "oneshot" })
end

return M
