# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages configuration files using [chezmoi](https://www.chezmoi.io/). The repository uses chezmoi's source directory structure with the `home/` directory containing all managed dotfiles.

## Key Commands

### Installation and Setup
- `make install` - Apply dotfiles using chezmoi
- `make uninstall` - Remove chezmoi-managed files
- `make list` - Show all managed files
- `aqua install` - Install all development tools defined in `home/dot_aqua/aqua.yaml`

### Platform-Specific Package Management
- `make brew-install` - Install Homebrew packages from Brewfile (macOS only)
- `make apt-install` - Install apt packages from apt-packages.txt (Ubuntu/Debian only)

### Development Tools
The repository uses [aqua](https://aquaproj.github.io/) as a declarative CLI version manager. All development tools are defined in `home/dot_aqua/aqua.yaml` including:
- Editors: helix
- Languages: go, node.js, rust
- Python: uv (manages Python versions, packages, and virtual environments)
- Kubernetes tools: kubectl, kind, krew, kustomize
- Development utilities: fzf, jq, yq, ghq, fd, lazygit, chezmoi

### Package Management Policy

The repository uses complementary package managers with clear separation of concerns:

**Homebrew** (macOS only):
- Manages GUI applications and system-level tools
- Examples: Ghostty, Google Chrome, Raycast, KeePassXC, git-credential-manager, gitify
- System utilities: tmux, starship, gh, colordiff
- Defined in `Brewfile` (repo root)
- Install with: `make brew-install`

**apt** (Ubuntu/Debian only):
- Manages basic system packages and utilities
- System utilities: curl, wget, git
- Defined in `apt-packages.txt` (repo root)
- Install with: `make apt-install`

**aqua** (cross-platform):
- Manages development tools and programming language toolchains
- Examples: go, node, rust, uv (Python), kubectl, helix, lazygit, fzf, jq
- Defined in `home/dot_aqua/aqua.yaml`
- Install with: `aqua install`

**Why separate?** Platform-specific package managers (Homebrew/apt) handle GUI applications, system integrations, and native build dependencies. aqua's declarative approach provides reproducible development tool versioning across different platforms and operating systems.

## Architecture

### Directory Structure
- `home/` - chezmoi source directory containing all dotfiles
- `zsh/` - Modular zsh configuration files sourced by `.zshrc` (not managed by chezmoi)
- `Brewfile` - Homebrew packages (macOS, kept at repo root for future appctl)
- `apt-packages.txt` - apt packages (Linux, kept at repo root for future appctl)
- `.chezmoiroot` - Points chezmoi to use `home/` as source directory

### chezmoi Naming Convention
Files in `home/` use chezmoi's naming convention:
- `dot_` prefix → `.` (dotfiles)
- `private_` prefix → mode 0600 (private files)
- `.tmpl` suffix → template processing

### Configuration Management
chezmoi manages these key configurations:
- `dot_aqua/aqua.yaml` → `~/.aqua/aqua.yaml` - Development tool versions
- `dot_claude/settings.json.tmpl` → `~/.claude/settings.json` - Claude Code settings (templated for OS-specific hooks)
- `dot_claude/skills/` → `~/.claude/skills/` - Claude Code custom skills
- `dot_config/ghostty/config.tmpl` → `~/.config/ghostty/config` - Ghostty terminal (templated for OS-specific font-size)
- `dot_config/helix/` → `~/.config/helix/` - Helix editor configuration
- `dot_config/kitty/kitty.conf.tmpl` → `~/.config/kitty/kitty.conf` - Kitty terminal (templated for OS-specific font_size)
- `dot_config/lazygit/` → `~/.config/lazygit/` - Lazygit configuration
- `dot_config/tmux/` → `~/.config/tmux/` - tmux configuration
- `dot_config/starship.toml` → `~/.config/starship.toml` - Shell prompt configuration
- `dot_gitconfig`, `dot_gitignore_global` → `~/.gitconfig`, `~/.gitignore_global` - Git configuration
- `private_dot_ssh/config` → `~/.ssh/config` - SSH configuration
- `dot_zimrc`, `dot_zshenv`, `dot_zshrc` → `~/.zimrc`, `~/.zshenv`, `~/.zshrc` - Zsh shell configuration

### Platform-Specific Configuration
chezmoi uses Go templates for OS-specific settings:
- Ghostty: font-size = 13 (macOS) / 10 (Linux)
- Kitty: font_size 13 (macOS) / 10 (Linux)
- Claude Code: notify-send hooks on Linux only

Template files use `{{ .chezmoi.os }}` to conditionally include platform-specific content.

### Zsh Module System
The `.zshrc` sources modular configuration files from `zsh/`:
- `git.zsh` - Git-related functions and aliases
- `kubernetes.zsh` - Kubernetes utilities
- `misc.zsh` - General utilities and aliases
- `sdk.zsh` - SDK and development environment setup

These modules are kept in the repo root and sourced via ghq path, not managed by chezmoi.

## Working with This Repository

When modifying configurations:
1. Edit files in `home/` directory (using chezmoi naming convention)
2. Run `make install` (or `chezmoi apply`) to apply changes
3. Run `aqua install` after updating `home/dot_aqua/aqua.yaml`
4. For Homebrew changes (macOS only):
   - Edit `Brewfile` to add/remove packages
   - Run `make brew-install` to apply changes
5. For apt changes (Ubuntu/Debian only):
   - Edit `apt-packages.txt` to add/remove packages
   - Run `make apt-install` to apply changes
6. Test changes by opening a new shell session

### Adding New Files
1. Create file in `home/` with appropriate chezmoi prefix:
   - Regular dotfile: `dot_filename`
   - Private file: `private_dot_filename`
   - Template: add `.tmpl` suffix
2. Update `.gitignore` whitelist pattern if needed
3. Run `chezmoi apply` to deploy

### Initial Setup on New Machine
```bash
# Install aqua first (see aquaproj.github.io for bootstrap)
# Then install chezmoi
aqua install

# Initialize chezmoi with this repo
chezmoi init --source=/path/to/dotfiles --apply
```
