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

# bat
alias bat='batcat'
export BAT_THEME="Monokai Extended Light"

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
        elif [[ "$1" =~ "^http://" ]] || [[ "$1" =~ "^https://" ]] ; then
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

# history fuzzy finder
function search-history() {
    BUFFER=$(history -n -r 1 | fzf --exact --no-sort --prompt="History > ")
    CURSOR=$#BUFFER
}
zle -N search-history
bindkey '^h' search-history
