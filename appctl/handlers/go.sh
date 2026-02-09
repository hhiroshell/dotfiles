#!/usr/bin/env bash
# go install handler

# Extract binary name from package path
_go_get_binary_name() {
    local pkg="$1"
    # Remove @version suffix and get last component
    local path="${pkg%%@*}"
    basename "$path"
}

_go_get_binary() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"
    local cmd
    cmd=$(echo "$app_json" | jq -r '.command // empty')
    if [[ -n "$cmd" ]]; then
        echo "$cmd"
    else
        local pkg
        pkg=$(echo "$install_entry" | jq -r '.package')
        _go_get_binary_name "$pkg"
    fi
}

_go_is_installed() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"
    local binary
    binary=$(_go_get_binary "$app_name" "$install_entry" "$app_json")
    local gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
    [[ -x "$gobin/$binary" ]]
}

handler_go_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if _go_is_installed "$app_name" "$install_entry" "$app_json"; then
        local version
        version=$(handler_go_current_version "$app_name" "$install_entry" "$app_json")
        log_ok "$app_name: installed ($version)"
        return 0
    else
        log_error "$app_name: not installed"
        return 1
    fi
}

handler_go_install() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')

    if _go_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_ok "$app_name: already installed"
        return 0
    fi

    log_info "$app_name: installing via go install..."
    if go install "$pkg"; then
        log_ok "$app_name: installed"
    else
        log_error "$app_name: installation failed"
        return 1
    fi
}

handler_go_upgrade() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local pkg
    pkg=$(echo "$install_entry" | jq -r '.package')

    log_info "$app_name: upgrading via go install..."
    if go install "$pkg"; then
        log_ok "$app_name: upgraded"
    else
        log_error "$app_name: upgrade failed"
        return 1
    fi
}

handler_go_uninstall() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local binary
    binary=$(_go_get_binary "$app_name" "$install_entry" "$app_json")
    local gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"

    if ! _go_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    log_info "$app_name: removing $gobin/$binary..."
    if rm -f "$gobin/$binary"; then
        log_ok "$app_name: uninstalled"
    else
        log_error "$app_name: uninstall failed"
        return 1
    fi
}

handler_go_current_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local binary
    binary=$(_go_get_binary "$app_name" "$install_entry" "$app_json")
    local gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"

    if [[ -x "$gobin/$binary" ]]; then
        "$gobin/$binary" --version 2>/dev/null | head -1 || \
        "$gobin/$binary" version 2>/dev/null | head -1 || \
        echo "installed, version unknown"
    fi
}
