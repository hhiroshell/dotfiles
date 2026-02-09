#!/usr/bin/env bash
# Custom script handler

# Get command to check if app is installed
_custom_get_check_cmd() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.check // empty'
}

# Get the install script
_custom_get_script() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.script // empty'
}

# Get the uninstall script
_custom_get_uninstall_script() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.uninstall // empty'
}

_custom_is_installed() {
    local app_name="$1"
    local install_entry="$2"

    local check_cmd
    check_cmd=$(_custom_get_check_cmd "$install_entry")

    if [[ -n "$check_cmd" ]]; then
        eval "$check_cmd" &>/dev/null
    else
        # Default: check if app_name command exists
        command_exists "$app_name"
    fi
}

handler_custom_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _custom_is_installed "$app_name" "$install_entry"; then
        local version
        version=$(handler_custom_current_version "$app_name" "$install_entry")
        log_ok "$app_name: installed ($version)"
        return 0
    else
        log_error "$app_name: not installed"
        return 1
    fi
}

handler_custom_install() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _custom_is_installed "$app_name" "$install_entry"; then
        log_ok "$app_name: already installed"
        return 0
    fi

    local script
    script=$(_custom_get_script "$install_entry")

    if [[ -z "$script" ]]; then
        log_error "$app_name: no install script defined"
        return 1
    fi

    log_info "$app_name: running custom install script..."
    if eval "$script"; then
        log_ok "$app_name: installed"
    else
        log_error "$app_name: installation failed"
        return 1
    fi
}

handler_custom_upgrade() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    # For custom scripts, upgrade is typically just re-running install
    local script
    script=$(_custom_get_script "$install_entry")

    if [[ -z "$script" ]]; then
        log_error "$app_name: no install script defined"
        return 1
    fi

    log_info "$app_name: running custom upgrade (reinstall)..."
    if eval "$script"; then
        log_ok "$app_name: upgraded"
    else
        log_error "$app_name: upgrade failed"
        return 1
    fi
}

handler_custom_uninstall() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if ! _custom_is_installed "$app_name" "$install_entry"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    local uninstall_script
    uninstall_script=$(_custom_get_uninstall_script "$install_entry")

    if [[ -z "$uninstall_script" ]]; then
        log_warn "$app_name: no uninstall script defined, skipping"
        return 0
    fi

    log_info "$app_name: running custom uninstall script..."
    if eval "$uninstall_script"; then
        log_ok "$app_name: uninstalled"
    else
        log_error "$app_name: uninstall failed"
        return 1
    fi
}

handler_custom_current_version() {
    local app_name="$1"
    local install_entry="$2"

    # Try common version flags
    if command_exists "$app_name"; then
        "$app_name" --version 2>/dev/null | head -1 || \
        "$app_name" -v 2>/dev/null | head -1 || \
        "$app_name" version 2>/dev/null | head -1 || \
        echo "installed"
    fi
}
