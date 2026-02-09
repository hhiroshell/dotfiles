UNAME := $(shell uname)

.PHONY: install uninstall list brew-install apt-install aqua-install

# Dotfiles management via chezmoi
install:
	chezmoi apply

uninstall:
	chezmoi purge

list:
	chezmoi managed

# Package management (will be replaced by appctl)
brew-install:
	@if [ "$(UNAME)" != "Darwin" ]; then \
		echo "Error: Homebrew commands are only supported on macOS"; \
		exit 1; \
	fi
	@if [ ! -f "$(CURDIR)/Brewfile" ]; then \
		echo "Error: $(CURDIR)/Brewfile not found"; \
		exit 1; \
	fi
	@echo "Installing packages from Brewfile..."
	@brew bundle install --file=$(CURDIR)/Brewfile

apt-install:
	@if [ "$(UNAME)" != "Linux" ]; then \
		echo "Error: apt commands are only supported on Linux"; \
		exit 1; \
	fi
	@if [ ! -f "$(CURDIR)/apt-packages.txt" ]; then \
		echo "Error: $(CURDIR)/apt-packages.txt not found"; \
		exit 1; \
	fi
	@echo "Installing packages from apt-packages.txt..."
	@grep -v '^#' $(CURDIR)/apt-packages.txt | grep -v '^$$' | xargs sudo apt install -y

aqua-install:
	@if ! command -v aqua >/dev/null 2>&1; then \
		echo "Error: aqua is not installed"; \
		exit 1; \
	fi
	@echo "Installing packages from aqua.yaml..."
	@aqua install
