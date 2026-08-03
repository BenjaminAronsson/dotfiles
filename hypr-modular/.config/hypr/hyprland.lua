-- Hyprland configuration -- laptop profile (CachyOS + noctalia shell)
--
-- Deployed by `make cachyos-dell` from ~/dotfiles. The desktop machine uses
-- the monolithic hypr-classic profile instead.
--
-- Load order matters: variables.lua defines MONITOR1..3 and the app names that
-- binds, monitors and workspaces all refer to, so it must come first.

require("config.variables")

require("config.animations")
require("config.colors")
require("config.decorations")
require("config.environment")
require("config.inputs")
require("config.misc")

require("config.monitors")
require("config.workspaces")
require("config.windowrules")
require("config.binds")

require("config.liddock")
require("config.autostart")
