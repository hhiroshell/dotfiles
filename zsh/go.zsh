# ======================
# Installation utilities
# ======================

list-go-archives() {
    local current=$(go version | cut -d" " -f 3) 2>/dev/null

    local candidates=$(curl -s https://go.dev/dl/ \
        | pup 'a[class="download"] text{}' \
        | grep "linux-amd64" \
        | sort --version-sort -r \
        | grep -e "1.19" -e "1.20" -e "1.21" -e "1.22" \
    )

    echo ${candidates} | while read archive; do
        if [[ "${archive}" =~ ${current} ]]; then
            echo "${archive} (<- installed)"
        else
            echo "${archive}"
        fi
    done
}

install-go() {
    local archive
    archive=$(list-go-archives | fzf)
    if [ $? -ne 0 ]; then
        return 1
    fi

    if [[ "${archive}" =~ "installed" ]]; then
        echo "You are already using the specified version."
        return 1
    fi

    tmpdir="$(mktemp -d)"

    echo "Downloading ${archive}"
    curl -L "https://go.dev/dl/${archive}" --output "${tmpdir}/${archive}"

    echo ""
    echo "Installing..."
    sudo rm -rf /usr/local/go
    if [ $? -ne 0 ]; then
        echo "failed to remove old installation"
        return 1
    fi
    sudo tar -x -f "${tmpdir}/${archive}" -C /usr/local
    if [ $? -ne 0 ]; then
        echo "failed to extract the go archive"
        return 1
    fi

    echo ""
    echo "Done."
}


# =====
# PATH
# =====

# "$HOME/go/bin" is for binaries installed via "go install"
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
