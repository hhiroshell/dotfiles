# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages configuration files and development environment setup through symbolic links. The repository follows a home-directory structure pattern where configuration files are stored in `home/` and symlinked to their target locations.

## Key Commands

### Installation and Setup
- `make install` - Creates symbolic links for all dotfiles from `home/` to `$HOME`
- `make uninstall` - Removes symbolic links created by `make install`
- `make list` - Shows all managed dotfile mappings (source -> target)
- `aqua install` - Install all development tools defined in `home/aqua/aqua.yaml`

### Development Tools
The repository uses [aqua](https://aquaproj.github.io/) as a declarative CLI version manager. All development tools are defined in `home/aqua/aqua.yaml` including:
- Editors: helix
- Languages: go, node.js, rust
- Kubernetes tools: kubectl, kind, krew, kustomize
- Development utilities: fzf, jq, yq, ghq, fd, lazygit

## Architecture

### Directory Structure
- `home/` - Contains all dotfiles organized in their target directory structure
- `zsh/` - Modular zsh configuration files sourced by `.zshrc`
- `Makefile` - Installation script that creates symlinks

### Configuration Management
The Makefile manages these key configurations (source -> symlink):
- `aqua/aqua.yaml` -> `~/.aqua/aqua.yaml` - Development tool versions
- `config/ghostty/` -> `~/.config/ghostty/` - Ghostty terminal (with OS-specific config)
- `config/helix/` -> `~/.config/helix/` - Helix editor configuration
- `config/kitty/` -> `~/.config/kitty/` - Kitty terminal configuration
- `config/lazygit/` -> `~/.config/lazygit/` - Lazygit configuration
- `config/tmux/` -> `~/.config/tmux/` - tmux configuration
- `config/starship.toml` -> `~/.config/starship.toml` - Shell prompt configuration
- `gitconfig` and `gitignore_global` -> `~/.gitconfig`, `~/.gitignore_global` - Git configuration
- `ssh/config` -> `~/.ssh/config` - SSH configuration
- `zimrc`, `zshenv`, `zshrc` -> `~/.zimrc`, `~/.zshenv`, `~/.zshrc` - Zsh shell configuration

### Platform-Specific Configuration
The Makefile detects the OS (`uname`) and creates platform-specific symlinks:
- On macOS: `config/ghostty/macos` -> `~/.config/ghostty/platform`
- On Linux: `config/ghostty/linux` -> `~/.config/ghostty/platform`

The main config file uses `config-file = ?platform` to optionally include the platform-specific settings.

### Zsh Module System
The `.zshrc` sources modular configuration files from `zsh/`:
- `git.zsh` - Git-related functions and aliases
- `kubernetes.zsh` - Kubernetes utilities
- `misc.zsh` - General utilities and aliases
- `sdk.zsh` - SDK and development environment setup

## Working with This Repository

When modifying configurations:
1. Edit files in `home/` directory (not in actual home directory)
2. Run `make install` to update symlinks if adding new files
3. Run `aqua install` after updating `home/aqua/aqua.yaml`
4. Test changes by opening a new shell session

The symlink approach ensures configuration changes are version-controlled while maintaining the expected file locations for applications.