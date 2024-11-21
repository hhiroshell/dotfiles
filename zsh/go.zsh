# ======================
# Installation utilities
# ======================

_go-tool-list-archives() {
    local current=$(go version | cut -d" " -f 3) 2>/dev/null

    local candidates=$(curl -s https://go.dev/dl/ \
        | pup 'a[class="download"] text{}' \
        | grep "linux-amd64" \
        | sort --version-sort -r \
        | grep -e "1.22" -e "1.23" -e "1.24" -e "1.25" \
    )

    echo ${candidates} | while read archive; do
        if [[ "${archive}" =~ ${current} ]]; then
            echo "${archive} (<- installed)"
        else
            echo "${archive}"
        fi
    done
}

_go-tool-install() {
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

_go-tool-usage() {
cat << EOF
Usage: go-tool [subcommand]

Subcommands:
  archives  List Go archives
  install   Install the selected version of Go
  usage     Print this message
EOF
}

go-tool() {
    if [ "$#" -lt 1 ]; then
        _go-tool-usage
        return 1
    fi

    subcommand="$1"
    shift
    case $subcommand in
        archives)
            _go-tool-list-archives
            ;;
        install)
            _go-tool-install
            ;;
        usage)
            _go-tool-usage
            ;;
        *)
            _go-tool-usage
            return 1
            ;;
    esac
}
