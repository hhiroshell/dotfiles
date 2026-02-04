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
# Background checks
# ================================

# Run all update checks in background
_pkg_check_background() {
    mkdir -p "$_pkg_cache_dir"

    # Try to acquire lock (non-blocking)
    exec 9>"$_pkg_lock_file"
    flock -n 9 || return 0

    (
        local dotfiles_dir
        dotfiles_dir=$(_pkg_dotfiles_dir)

        # Dotfiles sync check (single git fetch for all)
        if [[ -n "$dotfiles_dir" ]]; then
            cd "$dotfiles_dir" || exit 1
            git fetch origin --quiet 2>/dev/null

            # aqua
            local local_rev remote_rev
            local_rev=$(git rev-parse HEAD:home/aqua/aqua.yaml 2>/dev/null)
            remote_rev=$(git rev-parse origin/main:home/aqua/aqua.yaml 2>/dev/null)
            if [[ -n "$local_rev" ]] && [[ -n "$remote_rev" ]] && [[ "$local_rev" != "$remote_rev" ]]; then
                echo "1" > "$_pkg_cache_dir/aqua-sync"
            else
                rm -f "$_pkg_cache_dir/aqua-sync"
            fi

            # brew (macOS only)
            if [[ "$(uname)" == "Darwin" ]]; then
                local_rev=$(git rev-parse HEAD:home/Brewfile 2>/dev/null)
                remote_rev=$(git rev-parse origin/main:home/Brewfile 2>/dev/null)
                if [[ -n "$local_rev" ]] && [[ -n "$remote_rev" ]] && [[ "$local_rev" != "$remote_rev" ]]; then
                    echo "1" > "$_pkg_cache_dir/brew-sync"
                else
                    rm -f "$_pkg_cache_dir/brew-sync"
                fi
            fi

            # apt (Linux only)
            if [[ "$(uname)" == "Linux" ]]; then
                local_rev=$(git rev-parse HEAD:home/apt-packages.txt 2>/dev/null)
                remote_rev=$(git rev-parse origin/main:home/apt-packages.txt 2>/dev/null)
                if [[ -n "$local_rev" ]] && [[ -n "$remote_rev" ]] && [[ "$local_rev" != "$remote_rev" ]]; then
                    echo "1" > "$_pkg_cache_dir/apt-sync"
                else
                    rm -f "$_pkg_cache_dir/apt-sync"
                fi
            fi
        fi

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
_pkg_show_notifications() {
    # Only show once per session
    (( _pkg_notifications_shown )) && return 0

    # Check if results are ready
    [[ ! -f "$_pkg_cache_dir/last-check" ]] && return 0

    # Dotfiles sync notifications (yellow)
    if [[ -f "$_pkg_cache_dir/aqua-sync" ]]; then
        echo "\033[1;33m[aqua] Updates available. Run 'aqua-pull' to apply.\033[0m"
    fi

    if [[ -f "$_pkg_cache_dir/brew-sync" ]]; then
        echo "\033[1;33m[brew] Brewfile changed. Run 'brew-pull' or 'brew-sync' to apply.\033[0m"
    fi

    if [[ -f "$_pkg_cache_dir/apt-sync" ]]; then
        echo "\033[1;33m[apt] Package list changed. Run 'apt-pull' or 'apt-sync' to apply.\033[0m"
    fi

    # Upstream update notifications (cyan)
    if [[ -f "$_pkg_cache_dir/brew-outdated-count" ]]; then
        local count=$(cat "$_pkg_cache_dir/brew-outdated-count")
        if (( count > 0 )); then
            echo "\033[1;36m[brew] $count package(s) outdated. Run 'brew-upgrade' or 'brew-sync' to update.\033[0m"
        fi
    fi

    if [[ -f "$_pkg_cache_dir/apt-upgradable-count" ]]; then
        local count=$(cat "$_pkg_cache_dir/apt-upgradable-count")
        if (( count > 0 )); then
            echo "\033[1;36m[apt] $count package(s) upgradable. Run 'apt-upgrade' or 'apt-sync' to update.\033[0m"
        fi
    fi

    _pkg_notifications_shown=1
}

# precmd hook to show notifications
_pkg_precmd_hook() {
    _pkg_show_notifications
}

# ================================
# Pull commands (dotfiles sync)
# ================================

# aqua pull (sync from dotfiles)
aqua-pull() {
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
            aqua install && \
            rm -f "$_pkg_cache_dir/aqua-sync"
            ;;
        *)
            echo "Skipped"
            ;;
    esac
}

# brew pull (sync from dotfiles)
brew-pull() {
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
            brew bundle install --file="$dotfiles_dir/home/Brewfile" && \
            rm -f "$_pkg_cache_dir/brew-sync"
            ;;
        *)
            echo "Skipped"
            ;;
    esac
}

# apt pull (sync from dotfiles)
apt-pull() {
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
            grep -v '^#' "$dotfiles_dir/home/apt-packages.txt" | grep -v '^$' | xargs sudo apt install -y && \
            rm -f "$_pkg_cache_dir/apt-sync"
            ;;
        *)
            echo "Skipped"
            ;;
    esac
}

# ================================
# Upgrade commands
# ================================

# brew upgrade (clears cache after upgrade)
brew-upgrade() {
    brew upgrade "$@" && rm -f "$_pkg_cache_dir/brew-outdated" "$_pkg_cache_dir/brew-outdated-count"
}

# apt upgrade (clears cache after upgrade)
apt-upgrade() {
    sudo apt upgrade "$@" && rm -f "$_pkg_cache_dir/apt-upgradable" "$_pkg_cache_dir/apt-upgradable-count"
}

# ================================
# Sync commands (pull + upgrade)
# ================================

# brew sync (pull dotfiles + upgrade packages)
brew-sync() {
    brew-pull && brew-upgrade
}

# apt sync (pull dotfiles + upgrade packages)
apt-sync() {
    apt-pull && apt-upgrade
}

# ================================
# Status commands
# ================================

# Show cached outdated brew packages
brew-outdated() {
    if [[ -f "$_pkg_cache_dir/brew-outdated" ]]; then
        echo "Outdated brew packages (cached):"
        cat "$_pkg_cache_dir/brew-outdated"
    else
        echo "No cached data. Running brew outdated..."
        brew outdated
    fi
}

# Show cached upgradable apt packages
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
    # Start background check if cache expired
    if _pkg_cache_expired; then
        _pkg_check_background
    fi

    # Add precmd hook for showing background results
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _pkg_precmd_hook
fi
