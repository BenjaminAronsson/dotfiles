-- App -> workspace assignments. Shared by both machines.
--
-- The problem it solves: without these, every app opens on whatever workspace
-- happens to have focus, so launching Spotify from a browser workspace buries
-- it next to the browser. Pinning each long-running app to a fixed workspace
-- makes SUPER+<number> a reliable way to reach it.
--
-- Both profiles use the same numbers, deliberately: muscle memory should carry
-- between the laptop and the desktop. Note that this means the *screen* an app
-- lands on differs between them, because the two profiles cut their workspace
-- blocks differently:
--
--                       hypr-classic        hypr-modular (laptop)
--   MONITOR1 (main)     1 2 3 4             1 2 3 4
--   MONITOR2 (right)    5 6 7 8             5 6 7
--   MONITOR3 (panel)    --                  8 9 0
--
-- The one that bites: workspace 8 (Spotify) is the right-hand external on the
-- desktop but the *laptop panel* on the laptop. Docked with the lid shut, the
-- panel is invisible and liddock sweeps 8 onto an external, so Spotify moves;
-- it is not lost, but SUPER+8 will not be where you left it. This was a
-- conscious trade in favour of identical numbering -- if it turns out to annoy,
-- the fix is to move Spotify to 7 here rather than to fork this file.
--
-- ---------------------------------------------------------------------------
-- Matching classes: observe, never guess
-- ---------------------------------------------------------------------------
-- Hyprland matches `class` as a case-sensitive regex against the class the
-- client actually reports at runtime. Two separate bugs came from guessing it:
--
--   * The Edge PWA rules below assumed an "msedge-_<id>" underscore that Edge
--     does not emit, so they silently never matched and Teams/Outlook kept
--     opening on the active workspace.
--   * A `Chromium` spelling never matched the laptop's Chromium, which reports
--     a lowercase `chromium`.
--
-- A .desktop file's StartupWMClass is *not* authoritative either --
-- spotify-launcher.desktop declares `spotify`, but the window reports
-- `Spotify`. The only reliable source is a live window:
--
--   hyprctl clients -j | jq -r '.[] | "\(.class)\t\(.title)"'
--
-- Where a class could not be observed on both machines, the pattern below
-- accepts every spelling seen in the wild rather than betting on one.
--
-- ---------------------------------------------------------------------------
-- "silent"
-- ---------------------------------------------------------------------------
-- `workspace = "N silent"` sends the window to N *without* following it there.
-- Applied to apps that are launched in the background or arrive unprompted
-- (the PWAs, Claude, a browser opened from a link), so they do not yank focus
-- mid-task. Omitted for the apps you launch because you want to use them right
-- now (the IDEs, Spotify), where following the window is the point.

local M = {}

function M.setup()
    -- Mail & chat -> 5.
    -- Edge PWAs; classes confirmed against a live `hyprctl clients -j` on the
    -- desktop. Inert on the laptop, which has no Edge installed -- kept here
    -- rather than branched per profile so the two machines stay one ruleset.
    hl.window_rule({
        name  = "teams-pwa-workspace",
        match = { class = "msedge-ompifgpmddkgmclendfeacglnodjjndh-Default" },
        workspace = "5 silent",
    })

    hl.window_rule({
        name  = "outlook-pwa-workspace",
        match = { class = "msedge-faolnafnngnfdaknnbpnkhgohbobgegn-Default" },
        workspace = "5 silent",
    })

    -- Claude -> 6.
    hl.window_rule({
        name  = "claude-workspace",
        match = { class = "com.anthropic.Claude" },
        workspace = "6 silent",
    })

    -- Browsers -> 3.
    -- Both spellings of Chromium are listed: the laptop reports `chromium`,
    -- while Chrome-family browsers elsewhere have been seen to capitalise it.
    hl.window_rule({
        name  = "browser-workspace",
        match = { class = "^([Cc]hromium|microsoft-edge|google-chrome)$" },
        workspace = "3 silent",
    })

    -- IDEs -> 4.
    -- Rider on the desktop, VS Code on the laptop; same slot because only one
    -- of them is ever installed on a given machine. `code-oss` is the Arch
    -- build's class, `Code` the class Microsoft's own build reports -- the
    -- laptop runs code-oss, but accept both so this does not silently break if
    -- the official package replaces it.
    hl.window_rule({
        name  = "rider-workspace",
        match = { class = "jetbrains-rider" },
        workspace = "4",
    })

    hl.window_rule({
        name  = "vscode-workspace",
        match = { class = "^(code-oss|[Cc]ode)$" },
        workspace = "4",
    })

    -- Spotify -> 8. See the workspace-block caveat at the top of this file.
    hl.window_rule({
        name  = "spotify-workspace",
        match = { class = "Spotify" },
        workspace = "8",
    })
end

return M
