```makefile
PACKAGES := backgrounds environment hyprland hyprlock hyprmocha hyprpaper kitty starship waybar wofi
STOW     := stow --target=$(HOME) --dir=$(CURDIR)

SYSTEMD_SRC := $(CURDIR)/systemd
SYSTEMD_DST := /etc/systemd

.PHONY: stow unstow restow install-systemd uninstall-systemd verify-systemd help $(PACKAGES)

stow: ## Symlink all packages into ~
	$(STOW) $(PACKAGES)

unstow: ## Remove all symlinks from ~
	$(STOW) --delete $(PACKAGES)

restow: ## Re-link all packages
	$(STOW) --restow $(PACKAGES)

$(PACKAGES): ## Stow a single package, e.g. make kitty
	$(STOW) $@

install-systemd: ## Install systemd laptop configuration
	sudo install -Dm644 \
		$(SYSTEMD_SRC)/sleep.conf.d/80-laptop.conf \
		$(SYSTEMD_DST)/sleep.conf.d/80-laptop.conf
	sudo install -Dm644 \
		$(SYSTEMD_SRC)/logind.conf.d/80-laptop.conf \
		$(SYSTEMD_DST)/logind.conf.d/80-laptop.conf

uninstall-systemd: ## Remove installed systemd laptop configuration
	sudo rm -f $(SYSTEMD_DST)/sleep.conf.d/80-laptop.conf
	sudo rm -f $(SYSTEMD_DST)/logind.conf.d/80-laptop.conf

verify-systemd: ## Show the effective systemd configuration
	systemd-analyze cat-config systemd/sleep.conf
	systemd-analyze cat-config systemd/logind.conf

help:
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "%-20s %s\n", $$1, $$2}'
```
