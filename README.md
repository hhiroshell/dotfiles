# dotfiles

Personal dotfiles managed through symbolic links.

## Prerequisites

- [aqua](https://aquaproj.github.io/) - Declarative CLI version manager
- [zsh](https://www.zsh.org/) with [zimfw](https://zimfw.sh/)
- [starship](https://starship.rs/) - Shell prompt

## Installation

### Clone this repository

```console
$ mkdir -p ~/src/github.com/hhiroshell

$ git clone git@github.com:hhiroshell/dotfiles.git ~/src/github.com/hhiroshell/dotfiles

$ cd ~/src/github.com/hhiroshell/dotfiles
```

### Create symlinks

```console
$ make install
```

## Commands

| Command          | Description                              |
|------------------|------------------------------------------|
| `make install`   | Create symlinks from `home/` to `$HOME`  |
| `make uninstall` | Remove symlinks created by `make install`|
| `make list`      | Show all managed dotfile mappings        |

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

### Development Tools (mostly via aqua)
- Languages: Java, Go, Node.js, Rust
- Editors: helix
- Kubernetes: kubectl, kind, krew, kustomize
- Utilities: fzf, jq, yq, ghq, fd

### Git
- Global gitconfig and gitignore

## Directory Structure

```
.
├── home/           # Dotfiles (symlinked to $HOME with dot prefix)
│   ├── aqua/       # -> ~/.aqua
│   ├── config/     # -> ~/.config (ghostty, helix, kitty, tmux, starship)
│   ├── gitconfig   # -> ~/.gitconfig
│   ├── ssh/        # -> ~/.ssh
│   └── zshrc       # -> ~/.zshrc
├── zsh/            # Modular zsh configurations
│   ├── git.zsh
│   ├── kubernetes.zsh
│   └── ...
└── Makefile
```
