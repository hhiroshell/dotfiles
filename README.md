dotfiles
===

Installation
---

### Clone this repository and move into it.

```console
$ ghq get git@github.com:hhiroshell/dotfiles.git

$ cd $(ghq list --full-path --exact hhiroshell/dotfiles)
```

### Create symlinks.

```console
$ ln -s /home/hhiroshell/src/github.com/hhiroshell/dotfiles/home/.config ~/.config

$ ln -s /home/hhiroshell/src/github.com/hhiroshell/dotfiles/home/.gitconfig ~/.gitconfig

$ ln -s /home/hhiroshell/src/github.com/hhiroshell/dotfiles/home/.gitignore_global ~/.gitignore_global

$ ln -s /home/hhiroshell/src/github.com/hhiroshell/dotfiles/home/.ssh/config ~/.ssh/config

$ ln -s /home/hhiroshell/src/github.com/hhiroshell/dotfiles/home/.zimrc ~/.zimrc

$ ln -s /home/hhiroshell/src/github.com/hhiroshell/dotfiles/home/.zshrc ~/.zshrc
```
