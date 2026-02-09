# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages configuration files using [chezmoi](https://www.chezmoi.io/). The repository uses chezmoi's source directory structure with the `home/` directory containing all managed dotfiles.

## Key Commands

### Installation and Setup
- `make install` - Apply dotfiles using chezmoi
- `make uninstall` - Remove chezmoi-managed files
- `make list` - Show all managed files

### Package Management via appctl
- `make apps-install` - Install all apps defined in `apps/`
- `make apps-upgrade` - Upgrade all installed apps
- `make apps-status` - Show status of all apps
- `make apps-doctor` - Health check for apps

Or use appctl directly:
- `./appctl/appctl install [app...]` - Install apps (all if no args)
- `./appctl/appctl upgrade [app...]` - Upgrade apps
- `./appctl/appctl uninstall <app...>` - Uninstall specified apps
- `./appctl/appctl status [app...]` - Show app status
- `./appctl/appctl list` - List all defined apps
- `./appctl/appctl doctor` - Health check

## Architecture

### Directory Structure
- `home/` - chezmoi source directory containing all dotfiles
- `appctl/` - Declarative package management tool
- `apps/` - App definitions (YAML) for appctl
- `zsh/` - Modular zsh configuration files sourced by `.zshrc` (not managed by chezmoi)
- `.chezmoiroot` - Points chezmoi to use `home/` as source directory

### appctl - Declarative Package Management

appctl is a unified package management tool that works across macOS (Homebrew) and Linux (apt). All software is defined declaratively in YAML files in the `apps/` directory.

**Handlers:**
- `brew` - Homebrew formulas and casks (macOS)
- `apt` - apt packages (Linux)
- `go` - go install (requires: go)
- `custom` - Custom install scripts

**App Definition Schema:**
```yaml
name: example

version:
  policy: latest  # or pinned
  value: "1.0.0"  # only for pinned

requires:
  - go          # logical app names (checked before install)

install:
  - type: brew
    package: example      # formula
    os: macos

  - type: brew
    cask: example-app     # cask (GUI app)
    os: macos

  - type: apt
    package: example
    os: linux

  - type: go
    package: example.com/cmd/example@latest

  - type: custom
    os: linux
    check: command -v example
    script: |
      curl -fsSL https://example.com/install.sh | bash
    uninstall: |
      rm -f /usr/local/bin/example
```

**Bootstrap Dependencies:**
appctl requires `jq` and `yq` to parse YAML. Install them first:
- macOS: `brew install jq yq`
- Linux: `sudo apt-get install jq && sudo snap install yq`

### chezmoi Naming Convention
Files in `home/` use chezmoi's naming convention:
- `dot_` prefix → `.` (dotfiles)
- `private_` prefix → mode 0600 (private files)
- `.tmpl` suffix → template processing

### Configuration Management
chezmoi manages these key configurations:
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
3. Test changes by opening a new shell session

### Adding New Apps
1. Create a YAML file in `apps/` directory (e.g., `apps/myapp.yaml`)
2. Define the app with appropriate handlers for each OS
3. Run `./appctl/appctl install myapp` to install

### Adding New Dotfiles
1. Create file in `home/` with appropriate chezmoi prefix:
   - Regular dotfile: `dot_filename`
   - Private file: `private_dot_filename`
   - Template: add `.tmpl` suffix
2. Update `.gitignore` whitelist pattern if needed
3. Run `chezmoi apply` to deploy

### Initial Setup on New Machine
```bash
# Clone the repository
git clone https://github.com/hhiroshell/dotfiles.git
cd dotfiles

# Install bootstrap dependencies (jq, yq)
# macOS:
brew install jq yq

# Linux:
sudo apt-get install jq
sudo snap install yq

# Install chezmoi and other apps
./appctl/appctl install chezmoi
./appctl/appctl install

# Initialize chezmoi with this repo
chezmoi init --source=/path/to/dotfiles --apply
```
