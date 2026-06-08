# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal dotfiles for a Hyprland-based Linux desktop. There are no build, test, or lint commands — this is purely configuration files.

## Deployment

Uses [GNU Stow](https://www.gnu.org/software/stow/) to symlink configs into `$HOME`. Common commands:

```
make stow      # symlink all packages into ~
make unstow    # remove all symlinks
make restow    # re-link everything (use after adding/removing files)
make kitty     # stow a single package
```

Stow requires that existing files at the target path be absent or already symlinks — remove any conflicting real files before running `make stow`.

## Structure

Each top-level directory is a Stow package mirroring the `~/.config/` layout:

```
<package>/
  .config/<tool>/    ← symlinked to ~/.config/<tool>/
```

`hyprland`, `hyprlock`, `hyprmocha`, and `hyprpaper` all target `~/.config/hypr/`. Stow handles this by creating individual file symlinks inside that directory rather than a single directory symlink.

## Tools Configured

| Directory | Tool | Key file(s) |
|-----------|------|-------------|
| `hyprland` | Hyprland WM | `hyprland.conf`, `hypridle.conf` |
| `hyprlock` | Lock screen | `hyprlock.conf` |
| `hyprmocha` | Color palette | `mocha.conf` (sourced by hyprland.conf) |
| `hyprpaper` | Wallpaper daemon | `hyprpaper.conf` |
| `kitty` | Terminal | `kitty.conf`, `current-theme.conf` |
| `starship` | Shell prompt | `starship.toml` |
| `waybar` | Status bar | `config.jsonc`, `style.css`, `mocha.css` |
| `wofi` | App launcher | `style.css` |
| `backgrounds` | Wallpaper images | PNG/JPG assets |

## Theme

All tools use the **Catppuccin Mocha** color palette. The canonical color definitions live in `hyprmocha/.config/hypr/mocha.conf` and are sourced in `hyprland.conf`. Waybar uses `mocha.css` for the same palette. Keep colors consistent with this palette when adding or modifying configs.
