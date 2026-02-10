# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages configuration files using [chezmoi](https://www.chezmoi.io/). The repository uses chezmoi's source directory structure with the `chezmoi/` directory containing all managed dotfiles.

## Design Philosophy

This repository is built on the **appctl approach** — a design that targets a practical operating point between "dotfiles management" and "machine reproducibility."

It pursues neither perfect reproducibility nor a hands-off setup. The core principle is:

> **Assume things will break. Make breakage observable. Keep the ability to fix it.**

### Core Principles

1. **Declare, but don't guarantee.** Apps are declared in YAML, but fulfillment is not guaranteed. Instead, drift between declaration and reality is made **observable** (via `doctor`). This explicitly differs from Nix's guarantee model.

2. **Follow latest by default.** Version pinning is the exception, not the rule. Latest-tracking provides security updates, early detection of breaking changes, and reduced manual update cost. Pinning is an **emergency brake** used only when stability is momentarily needed.

3. **Respect existing ecosystems.** brew / apt / npm / GitHub Releases and native OS behaviors are **wrapped, not replaced**. This makes troubleshooting searchable, handoff easy, and corporate machine restrictions avoidable.

4. **Separate dotfiles from app management.** appctl handles app existence, state, and versions. chezmoi handles file placement, OS diffs, and templates. No symlink dependency. OS-specific diffs are confined to chezmoi. **Mixing responsibilities is intentionally avoided.**

5. **Doctor-centric design.** The system prioritizes `doctor` over `install`. Doctor checks installation presence, dependency satisfaction (`requires`), and version drift (pinned violations). It observes **"how things have drifted"** rather than asserting **"whether things are correct."**

### When This Approach Works Well

- Mixed macOS and Linux environments
- Corporate-managed machines are involved
- GUI and CLI tools coexist
- Latest-version tracking is acceptable
- Willingness to fix breakage exists

### When to Move On

This design is **not meant to last forever**. Clear signals to consider migration:

- **Doctor is perpetually red** — drift can be observed but no longer fixed in time. The operational scale has outgrown this approach.
- **Reproducibility becomes mandatory** — CI environments, shared dev setups, or incident investigation demand exact reproduction. Nix, devcontainers, or VMs are more appropriate.
- **YAML becomes a manual** — install sections bloat, conditionals multiply, bash turns into a DSL. The tool has become the goal. Nix, Ansible, or OS imaging provides stronger abstraction.
- **Full OS management is needed** — systemd, kernel/driver, OS security policies are out of scope for this design.

### Easy to Walk Away From

A key design property: **appctl is easy to remove.** brew/apt remain intact, chezmoi continues independently, and deleting appctl breaks nothing. This is an intentional design decision. This repository prioritizes **sustainability over completeness** — it preserves the ability to observe and fix failures, and when limits are reached, to walk away cleanly.

## Key Commands

### Dotfiles Management
- `chezmoi apply` - Apply dotfiles
- `chezmoi managed` - Show all managed files
- `chezmoi purge` - Remove chezmoi-managed files

### Package Management via appctl
- `./appctl/appctl install [app...]` - Install apps (all if no args)
- `./appctl/appctl upgrade [app...]` - Upgrade apps
- `./appctl/appctl uninstall <app...>` - Uninstall specified apps
- `./appctl/appctl status [app...]` - Show app status
- `./appctl/appctl list` - List all defined apps
- `./appctl/appctl doctor` - Health check

## Architecture

### Directory Structure
- `chezmoi/` - chezmoi source directory containing all dotfiles
  - `chezmoi/dot_config/zsh/` - Modular zsh configuration files deployed to `~/.config/zsh/`
- `appctl/` - Declarative package management tool
- `apps/` - App definitions (YAML) for appctl
- `.chezmoiroot` - Points chezmoi to use `chezmoi/` as source directory

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
command: example-bin  # binary name if different from app name (used for status checks)

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

  - type: apt
    package: pkg1 pkg2       # multiple packages (space-separated)
    os: linux
    pre_install: |           # run before apt-get install (e.g. add repo)
      curl -fsSL https://example.com/key.gpg | sudo tee /etc/apt/keyrings/example.gpg >/dev/null
      echo "deb [signed-by=/etc/apt/keyrings/example.gpg] https://example.com/repo stable main" \
        | sudo tee /etc/apt/sources.list.d/example.list >/dev/null
      sudo apt-get update
    uninstall: |             # run after apt-get remove (e.g. cleanup repo)
      sudo rm -f /etc/apt/sources.list.d/example.list
      sudo rm -f /etc/apt/keyrings/example.gpg

  - type: go
    package: example.com/cmd/example@latest

  - type: custom
    os: linux
    check: command -v example
    script: |
      curl -fsSL https://example.com/install.sh | bash
    uninstall: |
      rm -f /usr/local/bin/example
    version_cmd: example --version 2>/dev/null | awk '{print $2}'  # custom version detection
```

**Bootstrap Dependencies:**
appctl requires `jq` and `yq` to parse YAML. Install them manually following official instructions:
- jq: https://jqlang.github.io/jq/download/
- yq: https://github.com/mikefarah/yq#install

### chezmoi Naming Convention
Files in `chezmoi/` use chezmoi's naming convention:
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
- `dot_config/zsh/` → `~/.config/zsh/` - Modular zsh configuration files (git, kubernetes, misc, sdk)
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
The `.zshrc` sources modular configuration files from `~/.config/zsh/` (managed by chezmoi via `chezmoi/dot_config/zsh/`):
- `git.zsh` - Git-related functions and aliases
- `kubernetes.zsh` - Kubernetes utilities
- `misc.zsh` - General utilities and aliases
- `sdk.zsh` - SDK and development environment setup

These modules are deployed by chezmoi and sourced via `$XDG_CONFIG_HOME/zsh/` at shell startup.

## Working with This Repository

When modifying configurations:
1. Edit files in `chezmoi/` directory (using chezmoi naming convention)
2. Run `chezmoi apply` to apply changes
3. Test changes by opening a new shell session

### Adding New Apps
1. Create a YAML file in `apps/` directory (e.g., `apps/myapp.yaml`)
2. Define the app with appropriate handlers for each OS
3. Run `./appctl/appctl install myapp` to install

### Adding New Dotfiles
1. Create file in `chezmoi/` with appropriate chezmoi prefix:
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

# Install bootstrap dependencies (jq, yq) following official instructions:
#   jq: https://jqlang.github.io/jq/download/
#   yq: https://github.com/mikefarah/yq#install

# Install chezmoi and other apps
./appctl/appctl install chezmoi
./appctl/appctl install

# Initialize chezmoi with this repo
chezmoi init --source=/path/to/dotfiles --apply
```
