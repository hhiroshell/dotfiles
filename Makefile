DOTFILES := $(CURDIR)/home

TARGETS := \
	.aqua/aqua.yaml \
	.claude/commands \
	.config/helix \
	.config/kitty \
	.config/nvim \
	.config/starship.toml \
	.config/tmux \
	.gitconfig \
	.gitignore_global \
	.ideavimrc \
	.ssh/config \
	.zimrc \
	.zshenv \
	.zshrc

.PHONY: install uninstall list

install: $(addprefix $(HOME)/, $(TARGETS))

$(HOME)/%: $(DOTFILES)/%
	@mkdir -p $(dir $@)
	@if [ -e $@ ] && [ ! -L $@ ]; then \
		echo "Skipped: $@ already exists (not a symlink)"; \
	else \
		ln -snf $< $@; \
		echo "Created symlink: $@"; \
	fi

uninstall:
	@for target in $(TARGETS); do \
		path="$(HOME)/$$target"; \
		if [ -L "$$path" ]; then \
			rm -f "$$path"; \
			echo "Removed symlink: $$path"; \
		fi; \
	done

list:
	@echo "Targets:"
	@for target in $(TARGETS); do \
		echo "  $$target"; \
	done
