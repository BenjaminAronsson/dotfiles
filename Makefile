PACKAGES := backgrounds environment hyprland hyprlock hyprmocha hyprpaper kitty starship waybar wofi
STOW     := stow --target=$(HOME) --dir=$(CURDIR)

.PHONY: stow unstow restow $(PACKAGES)

stow: ## Symlink all packages into ~
	$(STOW) $(PACKAGES)

unstow: ## Remove all symlinks from ~
	$(STOW) --delete $(PACKAGES)

restow: ## Re-link all packages (use after adding or removing files)
	$(STOW) --restow $(PACKAGES)

$(PACKAGES): ## Stow a single package, e.g. make kitty
	$(STOW) $@

help:
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "%-10s %s\n", $$1, $$2}'
