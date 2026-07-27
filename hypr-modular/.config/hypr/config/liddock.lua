-- Lid / dock handling -- laptop profile.
--
-- The logic lives in the hypr-shared package, at ~/.config/hypr/shared/liddock.lua,
-- because both machines need exactly the same behaviour and keeping two copies in
-- step by hand had already failed once. Read that file for the scenario matrix and
-- the reasoning behind the parking/sweeping dance; only the per-machine details
-- belong here.
--
-- No after_change hook: noctalia owns the wallpaper on this machine and re-applies
-- it across monitor changes itself. The desktop passes one, for hyprpaper.

require("shared.liddock").setup({
    -- Matched by "desc:" so this updates the same rule monitors.lua declared,
    -- rather than adding a connector-keyed one that would outrank it.
    laptop_output   = MONITOR3,
    laptop_position = LAPTOP_POSITION,
})
