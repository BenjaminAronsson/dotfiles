# dotfiles

Hyprland desktop configuration using [GNU Stow](https://www.gnu.org/software/stow/) for deployment. Theme: [Catppuccin Mocha](https://catppuccin.com/).

## Packages

| Package | Tool |
|---------|------|
| `hyprland` | Window manager + idle daemon |
| `hyprlock` | Lock screen |
| `hyprpaper` | Wallpaper daemon |
| `hyprmocha` | Catppuccin Mocha color palette (sourced by other hypr configs) |
| `kitty` | Terminal |
| `waybar` | Status bar |
| `wofi` | App launcher + scripts (power, volume, brightness, VPN, calc) |
| `starship` | Shell prompt |
| `backgrounds` | Wallpaper images |

## Setup

```bash
make stow      # symlink all packages into ~
make unstow    # remove all symlinks
make restow    # re-link after adding or removing files
make kitty     # stow a single package
```

Remove any conflicting real files under `~/.config` before running `make stow` — Stow will refuse if a target path already exists as a non-symlink.
