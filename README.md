# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Prerequisites

- [pkgmux](pkgmux/) (Package Manager Multiplexer) - Declarative package management tool (included in this repo)
- Platform-specific package managers:
  - [Homebrew](https://brew.sh/) (macOS) - For GUI apps and system tools
  - apt (Ubuntu/Debian) - For system packages and build dependencies
- [zsh](https://www.zsh.org/)

## Installation

### Clone this repository

```console
$ mkdir -p ~/src/github.com/hhiroshell

$ git clone git@github.com:hhiroshell/dotfiles.git ~/src/github.com/hhiroshell/dotfiles

$ cd ~/src/github.com/hhiroshell/dotfiles
```

### Install apps

```console
$ ./pkgmux/pkgmux install
```

### Apply dotfiles

```console
$ chezmoi init --source=. --apply
```

## Commands

| Command                              | Description                     |
|--------------------------------------|---------------------------------|
| `./pkgmux/pkgmux install [app...]`   | Install apps (all if no args)   |
| `./pkgmux/pkgmux upgrade [app...]`   | Upgrade apps                    |
| `./pkgmux/pkgmux uninstall <app...>` | Uninstall specified apps        |
| `./pkgmux/pkgmux status [app...]`    | Show app status                 |
| `./pkgmux/pkgmux list`               | List all defined apps           |
| `./pkgmux/pkgmux doctor`             | Health check                    |

## What's Included

### Shell
- **zsh** - Shell configuration with zimfw plugin manager

### Editors
- **Helix** - Modal text editor with zenbones theme

### Terminal
- **Ghostty** - Fast, cross-platform terminal emulator
- **Kitty** - GPU-accelerated terminal emulator
- **tmux** - Terminal multiplexer

### Development Tools (via pkgmux)
- **Languages & Runtimes**: Go, Node.js, Rust, uv
- **Editors**: Helix
- **Version Control**: Git, gh, Lazygit, Git Credential Manager
- **Containers & Kubernetes**: Docker CLI, Lima, kubectl, kind, krew, kustomize
- **Go Tools**: gopls, golangci-lint, staticcheck, delve, goimports-reviser, setup-envtest, golangci-lint-langserver
- **CLI Utilities**: fzf, fd, jq, yq, ghq, btop, colordiff, curl, wget, hugo, deck, chezmoi, starship
- **AI**: Claude Code

### macOS GUI Apps (via Homebrew Cask)
- Alt-Tab, Ghostty, Git Credential Manager, Gitify, Google Chrome, Google Drive, Google Japanese IME, HiddenBar, KeePassXC, Mac Mouse Fix, MeetingBar, Raycast
- **Fonts**: HackGen Nerd

### Git
- Global gitconfig and gitignore

### SSH
- SSH client configuration (private)

### Claude Code
- Settings and custom skills

## Directory Structure

```
.
├── pkgmux/                 # Declarative package management tool
├── apps/                   # App definitions (YAML) for pkgmux
├── chezmoi/                # chezmoi source directory
│   ├── dot_claude/         # -> ~/.claude (settings, skills)
│   ├── dot_config/         # -> ~/.config (ghostty, helix, kitty, lazygit, tmux, zsh, starship)
│   ├── dot_gitconfig       # -> ~/.gitconfig
│   ├── dot_gitignore_global # -> ~/.gitignore_global
│   ├── dot_zimrc           # -> ~/.zimrc
│   ├── dot_zshenv          # -> ~/.zshenv
│   ├── dot_zshrc           # -> ~/.zshrc
│   └── private_dot_ssh/    # -> ~/.ssh (mode 0600)
├── .chezmoiroot            # Points chezmoi to chezmoi/
└── CLAUDE.md               # Claude Code project instructions
```

## Platform-Specific Settings

chezmoi templates handle OS-specific configurations:
- **Font sizes**: macOS uses larger fonts (13pt) than Linux (10pt) for Ghostty and Kitty
- **Notifications**: Linux uses `notify-send` for Claude Code hooks; macOS relies on native notifications
