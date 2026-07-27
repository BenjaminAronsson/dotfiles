# Dotfiles deployment.
#
# Packages are grouped into machine profiles, because the two machines run
# different desktops:
#
#   cachyos-dell  Dell Precision 5560 laptop, CachyOS + noctalia shell.
#                 noctalia provides the bar, launcher, notifications,
#                 wallpaper, clipboard, screenshots, lock screen and polkit
#                 agent, so none of waybar/wofi/dunst/hyprpaper is used, and
#                 the theme is generated from the wallpaper.
#
#   classic       Desktop, hand-assembled stack: waybar + wofi + dunst +
#                 hyprpaper + hyprlock, all themed Catppuccin Mocha.
#
# Usage:
#   make                  deploy the profile matching this machine's hostname
#   make cachyos-dell     deploy the laptop profile explicitly
#   make classic          deploy the desktop profile explicitly
#   make unstow           remove every symlink this repo owns
#   make restow           re-link (use after adding or removing files)
#   make kitty            stow a single package
#   make list             show which profile this machine resolves to

STOW := stow --target=$(HOME) --dir=$(CURDIR)
HOST := $(shell hostname)

# System-level config. Not stowed: it belongs to root, under /etc.
SYSTEMD_SRC := $(CURDIR)/systemd
SYSTEMD_DST := /etc/systemd

# SDDM login screen. Also not stowed: the drop-in belongs to root under /etc,
# and the theme variant has to live beside the theme it extends, under
# /usr/share, where the unprivileged `sddm` user can read it before login.
SDDM_SRC   := $(CURDIR)/sddm
SDDM_THEME := /usr/share/sddm/themes/sddm-astronaut-theme

# Shared by every machine. hypr-shared carries the Hyprland Lua that both
# profiles require() -- currently the lid/dock handling, which is identical on
# both and used to be maintained as two copies that drifted.
COMMON  := starship backgrounds environment scripts hypridle hypr-shared

# Laptop: modular Hyprland config, noctalia does the rest.
LAPTOP  := hypr-modular kitty-modular

# Desktop: monolithic Hyprland config plus the full hand-rolled stack.
CLASSIC := hypr-classic kitty-classic waybar wofi dunst hyprpaper hyprlock hyprmocha swappy flameshot

# Everything, for unstow/restow.
ALL := $(COMMON) $(LAPTOP) $(CLASSIC)

# Hostname -> profile. Add new machines here.
ifeq ($(HOST),cachyos-dell)
PROFILE := cachyos-dell
PROFILE_PKGS := $(LAPTOP)
else
PROFILE := classic
PROFILE_PKGS := $(CLASSIC)
endif

.PHONY: all cachyos-dell classic unstow restow list help \
        install-systemd uninstall-systemd verify-systemd \
        install-sddm uninstall-sddm verify-sddm $(ALL)

all: $(PROFILE) ## Deploy the profile matching this machine

cachyos-dell: ## Deploy the laptop profile (CachyOS + noctalia)
	$(STOW) $(COMMON) $(LAPTOP)

classic: ## Deploy the desktop profile (waybar + wofi + dunst + Mocha)
	$(STOW) $(COMMON) $(CLASSIC)

unstow: ## Remove all symlinks from ~
	-$(STOW) --delete $(ALL)

restow: ## Re-link the current profile (use after adding or removing files)
	$(STOW) --restow $(COMMON) $(PROFILE_PKGS)

$(ALL): ## Stow a single package, e.g. make kitty
	$(STOW) $@

install-systemd: ## Install lid/sleep policy into /etc (needs sudo)
	sudo install -Dm644 \
		$(SYSTEMD_SRC)/sleep.conf.d/80-laptop.conf \
		$(SYSTEMD_DST)/sleep.conf.d/80-laptop.conf
	sudo install -Dm644 \
		$(SYSTEMD_SRC)/logind.conf.d/80-laptop.conf \
		$(SYSTEMD_DST)/logind.conf.d/80-laptop.conf
	@echo "Installed. Apply with: sudo systemctl restart systemd-logind"
	@echo "(this ends the graphical session — save work first)"

uninstall-systemd: ## Remove the installed lid/sleep policy from /etc
	sudo rm -f $(SYSTEMD_DST)/sleep.conf.d/80-laptop.conf
	sudo rm -f $(SYSTEMD_DST)/logind.conf.d/80-laptop.conf

verify-systemd: ## Show the effective systemd sleep/lid configuration
	systemd-analyze cat-config systemd/sleep.conf
	systemd-analyze cat-config systemd/logind.conf
	@echo
	@echo "Can this machine hibernate?"
	@busctl call org.freedesktop.login1 /org/freedesktop/login1 \
		org.freedesktop.login1.Manager CanHibernate

install-sddm: ## Install the Catppuccin Mocha login screen (needs sudo)
	@test -d $(SDDM_THEME) || { \
		echo "sddm-astronaut-theme is not installed. First run:"; \
		echo "  paru -S sddm-astronaut-theme"; \
		exit 1; }
	sudo install -Dm644 \
		$(SDDM_SRC)/themes/catppuccin-mocha.conf \
		$(SDDM_THEME)/Themes/catppuccin-mocha.conf
	sudo install -Dm644 \
		$(CURDIR)/backgrounds/.config/backgrounds/nice-blue-background.png \
		$(SDDM_THEME)/Backgrounds/nice-blue-background.png
	sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/catppuccin-mocha.conf|' \
		$(SDDM_THEME)/metadata.desktop
	@# Repair an upstream typo: Main.qml falls back to `Screen.ScreenWidth`,
	@# which is not a QML property, so a blank ScreenWidth leaves the root
	@# Pane's width undefined. Without this the greeter cannot size itself to
	@# the actual screen and renders letterboxed in black. Idempotent.
	sudo sed -i 's|Screen\.ScreenWidth|Screen.width|g' $(SDDM_THEME)/Main.qml
	sudo install -Dm644 \
		$(SDDM_SRC)/sddm.conf.d/10-theme.conf \
		/etc/sddm.conf.d/10-theme.conf
	@echo
	@echo "Installed. Check it without logging out:  make verify-sddm"
	@echo "Upgrading sddm-astronaut-theme rewrites metadata.desktop and"
	@echo "reverts the variant -- re-run this target if the greeter changes."

uninstall-sddm: ## Revert to the unstyled default greeter
	sudo rm -f /etc/sddm.conf.d/10-theme.conf
	sudo rm -f $(SDDM_THEME)/Themes/catppuccin-mocha.conf
	sudo rm -f $(SDDM_THEME)/Backgrounds/nice-blue-background.png

verify-sddm: ## Preview the greeter in a window, without logging out
	@echo "Effective theme:"
	@grep -h '^Current=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | tail -1
	@echo "Selected variant:"
	@grep -h '^ConfigFile=' $(SDDM_THEME)/metadata.desktop 2>/dev/null
	@echo
	@echo "Opening a preview window (close it to return)..."
	sddm-greeter-qt6 --test-mode --theme $(SDDM_THEME)

list: ## Show the detected machine and what it would deploy
	@echo "hostname : $(HOST)"
	@echo "profile  : $(PROFILE)"
	@echo "packages : $(COMMON) $(PROFILE_PKGS)"

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-14s %s\n", $$1, $$2}'
