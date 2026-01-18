# ================
# Common Settings
# ================

# fzf
# set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

export FZF_DEFAULT_OPTS=" \
    --height 30% \
    --layout=reverse \
    --border \
    --color=light \
    --color=bg+:#E3E1E0 \
    --color=pointer:red,marker:red,gutter:#F0EDEC"

# nvim
alias vim='nvim'

# history
setopt extended_history
alias history='history -t "%F %T"'

# goimports-reviser
alias goimports-reviser='goimports-reviser -rm-unused -recursive'

# qmk
# cf. https://docs.qmk.fm/#/newbs_getting_started?id=set-up-qmk
PATH="$HOME/.local/bin:$PATH"

# exit
alias q='exit'

# ==========
# Utilities
# ==========

# Clipboard utilities for compatibility with macOS
if [[ "$(uname)" == "Linux" ]]; then
    if command -v xclip &> /dev/null; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
    fi
fi

today() {
    date '+%Y-%m-%d'
}

temp() {
    mkdir -p "${HOME}/temp/$(today)"
    cd $_

    TEMPDIR="$(pwd)" && export TEMPDIR
    echo "environment valuable \"TEMPDIR\" is set to \"$(pwd)\" ."
}

# Line count utility
# cf. https://qiita.com/UedaTakeyuki/items/c025b334fe18a391c421
cloc-git() {
    tempdir="$(mktemp -d)"
    git clone --depth 1 "$1" "${tempdir}"
    cloc "${tempdir}"
}
