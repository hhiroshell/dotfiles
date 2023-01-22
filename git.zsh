ghq-cd() {
    local repo
    repo=$(ghq list | fzf)
    if [ $? -ne 0 ]; then
        return 1
    fi

    cd "$(ghq root)/${repo}"
}

alias gcd='ghq-cd'

alias gh-open-current-dir='open $(git config remote.origin.url | sed -e "s/ssh:\/\/git@/https:\/\//")'

gh-open() {
    if [ "$1" = "." ] || [ "$1" = "$(pwd)" ]; then
        gh-open-current-dir
    else
        pushd "$1"
        gh-open-current-dir
        popd
    fi
}

ghq-gh-open() {
    if [ -n "$1" ]; then
        gh-open "$1"
    else
        local repo
        repo=$(ghq list | fzf)
        if [ $? -ne 0 ]; then
            return 1
        fi

        gh-open "$(ghq root)/${repo}"
    fi
}

alias gh='ghq-gh-open'
