#!/usr/bin/env bash
# apt handler

_apt_is_installed() {
    local install_entry="$1"
    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')
    dpkg -s "$pkg" &>/dev/null
}

handler_apt_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _apt_is_installed "$install_entry"; then
        local version
        version=$(handler_apt_current_version "$app_name" "$install_entry")
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

    log_info "$app_name: installing via apt..."
    if sudo apt-get install -y "$pkg"; then
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

    log_info "$app_name: upgrading via apt..."
    if sudo apt-get install -y --only-upgrade "$pkg"; then
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
    if sudo apt-get remove -y "$pkg"; then
        log_ok "$app_name: uninstalled"
    else
        log_error "$app_name: uninstall failed"
        return 1
    fi
}

handler_apt_current_version() {
    local app_name="$1"
    local install_entry="$2"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')

    dpkg -s "$pkg" 2>/dev/null | grep '^Version:' | awk '{print $2}'
}
