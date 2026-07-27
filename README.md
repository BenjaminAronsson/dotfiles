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

## Setting up a new machine

```bash
# 1. Install the tools the profile expects (see Dependencies below).
#    On Arch always use -Syu, never -Sy: a partial upgrade leaves the package
#    database ahead of the installed system and downloads then 404.
sudo pacman -Syu
sudo pacman -S --needed stow <profile deps>

# 2. Clone.
git clone https://github.com/BenjaminAronsson/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Check what it thinks this machine is. If the hostname is unknown it
#    falls back to the classic profile — add a branch in the Makefile.
make list

# 4. Clear conflicts. Stow will not overwrite real files, and a fresh install
#    ships defaults for most of these. Move them aside rather than deleting:
mkdir -p ~/config-backup
for f in starship.toml kitty/kitty.conf hypr; do
    [ -e ~/.config/$f ] && [ ! -L ~/.config/$f ] && mv ~/.config/$f ~/config-backup/
done

# 5. Deploy, then verify nothing is left unlinked.
make
ls -l ~/.config/hypr/
```

Then log out and back in, so Hyprland picks up the new config and the autostart
entries (hypridle, battery monitor) actually start.

**Symlinks must be relative.** Stow only recognises links it made itself; a
hand-made absolute symlink reads as "existing target not owned by stow" and
aborts the whole run. If that happens, delete the offending links and re-run
`make` — do not use `--adopt`, which pulls the target's contents into the repo.

## Dependencies

Both profiles need: `stow` `hyprland` `kitty` `starship` `hypridle`
`brightnessctl` `libnotify`

**Laptop** additionally: `noctalia` `ttf-meslo-nerd` `satty`

**Desktop** additionally: `waybar` `wofi` `dunst` `hyprpaper` `hyprlock`
`swayosd` `cliphist` `grim` `slurp` `swappy` `wlogout` `playerctl` `nautilus`
`ttf-cascadia-code-nerd`

A missing font fails silently — the terminal just falls back to a default
rather than erroring, so check `fc-list | grep -i <family>` if it looks wrong.

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

## Sleep, lid and system config

The `systemd/` directory is **not** stowed — it is root-owned config under
`/etc`, installed separately:

```bash
make install-systemd     # copy lid/sleep policy into /etc (needs sudo)
make verify-systemd      # show effective config + whether hibernation works
make uninstall-systemd   # remove it again
sudo systemctl restart systemd-logind   # apply (ends the graphical session)
```

`HandleLidSwitchDocked=ignore` is the key setting: it stops logind suspending
the machine when the lid closes with an external monitor attached, which is what
allows `liddock.lua` to move workspaces to the external instead.

**Hibernation is not available on the laptop.** Its only swap is zram, which
lives in RAM and therefore cannot hold a hibernation image, and there is no
`resume=` kernel parameter — `CanHibernate` reports `na`. Anything that names
`systemctl hibernate` or `suspend-then-hibernate` directly will silently fail
there, including the low-battery safety net.

So both hypridle and `battery-monitor.sh` call `scripts/sleep.sh`, which asks
logind what is actually possible and picks the deepest working mode. To enable
real hibernation, follow the steps in the comment at the top of
`systemd/logind.conf.d/80-laptop.conf`.

## Power profiles

`battery-monitor.sh` also drives `power-profiles-daemon`, because nothing else
will: on GNOME or Plasma the desktop shell does it, and Hyprland has no
equivalent, so otherwise the machine stays in whatever profile it booted with.

| power source | profile |
| --- | --- |
| adapter in | `performance` |
| on battery | `balanced` |
| on battery, at or below `CRIT` (10%) | `power-saver` |

It only acts when the wanted profile differs from the one it last set, so a
profile you choose by hand holds until the power source actually changes.
Override the choices with `AC_PROFILE` / `BAT_PROFILE` / `LOW_PROFILE`.

Check and drive it by hand with:

```bash
powerprofilesctl get
powerprofilesctl list
journalctl -t battery-monitor    # every switch it has made
```

The monitor is started from `autostart.lua` on `hyprland.start`. It keeps itself
single via `flock`, so the launch there is deliberately unguarded — do not add a
`pgrep -f battery-monitor.sh || ...` guard back. That guard cannot work, because
the launching shell's own command line has to contain the script name, and
`pgrep -f` matches full command lines including that parent shell. It silently
meant the monitor never started at all. The reasoning is in the script.

Because it starts on `hyprland.start`, `hyprctl reload` does **not** pick it up;
launch it by hand or log out and back in.

## Generated files

noctalia writes generated theme files into `~/.config/kitty/themes/` and
elsewhere. Those are deliberately not tracked — only `kitty.conf` is stowed,
and `~/.config/kitty` stays a real directory so noctalia has somewhere to write.
