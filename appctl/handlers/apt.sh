#!/usr/bin/env bash
# apt handler

# Get pre_install script from install entry
_apt_get_pre_install() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.pre_install // empty'
}

# Get uninstall script from install entry
_apt_get_uninstall_script() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.uninstall // empty'
}

_apt_is_installed() {
    local install_entry="$1"
    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package' | awk '{print $1}')
    dpkg -s "$pkg" &>/dev/null
}

handler_apt_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _apt_is_installed "$install_entry"; then
        local version
        version=$(handler_apt_current_version "$app_name" "$install_entry" "$app_json")
        log_ok "$app_name: installed ($version)"
        return 0
    else
        log_error "$app_name: not installed"
        return 1
    fi
}

handler_apt_install() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')

    if _apt_is_installed "$install_entry"; then
        log_ok "$app_name: already installed"
        return 0
    fi

    local pre_install
    pre_install=$(_apt_get_pre_install "$install_entry")
    if [[ -n "$pre_install" ]]; then
        log_info "$app_name: running pre_install script..."
        if ! eval "$pre_install"; then
            log_error "$app_name: pre_install script failed"
            return 1
        fi
    fi

    log_info "$app_name: installing via apt..."
    if sudo apt-get install -y $pkg; then
        log_ok "$app_name: installed"
    else
        log_error "$app_name: installation failed"
        return 1
    fi
}

handler_apt_upgrade() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')

    if ! _apt_is_installed "$install_entry"; then
        log_warn "$app_name: not installed, installing..."
        handler_apt_install "$app_name" "$install_entry" "$app_json"
        return $?
    fi

    local pre_install
    pre_install=$(_apt_get_pre_install "$install_entry")
    if [[ -n "$pre_install" ]]; then
        log_info "$app_name: running pre_install script..."
        if ! eval "$pre_install"; then
            log_error "$app_name: pre_install script failed"
            return 1
        fi
    fi

    log_info "$app_name: upgrading via apt..."
    if sudo apt-get install -y --only-upgrade $pkg; then
        log_ok "$app_name: upgraded"
    else
        log_ok "$app_name: already up to date"
    fi
}

handler_apt_uninstall() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')

    if ! _apt_is_installed "$install_entry"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    log_info "$app_name: uninstalling via apt..."
    if sudo apt-get remove -y $pkg; then
        log_ok "$app_name: uninstalled"
    else
        log_error "$app_name: uninstall failed"
        return 1
    fi

    local uninstall_script
    uninstall_script=$(_apt_get_uninstall_script "$install_entry")
    if [[ -n "$uninstall_script" ]]; then
        log_info "$app_name: running cleanup script..."
        eval "$uninstall_script"
    fi
}

handler_apt_latest_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package' | awk '{print $1}')

    apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}'
}

handler_apt_outdated() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if ! _apt_is_installed "$install_entry"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    local current_version
    current_version=$(handler_apt_current_version "$app_name" "$install_entry" "$app_json")

    if [[ -z "$current_version" ]]; then
        log_warn "$app_name: cannot check (no version info)"
        return 0
    fi

    local latest_version
    latest_version=$(handler_apt_latest_version "$app_name" "$install_entry" "$app_json")

    if [[ -z "$latest_version" ]]; then
        log_warn "$app_name: cannot check (failed to query latest version)"
        return 0
    fi

    if [[ "$current_version" != "$latest_version" ]]; then
        log_warn "$app_name: update available (installed: $current_version, latest: $latest_version)"
    else
        log_ok "$app_name: up to date ($current_version)"
    fi
}

handler_apt_current_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package' | awk '{print $1}')

    dpkg -s "$pkg" 2>/dev/null | grep '^Version:' | awk '{print $2}'
}
