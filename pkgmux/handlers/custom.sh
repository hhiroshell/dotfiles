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

# Get pinned version from install entry
_custom_get_pinned_version() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.pinned_version // empty'
}

# Get custom version command
_custom_get_version_cmd() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.version_cmd // empty'
}

_custom_is_installed() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local check_cmd
    check_cmd=$(_custom_get_check_cmd "$install_entry")

    if [[ -n "$check_cmd" ]]; then
        eval "$check_cmd" &>/dev/null
    else
        # Default: check if command exists
        local cmd
        cmd=$(get_command "$app_json" "$app_name")
        command_exists "$cmd"
    fi
}

handler_custom_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _custom_is_installed "$app_name" "$install_entry" "$app_json"; then
        local version
        version=$(handler_custom_current_version "$app_name" "$install_entry" "$app_json")
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

    if _custom_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_ok "$app_name: already installed"
        return 0
    fi

    local script
    script=$(_custom_get_script "$install_entry")

    if [[ -z "$script" ]]; then
        log_error "$app_name: no install script defined"
        return 1
    fi

    local pinned_version
    pinned_version=$(_custom_get_pinned_version "$install_entry")
    if [[ -n "$pinned_version" ]]; then
        export PKGMUX_PINNED_VERSION="$pinned_version"
    else
        unset PKGMUX_PINNED_VERSION 2>/dev/null || true
    fi

    log_info "$app_name: running custom install script..."
    if eval "$script"; then
        unset PKGMUX_PINNED_VERSION 2>/dev/null || true
        log_ok "$app_name: installed"
    else
        unset PKGMUX_PINNED_VERSION 2>/dev/null || true
        log_error "$app_name: installation failed"
        return 1
    fi
}

handler_custom_upgrade() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if ! _custom_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_warn "$app_name: not installed, installing..."
        handler_custom_install "$app_name" "$install_entry" "$app_json"
        return $?
    fi

    # Pinning guard
    local pinned_version
    pinned_version=$(_custom_get_pinned_version "$install_entry")
    if [[ -n "$pinned_version" ]]; then
        local current_version
        current_version=$(handler_custom_current_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true
        if [[ -n "$current_version" && "$current_version" != "installed, version unknown" && "$current_version" == "$pinned_version" ]]; then
            log_ok "$app_name: already at pinned version ($pinned_version)"
            return 0
        fi
        log_info "$app_name: pinned to $pinned_version, upgrading..."
    else
        local latest_cmd
        latest_cmd=$(_custom_get_latest_cmd "$install_entry")
        if [[ -n "$latest_cmd" ]]; then
            local current_version latest_version
            current_version=$(handler_custom_current_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true
            latest_version=$(handler_custom_latest_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true
            if [[ -n "$current_version" && "$current_version" != "installed, version unknown" ]]; then
                if [[ -z "$latest_version" ]]; then
                    log_warn "$app_name: cannot determine latest version, skipping upgrade"
                    return 0
                elif [[ "$current_version" == "$latest_version" ]]; then
                    log_ok "$app_name: already up to date ($current_version)"
                    return 0
                fi
            fi
        fi
    fi

    # For custom scripts, upgrade is typically just re-running install
    local script
    script=$(_custom_get_script "$install_entry")

    if [[ -z "$script" ]]; then
        log_error "$app_name: no install script defined"
        return 1
    fi

    if [[ -n "$pinned_version" ]]; then
        export PKGMUX_PINNED_VERSION="$pinned_version"
    else
        unset PKGMUX_PINNED_VERSION 2>/dev/null || true
    fi

    log_info "$app_name: running custom upgrade (reinstall)..."
    if eval "$script"; then
        unset PKGMUX_PINNED_VERSION 2>/dev/null || true
        log_ok "$app_name: upgraded"
    else
        unset PKGMUX_PINNED_VERSION 2>/dev/null || true
        log_error "$app_name: upgrade failed"
        return 1
    fi
}

handler_custom_uninstall() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if ! _custom_is_installed "$app_name" "$install_entry" "$app_json"; then
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

_custom_get_latest_cmd() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.latest_cmd // empty'
}

handler_custom_latest_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local latest_cmd
    latest_cmd=$(_custom_get_latest_cmd "$install_entry")

    if [[ -n "$latest_cmd" ]]; then
        local result
        result=$(eval "$latest_cmd" 2>/dev/null) || true
        # Filter out jq's literal "null" (e.g. from rate-limited GitHub API responses)
        if [[ -n "$result" && "$result" != "null" ]]; then
            echo "$result"
        fi
    fi
}

handler_custom_outdated() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if ! _custom_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    local latest_cmd
    latest_cmd=$(_custom_get_latest_cmd "$install_entry")

    if [[ -z "$latest_cmd" ]]; then
        log_skip "$app_name: cannot check (no latest_cmd defined)"
        return 0
    fi

    local current_version
    current_version=$(handler_custom_current_version "$app_name" "$install_entry" "$app_json")

    if [[ -z "$current_version" || "$current_version" == "installed, version unknown" ]]; then
        log_warn "$app_name: cannot check (no version info)"
        return 0
    fi

    local latest_version
    latest_version=$(handler_custom_latest_version "$app_name" "$install_entry" "$app_json")

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

handler_custom_current_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    # Check for custom version command first
    local version_cmd
    version_cmd=$(_custom_get_version_cmd "$install_entry")

    if [[ -n "$version_cmd" ]]; then
        local ver
        ver=$(eval "$version_cmd" 2>/dev/null)
        echo "${ver:-installed, version unknown}"
        return
    fi

    # Fallback: try common version flags with command name
    local cmd
    cmd=$(get_command "$app_json" "$app_name")
    if command_exists "$cmd"; then
        "$cmd" --version 2>/dev/null | head -1 || \
        "$cmd" version 2>/dev/null | head -1 || \
        echo "installed, version unknown"
    else
        echo "installed, version unknown"
    fi
}
