DOTFILES := $(CURDIR)/home
UNAME := $(shell uname)

# source (in home/) -> target (in $HOME)
MAPPINGS := \
	aqua/aqua.yaml:.aqua/aqua.yaml \
	claude/commands:.claude/commands \
	config/helix:.config/helix \
	config/ghostty/config:.config/ghostty/config \
	config/kitty:.config/kitty \
	config/lazygit:.config/lazygit \
	config/starship.toml:.config/starship.toml \
	config/tmux:.config/tmux \
	gitconfig:.gitconfig \
	gitignore_global:.gitignore_global \
	ssh/config:.ssh/config \
	zimrc:.zimrc \
	zshenv:.zshenv \
	zshrc:.zshrc

# Platform-specific mappings (different source, same target)
ifeq ($(UNAME),Darwin)
MAPPINGS += config/ghostty/macos:.config/ghostty/platform
endif
ifeq ($(UNAME),Linux)
MAPPINGS += config/ghostty/linux:.config/ghostty/platform
endif

.PHONY: install uninstall list

install:
	@for mapping in $(MAPPINGS); do \
		src="$(DOTFILES)/$${mapping%%:*}"; \
		target="$(HOME)/$${mapping##*:}"; \
		mkdir -p "$$(dirname "$$target")"; \
		if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
			echo "Skipped: $$target already exists (not a symlink)"; \
		else \
			ln -snf "$$src" "$$target"; \
			echo "Created symlink: $$target"; \
		fi; \
	done

uninstall:
	@for mapping in $(MAPPINGS); do \
		target="$(HOME)/$${mapping##*:}"; \
		if [ -L "$$target" ]; then \
			rm -f "$$target"; \
			echo "Removed symlink: $$target"; \
		fi; \
	done

list:
	@echo "Mappings (source -> target):"
	@for mapping in $(MAPPINGS); do \
		src="$${mapping%%:*}"; \
		target="$${mapping##*:}"; \
		printf "  %-30s -> %s\n" "$$src" "$$target"; \
	done
