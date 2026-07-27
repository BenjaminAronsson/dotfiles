# dotfiles

Configuration for two Hyprland machines, deployed with [GNU Stow](https://www.gnu.org/software/stow/).

The two machines run genuinely different desktops, so packages are grouped into
**profiles** and `make` picks one by hostname.

| | `cachyos-dell` (laptop) | `classic` (desktop) |
|---|---|---|
| Machine | Dell Precision 5560, CachyOS | desktop |
| Hyprland config | modular, `config/*.lua` | monolithic `hyprland.lua` |
| Bar / launcher / notifications | noctalia | waybar / wofi / dunst |
| Wallpaper, clipboard, screenshots | noctalia | hyprpaper, cliphist, grim+slurp+swappy |
| Lock screen | noctalia | hyprlock |
| Theme | generated from wallpaper | Catppuccin Mocha, fixed |

noctalia replaces most of the hand-assembled stack on the laptop, which is why
`waybar`, `wofi`, `dunst`, `hyprpaper`, `hyprlock` and `hyprmocha` are only
stowed in the `classic` profile.

## Usage

```bash
make            # deploy the profile matching this machine's hostname
make list       # show which profile this machine resolves to
make help       # list all targets

make cachyos-dell   # force the laptop profile
make classic        # force the desktop profile

make restow     # re-link after adding or removing files
make unstow     # remove every symlink this repo owns
make starship   # stow a single package
```

Stow refuses to overwrite a real file. If a target already exists as a regular
file or directory, move it aside first.

Adding a machine: add a `PROFILE` branch in the `Makefile` keyed on hostname.

## Packages

**Shared** — `starship` `backgrounds` `environment` `scripts` `hypridle`

**Laptop** — `hypr-modular` `kitty-modular`

**Desktop** — `hypr-classic` `kitty-classic` `waybar` `wofi` `dunst`
`hyprpaper` `hyprlock` `hyprmocha` `swappy` `flameshot`

`scripts` holds `lock.sh`, which picks whichever locker the machine has, and
`battery-monitor.sh`, which uses `notify-send` so it works with both dunst and
noctalia. That is what lets `hypridle.conf` stay shared.

## Monitors

The laptop docks at two desks and works out which one from the EDID serial
numbers of whatever is plugged in — see
`hypr-modular/.config/hypr/config/variables.lua`. The roles `MONITOR1` (main),
`MONITOR2` (right) and `MONITOR3` (laptop panel) resolve to the right screens at
either desk, so the workspace layout in `workspaces.lua` follows you.

Roles resolve when the config **loads**, so after docking at a different desk
run `hyprctl reload` to re-home the workspaces.

List what is attached:

```bash
hyprctl monitors all | grep -E '^Monitor|description:'
```

## Generated files

noctalia writes generated theme files into `~/.config/kitty/themes/` and
elsewhere. Those are deliberately not tracked — only `kitty.conf` is stowed,
and `~/.config/kitty` stays a real directory so noctalia has somewhere to write.
