# ================
# Common Settings
# ================

# fzf
export FZF_DEFAULT_OPTS='--height 30% --layout=reverse --border --color=bg:#FFFFFF,bg+:#C2D8E4,fg:#282629,fg+:#282629,pointer:#007BBB,marker:#656066,spinner:#81A1C1,hl:#616E88,header:#616E88,info:#81A1C1,prompt:#81A1C1,hl+:#81A1C1'

# bat
alias bat='batcat'
export BAT_THEME="Monokai Extended Light"

# nvim
alias vim='nvim'


# ==========
# Utilities
# ==========

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

# today
today() {
    date '+%Y-%m-%d'

}

# history fuzzy finder
function search-history() {
    BUFFER=$(history -n -r 1 | fzf --exact --no-sort --prompt="History > ")
    CURSOR=$#BUFFER
}
zle -N search-history
bindkey '^h' search-history
