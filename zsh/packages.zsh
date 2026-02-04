# ================================
# Package auto-update detection
# ================================

# Cache and lock file locations
_pkg_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-pkg-updates"
_pkg_lock_file="/tmp/dotfiles-pkg-check.lock"
_pkg_cache_expiry=3600  # 1 hour in seconds

# Get the dotfiles directory path
_pkg_dotfiles_dir() {
    ghq list --full-path --exact dotfiles 2>/dev/null | head -1
}

# ================================
# Dotfiles sync checks (fast)
# ================================

# Check if a file has changed on remote
_pkg_check_remote_diff() {
    local file="$1"
    local dotfiles_dir
    dotfiles_dir=$(_pkg_dotfiles_dir)

    [[ -z "$dotfiles_dir" ]] && return 1

    (
        cd "$dotfiles_dir" || exit 1
        git fetch origin --quiet 2>/dev/null || exit 1

        local local_rev remote_rev
        local_rev=$(git rev-parse HEAD:"$file" 2>/dev/null)
        remote_rev=$(git rev-parse origin/main:"$file" 2>/dev/null)

        [[ -n "$local_rev" ]] && [[ -n "$remote_rev" ]] && [[ "$local_rev" != "$remote_rev" ]]
    )
}

# Check dotfiles sync for all package managers
_pkg_check_dotfiles_sync() {
    # aqua
    if _pkg_check_remote_diff "home/aqua/aqua.yaml"; then
        echo "\033[1;33m[aqua] Updates available. Run 'aqua-update' to apply.\033[0m"
    fi

    # brew (macOS only)
    if [[ "$(uname)" == "Darwin" ]]; then
        if _pkg_check_remote_diff "home/Brewfile"; then
            echo "\033[1;33m[brew] Brewfile changed. Run 'brew-update' to apply.\033[0m"
        fi
    fi

    # apt (Linux only)
    if [[ "$(uname)" == "Linux" ]] && command -v apt &>/dev/null; then
        if _pkg_check_remote_diff "home/apt-packages.txt"; then
            echo "\033[1;33m[apt] Package list changed. Run 'apt-update' to apply.\033[0m"
        fi
    fi
}

# ================================
# Background upstream checks
# ================================

# Run upstream update checks in background
_pkg_check_upstream_background() {
    mkdir -p "$_pkg_cache_dir"

    # Try to acquire lock (non-blocking)
    exec 9>"$_pkg_lock_file"
    flock -n 9 || return 0

    (
        # brew outdated (macOS only)
        if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
            local brew_outdated
            brew_outdated=$(brew outdated --quiet 2>/dev/null)
            if [[ -n "$brew_outdated" ]]; then
                local count=$(echo "$brew_outdated" | wc -l | tr -d ' ')
                echo "$brew_outdated" > "$_pkg_cache_dir/brew-outdated"
                echo "$count" > "$_pkg_cache_dir/brew-outdated-count"
            else
                rm -f "$_pkg_cache_dir/brew-outdated" "$_pkg_cache_dir/brew-outdated-count"
            fi
        fi

        # apt upgradable (Linux only)
        if [[ "$(uname)" == "Linux" ]] && command -v apt &>/dev/null; then
            local apt_upgradable
            apt_upgradable=$(apt list --upgradable 2>/dev/null | grep -v "^Listing")
            if [[ -n "$apt_upgradable" ]]; then
                local count=$(echo "$apt_upgradable" | wc -l | tr -d ' ')
                echo "$apt_upgradable" > "$_pkg_cache_dir/apt-upgradable"
                echo "$count" > "$_pkg_cache_dir/apt-upgradable-count"
            else
                rm -f "$_pkg_cache_dir/apt-upgradable" "$_pkg_cache_dir/apt-upgradable-count"
            fi
        fi

        # Mark check as complete with timestamp
        date +%s > "$_pkg_cache_dir/last-check"
    ) &>/dev/null &
    disown
}

# Check if cache is expired
_pkg_cache_expired() {
    local last_check_file="$_pkg_cache_dir/last-check"
    [[ ! -f "$last_check_file" ]] && return 0

    local last_check=$(cat "$last_check_file")
    local now=$(date +%s)
    (( now - last_check > _pkg_cache_expiry ))
}

# Flag to track if we've shown notifications this session
typeset -g _pkg_notifications_shown=0

# Show notifications from background check results (called via precmd)
_pkg_show_upstream_notifications() {
    # Only show once per session
    (( _pkg_notifications_shown )) && return 0

    # Check if results are ready
    [[ ! -f "$_pkg_cache_dir/last-check" ]] && return 0

    local has_notifications=0

    # brew
    if [[ -f "$_pkg_cache_dir/brew-outdated-count" ]]; then
        local count=$(cat "$_pkg_cache_dir/brew-outdated-count")
        if (( count > 0 )); then
            echo "\033[1;36m[brew] $count package(s) outdated. Run 'brew upgrade' to update.\033[0m"
            has_notifications=1
        fi
    fi

    # apt
    if [[ -f "$_pkg_cache_dir/apt-upgradable-count" ]]; then
        local count=$(cat "$_pkg_cache_dir/apt-upgradable-count")
        if (( count > 0 )); then
            echo "\033[1;36m[apt] $count package(s) upgradable. Run 'sudo apt upgrade' to update.\033[0m"
            has_notifications=1
        fi
    fi

    _pkg_notifications_shown=1
}

