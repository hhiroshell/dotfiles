#!/usr/bin/env bash
# Homebrew handler (formulas + casks)

# Get package name from install entry (supports both 'package' and 'cask')
_brew_get_package() {
    local install_entry="$1"
    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package // empty')
    if [[ -z "$pkg" ]]; then
        pkg=$(echo "$install_entry" | jq -r '.cask // empty')
    fi
    echo "$pkg"
}

# Check if this is a cask
_brew_is_cask() {
    local install_entry="$1"
    echo "$install_entry" | jq -e '.cask != null' &>/dev/null
}

_brew_is_installed() {
    local install_entry="$1"
    local pkg
    pkg=$(_brew_get_package "$install_entry")

    if _brew_is_cask "$install_entry"; then
        brew list --cask "$pkg" &>/dev/null
    else
        brew list "$pkg" &>/dev/null
    fi
}

handler_brew_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _brew_is_installed "$install_entry"; then
        local version
        version=$(handler_brew_current_version "$app_name" "$install_entry")
        log_ok "$app_name: installed ($version)"
        return 0
    else
        log_error "$app_name: not installed"
        return 1
    fi
}

handler_brew_install() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(_brew_get_package "$install_entry")

    if _brew_is_installed "$install_entry"; then
        log_ok "$app_name: already installed"
        return 0
    fi

    log_info "$app_name: installing via brew..."
    if _brew_is_cask "$install_entry"; then
        if brew install --cask "$pkg"; then
            log_ok "$app_name: installed"
        else
            log_error "$app_name: installation failed"
            return 1
        fi
    else
        if brew install "$pkg"; then
            log_ok "$app_name: installed"
        else
            log_error "$app_name: installation failed"
            return 1
        fi
    fi
}

handler_brew_upgrade() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(_brew_get_package "$install_entry")

    if ! _brew_is_installed "$install_entry"; then
        log_warn "$app_name: not installed, installing..."
        handler_brew_install "$app_name" "$install_entry" "$app_json"
        return $?
    fi

    log_info "$app_name: upgrading via brew..."
    if _brew_is_cask "$install_entry"; then
        if brew upgrade --cask "$pkg" 2>/dev/null; then
            log_ok "$app_name: upgraded"
        else
            log_ok "$app_name: already up to date"
        fi
    else
        if brew upgrade "$pkg" 2>/dev/null; then
            log_ok "$app_name: upgraded"
        else
            log_ok "$app_name: already up to date"
        fi
    fi
}

handler_brew_uninstall() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(_brew_get_package "$install_entry")

    if ! _brew_is_installed "$install_entry"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    log_info "$app_name: uninstalling via brew..."
    if _brew_is_cask "$install_entry"; then
        if brew uninstall --cask "$pkg"; then
            log_ok "$app_name: uninstalled"
        else
            log_error "$app_name: uninstall failed"
            return 1
        fi
    else
        if brew uninstall "$pkg"; then
            log_ok "$app_name: uninstalled"
        else
            log_error "$app_name: uninstall failed"
            return 1
        fi
    fi
}

handler_brew_current_version() {
    local app_name="$1"
    local install_entry="$2"

    local pkg
    pkg=$(_brew_get_package "$install_entry")

    if _brew_is_cask "$install_entry"; then
        brew list --cask --versions "$pkg" 2>/dev/null | awk '{print $2}'
    else
        brew list --versions "$pkg" 2>/dev/null | awk '{print $2}'
    fi
}
