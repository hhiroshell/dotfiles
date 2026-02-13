#!/usr/bin/env bash
# go install handler

# Extract binary name from package path
_go_get_binary_name() {
    local pkg="$1"
    # Remove @version suffix and strip major version path (e.g. /v2, /v3)
    local path="${pkg%%@*}"
    path=$(echo "$path" | sed 's|/v[0-9]\+$||')
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

    if ! _go_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_warn "$app_name: not installed, installing..."
        handler_go_install "$app_name" "$install_entry" "$app_json"
        return $?
    fi

    local current_version latest_version
    current_version=$(handler_go_current_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true
    latest_version=$(handler_go_latest_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true
    if [[ -n "$current_version" && "$current_version" != "installed, version unknown" && -n "$latest_version" && "$current_version" == "$latest_version" ]]; then
        log_ok "$app_name: already up to date ($current_version)"
        return 0
    fi

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

handler_go_latest_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local binary
    binary=$(_go_get_binary "$app_name" "$install_entry" "$app_json")
    local gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"

    if [[ ! -x "$gobin/$binary" ]]; then
        return 0
    fi

    local module_path
    module_path=$(go version -m "$gobin/$binary" 2>/dev/null | awk '/^\tmod\t/{print $2}')

    if [[ -z "$module_path" ]]; then
        return 0
    fi

    # Go module proxy requires case-encoding: uppercase letters become '!' + lowercase
    local encoded_path
    encoded_path=$(echo "$module_path" | sed 's/[A-Z]/!&/g' | tr '[:upper:]' '[:lower:]')

    curl -sS --max-time 10 "https://proxy.golang.org/${encoded_path}/@latest" 2>/dev/null | jq -r '.Version // empty'
}

handler_go_outdated() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    if ! _go_is_installed "$app_name" "$install_entry" "$app_json"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    local current_version
    current_version=$(handler_go_current_version "$app_name" "$install_entry" "$app_json")

    if [[ -z "$current_version" || "$current_version" == "installed, version unknown" ]]; then
        log_warn "$app_name: cannot check (no version info)"
        return 0
    fi

    local latest_version
    latest_version=$(handler_go_latest_version "$app_name" "$install_entry" "$app_json")

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

handler_go_current_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local binary
    binary=$(_go_get_binary "$app_name" "$install_entry" "$app_json")
    local gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"

    if [[ -x "$gobin/$binary" ]]; then
        local ver
        ver=$(go version -m "$gobin/$binary" 2>/dev/null | awk '/^\tmod\t/{print $3}')
        echo "${ver:-installed, version unknown}"
    fi
}
