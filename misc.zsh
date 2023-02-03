# ================
# Common Settings
# ================

export FZF_DEFAULT_OPTS='--height 30% --layout=reverse --border'

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
