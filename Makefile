DOTFILES := $(CURDIR)/home

# source (in home/) -> target (in $HOME)
MAPPINGS := \
	aqua/aqua.yaml:.aqua/aqua.yaml \
	claude/commands:.claude/commands \
	config/helix:.config/helix \
	config/kitty:.config/kitty \
	config/nvim:.config/nvim \
	config/starship.toml:.config/starship.toml \
	config/tmux:.config/tmux \
	gitconfig:.gitconfig \
	gitignore_global:.gitignore_global \
	ideavimrc:.ideavimrc \
	ssh/config:.ssh/config \
	zimrc:.zimrc \
	zshenv:.zshenv \
	zshrc:.zshrc

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
	@echo "Targets:"
	@for mapping in $(MAPPINGS); do \
		echo "  $${mapping##*:}"; \
	done
