_slow-yes() {
    while :
    do
        echo "y"
        sleep 1
    done
}

_ghq-idea() {
    if [ -n "$*" ]; then
        if [[ "$(uname -r)" == *microsoft* ]]; then
            _slow-yes | cmd.exe /c idea.bat $(wslpath -aw "$@") > /dev/null 2>&1 &
        elif [[ "$(uname)" == "Darwin" ]]; then
            "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "$@" > /dev/null 2>&1 &
        fi
    else
        local repo
        repo=$(ghq list | fzf)
        if [ $? -ne 0 ]; then
            return 1
        fi

        if [[ "$(uname -r)" == *microsoft* ]]; then
            _slow-yes | cmd.exe /c idea.bat $(wslpath -aw "$(ghq root)/${repo}") > /dev/null 2>&1 &
        elif [[ "$(uname)" == "Darwin" ]]; then
            "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "$(ghq root)/${repo}" > /dev/null 2>&1 &
        fi
    fi
}

alias idea='_ghq-idea'

# ======================
# Installation utilities
# ======================

list-idea-archives() {
    local current=$(cat /usr/local/idea-IU/product-info.json | jq -r '.version')

    local candidates=$(curl -s "https://data.services.jetbrains.com/products?code=IIU&release.type=release" \
        | jq -r '.[].releases[].downloads.linux.link' \
        | grep -v "null" \
        | head \
        | while read url; do basename "$url"; done
    )

    echo ${candidates} | while read archive; do
        if [[ "${archive}" =~ ${current} ]]; then
            echo "${archive} (<- installed)"
        else
            echo "${archive}"
        fi
    done
}

install-idea() {
    local archive
    archive=$(list-idea-archives | fzf)
    if [ $? -ne 0 ]; then
        return 1
    fi

    if [[ "${archive}" =~ "installed" ]]; then
        echo "You are already using the specified version."
        return 1
    fi

    tmpdir="$(mktemp -d)"

    echo "Downloading ${archive} ..."
    url=$(curl -s "https://data.services.jetbrains.com/products?code=IIU&release.type=release" \
        | jq -r '.[].releases[].downloads.linux.link' \
        | grep -e "${archive}" \
    )
    curl -L "${url}" --output "${tmpdir}/${archive}"


    echo "Extracting ${archive} ..."
    tar -x -f "${tmpdir}/${archive}" -C ${tmpdir}
    base="$(tar -t -f ${tmpdir}/${archive} | grep '/$' | head -n 1 | sed 's/\/$//')"
    mv "${tmpdir}/${base}" "${tmpdir}/idea-IU"

    echo "Removing old installation..."
    sudo rm -rf /usr/local/idea-IU
    if [ $? -ne 0 ]; then
        echo "failed to remove old installation"
        return 1
    fi

    echo "Installing..."
    sudo mv "${tmpdir}/idea-IU" /usr/local
    if [ $? -ne 0 ]; then
        echo "failed to extract the idea archive"
        return 1
    fi

    echo "Done."
}

# =====
# PATH
# =====

# "$HOME/go/bin" is for binaries installed via "go install"
export PATH="$PATH:/usr/local/idea-IU/bin"

