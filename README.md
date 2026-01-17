# dotfiles

Personal dotfiles managed through symbolic links.

## Prerequisites

- [aqua](https://aquaproj.github.io/) - Declarative CLI version manager
- [zsh](https://www.zsh.org/) with [zimfw](https://zimfw.sh/)
- [starship](https://starship.rs/) - Shell prompt

## Installation

### Clone this repository

```console
$ ghq get git@github.com:hhiroshell/dotfiles.git

$ cd $(ghq list --full-path --exact hhiroshell/dotfiles)
```

### Create symlinks

```console
$ make install
```

### Install development tools

```console
$ aqua install
```

## Commands

| Command          | Description                              |
|------------------|------------------------------------------|
| `make install`   | Create symlinks from `home/` to `$HOME`  |
| `make uninstall` | Remove symlinks created by `make install`|
| `make list`      | Show all managed dotfile targets         |

## What's Included

### Shell
- **zsh** - Shell configuration with zimfw
- **starship** - Cross-shell prompt

### Editors
- **Helix** - Modal text editor with zenbones theme
- **Neovim** - Vim-based editor
- **IdeaVim** - Vim emulation for IntelliJ IDEs

### Terminal
- **Kitty** - GPU-accelerated terminal emulator
- **tmux** - Terminal multiplexer

### Development Tools (via aqua)
- Languages: Go, Node.js, Rust
- Editors: helix, neovim
- Kubernetes: kubectl, kind, krew, kustomize
- Utilities: fzf, jq, yq, ghq, fd

### Git
- Global gitconfig and gitignore

## Directory Structure

```
.
├── home/           # Dotfiles (symlinked to $HOME)
│   ├── .aqua/      # aqua configuration
│   ├── .config/    # XDG config (helix, kitty, nvim, tmux, starship)
│   ├── .gitconfig
│   ├── .ssh/
│   └── .zshrc
├── zsh/            # Modular zsh configurations
│   ├── git.zsh
│   ├── kubernetes.zsh
│   └── ...
└── Makefile
```
