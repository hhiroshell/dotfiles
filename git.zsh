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

git-checkout() {
    if [ -n "$*" ]; then
        git checkout "$@"
    else
        local selected
        selected=$(git branch --all | grep -v "HEAD" | fzf --preview 'echo {} | cut -c 3- | xargs git log --color=always')
        if [ $? -ne 0 ]; then
	        return 1
        fi

        git checkout $(echo "${selected}" | cut -c 3- | sed -e 's#remotes/[^/]*/##')
    fi
}

alias gco='git-checkout'

_git_status() {
    local sts
    if [ -z "$*" ] || [ "$*" = "HEAD" ]; then
        sts=$(git status --short)
    else
        sts=$(git diff --name-status "$@")
    fi

    echo "${sts}"
}

git-diff() {
    local selected
    selected=$(echo "$(_git_status "$@")" | fzf \
        --preview 'echo {} | rev | cut -f1 -d" " | rev | xargs git diff --color=always "$@" --' \
        --multi \
        --height 90%)
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo $(echo "${selected}" | cut -c 4-)
}

alias gdf='git-diff'

git-rollback() {
    local selected
    selected=$(git-diff)
    if [ $? -ne 0 ]; then
	    return 1
    fi

    git checkout -- $(echo "${selected}" | sed -e 's/\n/ /g')
}

alias grb='git-rollback'

git-add() {
    local selected
    selected=$(git-diff)
    if [ $? -ne 0 ]; then
	    return 1
    fi

    git add $(echo "${selected}" | sed -e 's/\n/ /g')
}

alias gad='git-add'

git-add-interactive() {
    local selected
    selected=$(git-diff)
    if [ $? -ne 0 ]; then
	    return 1
    fi

    git add -p $(echo "${selected}" | sed -e 's/\n/ /g')
}

alias gadi='git-add-interactive'

git-reset() {
    local selected
    selected=$(git-diff)
    if [ $? -ne 0 ]; then
	    return 1
    fi

    git reset $(echo "${selected}" | sed -e 's/\n/ /g')
}

alias grs='git-reset'
