-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- Each monitor owns a block of workspaces, so SUPER+<number> always lands on a
-- predictable screen:
--
--   1 2 3 4   MONITOR1  Dell, main, centre
--   5 6 7     MONITOR2  ASUS, right
--   8 9 0     MONITOR3  laptop panel, left   (0 is workspace 10)
--
-- "default" marks the workspace a monitor shows when it first appears; exactly
-- one per monitor. "persistent" keeps a workspace alive while empty so it stays
-- visible in the bar and does not renumber under you.
--
-- Undocked, the rules for missing monitors go dormant and their workspaces move
-- to the laptop panel. Nothing is lost, and re-docking sends them back.

-- Dell, main
hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = MONITOR1, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = MONITOR1, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = MONITOR1, persistent = true })

-- ASUS, right
hl.workspace_rule({ workspace = "5", monitor = MONITOR2, default = true, persistent = true })
hl.workspace_rule({ workspace = "6", monitor = MONITOR2, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = MONITOR2, persistent = true })

-- Laptop panel, left
hl.workspace_rule({ workspace = "8", monitor = MONITOR3, default = true, persistent = true })

-- 9 and 10 are deliberately unbound (no "monitor" field): a workspace rule's
-- "monitor" is a hard binding that Hyprland reasserts every time the
-- workspace is focused by id, not just an initial default. Binding them to
-- MONITOR3 (the laptop panel) meant SUPER+9/0 always snapped back to the
-- panel even while docked with the lid closed and its workspaces swept
-- elsewhere by liddock -- the panel is invisible then, so this looked like
-- the workspace was "hiding". Left unbound, they land on whichever monitor
-- is currently focused instead, and simply aren't force-created or pinned
-- until something is put there. Matches how hypr-classic treats its own 9/10.

-- Named scratch workspace for games; not persistent, appears when used.
hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR })
