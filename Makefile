UNAME := $(shell uname)

.PHONY: install uninstall list apps-install apps-upgrade apps-status apps-doctor

# Dotfiles management via chezmoi
install:
	chezmoi apply

uninstall:
	chezmoi purge

list:
	chezmoi managed

# Package management via appctl
apps-install:
	@$(CURDIR)/appctl/appctl install

apps-upgrade:
	@$(CURDIR)/appctl/appctl upgrade

apps-status:
	@$(CURDIR)/appctl/appctl status

apps-doctor:
	@$(CURDIR)/appctl/appctl doctor
