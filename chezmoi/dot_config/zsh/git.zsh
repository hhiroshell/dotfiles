_ghq-cd() {
    local repo
    repo=$(ghq list | fzf)
    if [ $? -ne 0 ]; then
        return 1
    fi

    cd "$(ghq root)/${repo}"
}

alias gd='_ghq-cd'

_gh-browse() {
    gh browse "$@" &>/dev/null
}

alias gb='_gh-browse'

_gh-fuzzy-clone() {
    if [ -z "$1" ]; then
        echo "Usage: ghc <github-url-or-owner/repo>" >&2
        return 1
    fi

    local input="$1"
    shift
    local repo="$input"

    # Strip scheme (https://, http://, ssh://, git://)
    repo="${repo#*://}"
    # Strip git@ prefix (SSH URLs)
    repo="${repo#git@}"
    # Replace : with / (git@github.com:user/repo format)
    repo="${repo/:/\/}"
    # Strip github.com/ prefix
    repo="${repo#github.com/}"
    # Extract owner/repo (first two path segments)
    repo="$(echo "$repo" | cut -d'/' -f1,2)"
    # Strip .git suffix
    repo="${repo%.git}"

    if [ -z "$repo" ] || ! echo "$repo" | grep -q '/'; then
        echo "ghc: could not extract owner/repo from: $input" >&2
        return 1
    fi

    local dest="$(ghq root)/github.com/${repo}"
    gh repo clone "$repo" "$dest" "$@"
}

alias gc='_gh-fuzzy-clone'
