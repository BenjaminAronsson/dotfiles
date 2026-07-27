# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal dotfiles for two Hyprland machines. There are no build, test, or lint
commands — this is purely configuration files.

## Two machines, two profiles

The machines run different desktops, so packages are grouped into profiles and
`make` selects one by hostname. Do not assume a change applies to both.

| | `cachyos-dell` (laptop) | `classic` (desktop) |
|---|---|---|
| Hyprland config | modular `config/*.lua` | monolithic `hyprland.lua` |
| Shell | noctalia | waybar + wofi + dunst + hyprpaper |
| Lock | noctalia session lock | hyprlock |
| Theme | generated from wallpaper | Catppuccin Mocha, fixed |

noctalia subsumes bar, launcher, notifications, wallpaper, clipboard,
screenshots, lock screen and polkit agent on the laptop. When adding something
to the laptop profile, check whether noctalia already provides it before
introducing a standalone tool.

## Deployment

Uses GNU Stow to symlink configs into `$HOME`.

```
make               # deploy the profile matching this hostname
make list          # show detected profile and its packages
make cachyos-dell  # force laptop profile
make classic       # force desktop profile
make restow        # re-link after adding or removing files
make unstow        # remove all symlinks
make starship      # stow a single package
```

Stow requires that existing files at the target path be absent or already
symlinks — move conflicting real files aside first.

Add a machine by adding a `PROFILE` branch in the `Makefile` keyed on hostname.

## Structure

Each top-level directory is a Stow package mirroring the `~/.config/` layout:

```
<package>/
  .config/<tool>/    ← symlinked to ~/.config/<tool>/
```

Several packages target `~/.config/hypr/` (`hypr-modular`, `hypridle`,
`scripts`, `hypr-shared`). Stow handles this by unfolding — creating individual
file symlinks inside that directory rather than one directory symlink. Do not
collapse them into a single package; the split is what lets `hypridle`,
`scripts` and `hypr-shared` be shared across profiles.

## Hyprland config is Lua

Both machines use Hyprland's Lua config, not the classic `hyprland.conf` syntax.
On the laptop, `hyprland.lua` is the entry point and `require`s `config/*.lua`.
**Load order matters**: `config.variables` defines `MONITOR1..3` and the app
names that `binds`, `monitors` and `workspaces` reference, so it must load first.

## Monitors

Matched by `desc:` (make + model + serial), never by connector name — the
connector depends on which dock port the cable lands in, and the office has two
identical panels distinguished only by serial.

`config/variables.lua` reads the EDID of every connected output and resolves
`MONITOR1` (main), `MONITOR2` (right), `MONITOR3` (laptop panel) to whichever
desk is detected. This happens at config *load*, so changing desk needs a
`hyprctl reload`.

## Lid / dock handling is shared

Both machines are laptops that dock, and both need identical lid behaviour, so
the logic lives in one place: `hypr-shared/.config/hypr/shared/liddock.lua`,
deployed to every machine as part of `COMMON` and pulled in with
`require("shared.liddock").setup{...}`.

It is subtle and was arrived at empirically; its comments record why each guard
exists — in particular that the laptop panel must stay *enabled* while the lid
is closed, because disabling it crashes on dock removal (aquamarine bug). Read
the scenario matrix in that file before changing anything.

Each profile passes only its own details:

| | `hypr-modular` (laptop) | `hypr-classic` (desktop) |
|---|---|---|
| `laptop_output` | `MONITOR3` (a `desc:` string) | `"eDP-1"` (connector name) |
| `after_change` | none — noctalia re-applies its own wallpaper | `ensure_wallpaper` for hyprpaper |

**Do not fork this file back into the profiles.** It was two hand-maintained
copies until 2026-07-27, which is exactly how a `position = "auto"` bug in
`enable_edp()` came to exist in both at once: it re-applied the panel's monitor
rule on every lid open with "auto", relocating the physically-left panel to the
far right of the layout. Anything genuinely machine-specific belongs in the
`setup{}` call, not in a second copy.

## Keybinding conflicts

`binds.lua` binds `SUPER+SHIFT+[0-9]` in a loop near the end of the file. Any
earlier bind on those combinations is silently overridden. Move-to-monitor
therefore lives on `SUPER+ALT+[1-3]`.

## Generated files

noctalia generates theme files into `~/.config/kitty/themes/` and similar
locations. These must not be tracked. Only `kitty.conf` is stowed, keeping
`~/.config/kitty` a real directory for noctalia to write into.

## Theme

The desktop uses Catppuccin Mocha; canonical colours live in
`hyprmocha/.config/hypr/mocha.conf` and are sourced by `hyprlock.conf`, with
waybar using `mocha.css`. Keep those consistent when editing the `classic`
profile.

The laptop does **not** use Mocha — noctalia generates its palette from the
wallpaper and propagates it to kitty, btop, Qt/KDE and Firefox via its own
templates. Do not add fixed Mocha colours to the laptop profile.
