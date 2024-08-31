if [[ "$(uname)" == "Linux" ]]; then
    IDEA_HOME="/usr/local/idea-IU"
elif [[ "$(uname)" == "Darwin" ]]; then
    IDEA_HOME="/Applications/IntelliJ IDEA.app/Contents"
fi

_idea-version() {
    if [[ "$(uname)" == "Linux" ]]; then
        < "${IDEA_HOME}/product-info.json" jq -r '.version'
    elif [[ "$(uname)" == "Darwin" ]]; then
        < "${IDEA_HOME}/Resources/product-info.json" jq -r '.version'
    fi
}

_idea-archives() {
    local platform
    if [[ "$(uname)" == "Linux" ]]; then
        platform="linux"
    elif [[ "$(uname)" == "Darwin" ]]; then
        if [[ "$(uname -m)" == "arm64" ]]; then
            platform="macM1"
        else
            platform="mac"
        fi
    fi

    local candidates=$(curl -s "https://data.services.jetbrains.com/products?code=IIU&release.type=release" \
        | jq -r ".[].releases[].downloads.${platform}.link" \
        | grep -v "null" \
        | head \
        | while read url; do basename "$url"; done
    )

    echo ${candidates} | while read archive; do
        if [[ "${archive}" =~ $(_idea-version) ]]; then
            echo "${archive} (<- installed)"
        else
            echo "${archive}"
        fi
    done
}

_idea-install() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "Please use Homebrew to install it on Darwin (macOS)."
        echo ""
        echo "$ brew [install|upgrade] --cask intellij-idea"
        return 1
    fi

    # From here, the installation steps are confirmed to work only on Linux.
    local archive
    archive=$(_idea-archives | fzf)
    if [ $? -ne 0 ]; then
        return 1
    fi

    if [[ "${archive}" =~ "installed" ]]; then
        echo "You are already using the specified version."
        return 1
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"

    echo "🔄 Downloading ${archive} ... 🔄"
    url=$(curl -s "https://data.services.jetbrains.com/products?code=IIU&release.type=release" \
        | jq -r '.[].releases[].downloads.linux.link' \
        | grep -e "${archive}" \
    )
    curl -L "${url}" --output "${tmpdir}/${archive}"

    echo ""
    echo "📦 Extracting ${archive} ... 📦"
    tar -x -f "${tmpdir}/${archive}" -C "${tmpdir}"

    echo ""
    echo "⚙️ Installing... ⚙️"
    sudo rm -rf "${IDEA_HOME}"
    if [ $? -ne 0 ]; then
        echo "failed to remove old installation"
        return 1
    fi
    local base
    base="$(tar -t -f ${tmpdir}/${archive} | grep '/$' | head -n 1 | sed 's/\/$//')"
    sudo mv "${tmpdir}/${base}" "${IDEA_HOME}"
    if [ $? -ne 0 ]; then
        echo "failed to extract the idea archive"
        return 1
    fi

    echo ""
    echo "Done. 👍"
}

_idea-run() {
    local target
    if [ "$#" -lt 1 ]; then
        local repo
        repo=$(ghq list | fzf)
        if [ $? -ne 0 ]; then
            return 1
        fi

        target="$(ghq root)/${repo}"
    else
        target="$1"
    fi

    if [[ "$(uname)" == "Linux" ]]; then
        "${IDEA_HOME}/bin/idea" "${target}" > /dev/null 2>&1 &
    elif [[ "$(uname)" == "Darwin" ]]; then
        "${IDEA_HOME}/MacOS/idea" "${target}" > /dev/null 2>&1 &
    fi
}

_idea-usage() {
    echo "TODO: print usages"
}

idea() {
    if [ "$#" -lt 1 ]; then
        _idea-usage
        return 1
    fi

    subcommand="$1"
    shift
    case $subcommand in
        version)
            _idea-version
            ;;
        archives)
            _idea-archives
            ;;
        install)
            _idea-install
            ;;
        run)
            _idea-run "$@"
            ;;
        *)
            _idea-usage
            return 1
            ;;
    esac
}
