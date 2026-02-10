# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Prerequisites

- [appctl](appctl/) - Declarative package management tool (included in this repo)
- Platform-specific package managers:
  - [Homebrew](https://brew.sh/) (macOS) - For GUI apps and system tools
  - apt (Ubuntu/Debian) - For system packages and build dependencies
- [zsh](https://www.zsh.org/) with [zimfw](https://zimfw.sh/)
- [starship](https://starship.rs/) - Shell prompt

## Installation

### Clone this repository

```console
$ mkdir -p ~/src/github.com/hhiroshell

$ git clone git@github.com:hhiroshell/dotfiles.git ~/src/github.com/hhiroshell/dotfiles

$ cd ~/src/github.com/hhiroshell/dotfiles
```

### Install apps

```console
$ ./appctl/appctl install
```

### Apply dotfiles

```console
$ make install
# or
$ chezmoi init --source=. --apply
```

## Commands

| Command            | Description                                              |
|--------------------|----------------------------------------------------------|
| `make install`     | Apply dotfiles using chezmoi                             |
| `make uninstall`   | Remove chezmoi-managed files                             |
| `make list`        | Show all managed files                                   |
| `make brew-install`| Install packages from Brewfile (macOS)                   |
| `make apt-install` | Install packages from apt-packages.txt (Ubuntu/Debian)   |

## What's Included

### Shell
- **zsh** - Shell configuration with zimfw
- **starship** - Cross-shell prompt

### Editors
- **Helix** - Modal text editor with zenbones theme

### Terminal
- **Ghostty** - Fast, cross-platform terminal emulator
- **Kitty** - GPU-accelerated terminal emulator
- **tmux** - Terminal multiplexer

### Development Tools (via appctl)
- Languages: Go, Node.js, Rust
- Python: uv (manages Python versions, packages, and virtual environments)
- Editors: helix
- Kubernetes: kubectl, kind, krew, kustomize
- Utilities: fzf, jq, yq, ghq, fd, lazygit, chezmoi

### System Tools & Applications

**macOS (via Homebrew)**:
- GUI Apps: Ghostty, Google Chrome, Raycast, KeePassXC, Git Credential Manager, Gitify
- System utilities: tmux, starship, gh, colordiff
- Package management: Declarative Brewfile for reproducible setup

**Ubuntu/Debian (via apt)**:
- System utilities: curl, wget, git
- Package management: Declarative apt-packages.txt for reproducible setup

### Git
- Global gitconfig and gitignore

## Directory Structure

```
.
├── chezmoi/                # chezmoi source directory
│   ├── .chezmoi.toml.tmpl  # chezmoi config template
│   ├── .chezmoiignore      # files to ignore
│   ├── dot_claude/         # -> ~/.claude (settings, skills)
│   ├── dot_config/         # -> ~/.config (ghostty, helix, kitty, lazygit, tmux, starship)
│   ├── dot_gitconfig       # -> ~/.gitconfig
│   ├── dot_zshrc           # -> ~/.zshrc
│   └── private_dot_ssh/    # -> ~/.ssh (mode 0600)
├── zsh/                    # Modular zsh configurations (sourced via ghq)
│   ├── git.zsh
│   ├── kubernetes.zsh
│   └── ...
├── Brewfile                # Homebrew packages (macOS)
├── apt-packages.txt        # apt packages (Linux)
├── .chezmoiroot            # Points chezmoi to chezmoi/
└── Makefile
```

## Platform-Specific Settings

chezmoi templates handle OS-specific configurations:
- **Font sizes**: macOS uses larger fonts (13pt) than Linux (10pt) for Ghostty and Kitty
- **Notifications**: Linux uses `notify-send` for Claude Code hooks; macOS relies on native notifications
