# ================
# Common Settings
# ================

# fzf
export FZF_DEFAULT_OPTS=" \
    --height 30% \
    --layout=reverse \
    --border \
    --color=light \
    --color=bg+:#E9E4E2 \
    --color=pointer:red,marker:red,gutter:#F0EDEC"

# nvim
alias vim='nvim'

# qmk
# cf. https://docs.qmk.fm/#/newbs_getting_started?id=set-up-qmk
PATH="$HOME/.local/bin:$PATH"

# ==========
# Utilities
# ==========

# WSL utilities for compatibility with masOS X
if [[ "$(uname -r)" == *microsoft* ]]; then
    # cf. https://zenn.dev/kaityo256/articles/open_command_on_wsl
    function open() {
        if [ $# != 1 ]; then
            explorer.exe .
        else
            if [ -e $1 ]; then
                cmd.exe /c start "$(wslpath -w $1)" 2> /dev/null
            elif [[ "$1" =~ "^http://" ]] || [[ "$1" =~ "^https://" ]]; then
                cmd.exe /c start "$1" 2> /dev/null
            else
                echo "open: $1 : No such file or directory"
            fi
        fi
    }

    # cf. https://zenn.dev/kondounagi/scraps/184c884b5804a4
    alias pbcopy='clip.exe'
    alias pbpaste='powershell.exe -Command Get-Clipboard'
fi

today() {
    date '+%Y-%m-%d'
}

temp() {
    mkdir -p "${HOME}/temp/$(today)"
    cd $_
}

# history
# cf. https://mogulla3.tech/articles/2021-09-06-search-command-history-with-incremental-search/
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt share_history

function search-history() {
    BUFFER=$(history -n -r 1 | fzf --exact --no-sort --prompt="History > ")
    CURSOR=${#BUFFER}
}
zle -N search-history
bindkey '^h' search-history
