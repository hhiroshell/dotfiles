# ================
# Common Settings
# ================

# fzf
if [[ "$(uname)" == "Linux" ]]; then
    source "/usr/share/doc/fzf/examples/completion.zsh"
    source "/usr/share/doc/fzf/examples/key-bindings.zsh"
elif [[ "$(uname)" == "Darwin" ]]; then
    source "/opt/homebrew/opt/fzf/shell/completion.zsh"
    source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
fi

export FZF_DEFAULT_OPTS=" \
    --height 30% \
    --layout=reverse \
    --border \
    --color=light \
    --color=bg+:#E9E4E2 \
    --color=pointer:red,marker:red,gutter:#F0EDEC"

# nvim
alias vim='nvim'

# goimports-reviser
alias goimports-reviser='goimports-reviser -rm-unused -recursive'

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

# Line count utility
# cf. https://qiita.com/UedaTakeyuki/items/c025b334fe18a391c421
cloc-git() {
    tempdir="$(mktemp -d)"
    git clone --depth 1 "$1" "${tempdir}"
    cloc "${tempdir}"
}

today() {
    date '+%Y-%m-%d'
}

temp() {
    mkdir -p "${HOME}/temp/$(today)"
    cd $_
}
