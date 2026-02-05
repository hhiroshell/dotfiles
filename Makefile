DOTFILES := $(CURDIR)/home
UNAME := $(shell uname)

# source (in home/) -> target (in $HOME)
MAPPINGS := \
	aqua/aqua.yaml:.aqua/aqua.yaml \
	claude/skills:.claude/skills \
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
MAPPINGS += claude/settings.macos.json:.claude/settings.json
MAPPINGS += Brewfile:.Brewfile
endif
ifeq ($(UNAME),Linux)
MAPPINGS += config/ghostty/linux:.config/ghostty/platform
MAPPINGS += claude/settings.linux.json:.claude/settings.json
endif

.PHONY: install uninstall list brew-install apt-install aqua-install

install:
	@for mapping in $(MAPPINGS); do \
		src="$(DOTFILES)/$${mapping%%:*}"; \
		target="$(HOME)/$${mapping##*:}"; \
		if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
			echo "Skipped: $$target already exists (not a symlink)"; \
		elif [ -L "$$target" ]; then \
			printf "Overwrite symlink: $$target -> $$src? [y/N] "; \
			read answer; \
			case "$$answer" in \
				[Yy]*) \
					ln -snf "$$src" "$$target"; \
					echo "Updated symlink: $$target"; \
					;; \
				*) \
					echo "Skipped: $$target"; \
					;; \
			esac; \
		else \
			mkdir -p "$$(dirname "$$target")"; \
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

brew-install:
	@if [ "$(UNAME)" != "Darwin" ]; then \
		echo "Error: Homebrew commands are only supported on macOS"; \
		exit 1; \
	fi
	@if [ ! -f "$(DOTFILES)/Brewfile" ]; then \
		echo "Error: $(DOTFILES)/Brewfile not found"; \
		exit 1; \
	fi
	@echo "Installing packages from Brewfile..."
	@brew bundle install --file=$(DOTFILES)/Brewfile

apt-install:
	@if [ "$(UNAME)" != "Linux" ]; then \
		echo "Error: apt commands are only supported on Linux"; \
		exit 1; \
	fi
	@if [ ! -f "$(DOTFILES)/apt-packages.txt" ]; then \
		echo "Error: $(DOTFILES)/apt-packages.txt not found"; \
		exit 1; \
	fi
	@echo "Installing packages from apt-packages.txt..."
	@grep -v '^#' $(DOTFILES)/apt-packages.txt | grep -v '^$$' | xargs sudo apt install -y

aqua-install:
	@if ! command -v aqua >/dev/null 2>&1; then \
		echo "Error: aqua is not installed"; \
		exit 1; \
	fi
	@if [ ! -f "$(DOTFILES)/aqua/aqua.yaml" ]; then \
		echo "Error: $(DOTFILES)/aqua/aqua.yaml not found"; \
		exit 1; \
	fi
	@echo "Installing packages from aqua.yaml..."
	@aqua install
