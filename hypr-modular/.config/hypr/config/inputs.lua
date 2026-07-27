-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        kb_layout = "se",
        -- Caps Lock acts as a second Escape, as on the desktop machine.
        kb_options = "caps:escape",
    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

-- Three-finger horizontal swipe to change workspace, matching the desktop.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- hl.gesture({ fingers = 3, direction = "down",       action = "close" })
-- hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
-- hl.gesture({ fingers = 3, direction = "left",       action = "float" })