# precmd hook to show notifications
_pkg_precmd_hook() {
    _pkg_show_upstream_notifications
}

# ================================
# Update commands
# ================================

# aqua update
aqua-update() {
    local dotfiles_dir
    dotfiles_dir=$(_pkg_dotfiles_dir)

    if [[ -z "$dotfiles_dir" ]]; then
        echo "Error: dotfiles directory not found"
        return 1
    fi

    cd "$dotfiles_dir" || return 1

    git fetch origin --quiet 2>/dev/null || {
        echo "Failed to fetch from remote"
        return 1
    }

    local local_rev remote_rev
    local_rev=$(git rev-parse HEAD:home/aqua/aqua.yaml 2>/dev/null)
    remote_rev=$(git rev-parse origin/main:home/aqua/aqua.yaml 2>/dev/null)

    if [[ "$local_rev" == "$remote_rev" ]]; then
        echo "aqua.yaml is already up to date"
        return 0
    fi

    echo "Changes in aqua.yaml:"
    git diff HEAD..origin/main -- home/aqua/aqua.yaml | head -50
    echo ""

    printf "Pull changes and run 'aqua install'? [y/N] "
    read -r answer
    case "$answer" in
        [Yy]*)
            git pull origin main --quiet && \
            echo "Running aqua install..." && \
            aqua install
            ;;
        *)
            echo "Skipped aqua update"
            ;;
    esac
}

# brew update (sync from dotfiles)
brew-update() {
    local dotfiles_dir
    dotfiles_dir=$(_pkg_dotfiles_dir)

    if [[ -z "$dotfiles_dir" ]]; then
        echo "Error: dotfiles directory not found"
        return 1
    fi

    cd "$dotfiles_dir" || return 1

    git fetch origin --quiet 2>/dev/null || {
        echo "Failed to fetch from remote"
        return 1
    }

    local local_rev remote_rev
    local_rev=$(git rev-parse HEAD:home/Brewfile 2>/dev/null)
    remote_rev=$(git rev-parse origin/main:home/Brewfile 2>/dev/null)

    if [[ "$local_rev" == "$remote_rev" ]]; then
        echo "Brewfile is already up to date"
        return 0
    fi

    echo "Changes in Brewfile:"
    git diff HEAD..origin/main -- home/Brewfile | head -50
    echo ""

    printf "Pull changes and run 'brew bundle install'? [y/N] "
    read -r answer
    case "$answer" in
        [Yy]*)
            git pull origin main --quiet && \
            echo "Running brew bundle install..." && \
            brew bundle install --file="$dotfiles_dir/home/Brewfile"
            ;;
        *)
            echo "Skipped brew update"
            ;;
    esac
}

# apt update (sync from dotfiles)
apt-update() {
    local dotfiles_dir
    dotfiles_dir=$(_pkg_dotfiles_dir)

    if [[ -z "$dotfiles_dir" ]]; then
        echo "Error: dotfiles directory not found"
        return 1
    fi

    cd "$dotfiles_dir" || return 1

    git fetch origin --quiet 2>/dev/null || {
        echo "Failed to fetch from remote"
        return 1
    }

    local local_rev remote_rev
    local_rev=$(git rev-parse HEAD:home/apt-packages.txt 2>/dev/null)
    remote_rev=$(git rev-parse origin/main:home/apt-packages.txt 2>/dev/null)

    if [[ "$local_rev" == "$remote_rev" ]]; then
        echo "apt-packages.txt is already up to date"
        return 0
    fi

    echo "Changes in apt-packages.txt:"
    git diff HEAD..origin/main -- home/apt-packages.txt | head -50
    echo ""

    printf "Pull changes and run 'apt install'? [y/N] "
    read -r answer
    case "$answer" in
        [Yy]*)
            git pull origin main --quiet && \
            echo "Running apt install..." && \
            grep -v '^#' "$dotfiles_dir/home/apt-packages.txt" | grep -v '^$' | xargs sudo apt install -y
            ;;
        *)
            echo "Skipped apt update"
            ;;
    esac
}

# Show detailed outdated packages
brew-outdated() {
    if [[ -f "$_pkg_cache_dir/brew-outdated" ]]; then
        echo "Outdated brew packages (cached):"
        cat "$_pkg_cache_dir/brew-outdated"
    else
        echo "No cached data. Running brew outdated..."
        brew outdated
    fi
}

apt-upgradable() {
    if [[ -f "$_pkg_cache_dir/apt-upgradable" ]]; then
        echo "Upgradable apt packages (cached):"
        cat "$_pkg_cache_dir/apt-upgradable"
    else
        echo "No cached data. Running apt list --upgradable..."
        apt list --upgradable 2>/dev/null
    fi
}

# ================================
# Shell startup
# ================================

if [[ -o interactive ]]; then
    # Fast dotfiles sync check (immediate)
    _pkg_check_dotfiles_sync

    # Start background upstream check if cache expired
    if _pkg_cache_expired; then
        _pkg_check_upstream_background
    fi

    # Add precmd hook for showing background results
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _pkg_precmd_hook
fi
