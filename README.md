# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Prerequisites

- [appctl](appctl/) - Declarative package management tool (included in this repo)
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
$ ./appctl/appctl install
```

### Apply dotfiles

```console
$ chezmoi init --source=. --apply
```

## Commands

| Command                              | Description                     |
|--------------------------------------|---------------------------------|
| `./appctl/appctl install [app...]`   | Install apps (all if no args)   |
| `./appctl/appctl upgrade [app...]`   | Upgrade apps                    |
| `./appctl/appctl uninstall <app...>` | Uninstall specified apps        |
| `./appctl/appctl status [app...]`    | Show app status                 |
| `./appctl/appctl list`               | List all defined apps           |
| `./appctl/appctl doctor`             | Health check                    |

## What's Included

### Shell
- **zsh** - Shell configuration with zimfw plugin manager

### Editors
- **Helix** - Modal text editor with zenbones theme

### Terminal
- **Ghostty** - Fast, cross-platform terminal emulator
- **Kitty** - GPU-accelerated terminal emulator
- **tmux** - Terminal multiplexer

### Development Tools (via appctl)
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
├── appctl/                 # Declarative package management tool
├── apps/                   # App definitions (YAML) for appctl
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
