#!/usr/bin/env bash
# mise handler - exact version pinning via mise (https://mise.jdx.dev/)

# Get the tool name / backend spec (aqua:..., ubi:..., pipx:...) from the entry
_mise_get_tool() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.tool // empty'
}

# Resolve the pinned version, if any.
# Precedence: install-entry `pinned_version` field > PKGMUX_PINNED_VERSION env
# var (the hook the future profile pin-layer drives) > none (track latest).
_mise_get_pinned_version() {
    local install_entry="$1"
    local pinned
    pinned=$(echo "$install_entry" | jq -r '.pinned_version // empty')
    if [[ -z "$pinned" ]]; then
        pinned="${PKGMUX_PINNED_VERSION:-}"
    fi
    echo "$pinned"
}

# Resolve the mise ref to install/use: <tool>@<pin> when pinned, else <tool>@latest
_mise_resolve_ref() {
    local install_entry="$1"
    local tool pinned
    tool=$(_mise_get_tool "$install_entry")
    pinned=$(_mise_get_pinned_version "$install_entry")
    if [[ -n "$pinned" ]]; then
        echo "${tool}@${pinned}"
    else
        echo "${tool}@latest"
    fi
}

_mise_is_installed() {
    local tool="$1"
    # `mise current <tool>` prints the active version to stdout (empty when the
    # tool has no global version set); the "no version set" warning goes to stderr.
    [[ -n "$(mise current "$tool" 2>/dev/null)" ]]
}

handler_mise_status() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    if _mise_is_installed "$tool"; then
        local version
        version=$(handler_mise_current_version "$app_name" "$install_entry" "$app_json")
        log_ok "$app_name: installed ($version)"
        return 0
    else
        log_error "$app_name: not installed"
        return 1
    fi
}

handler_mise_install() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    if [[ -z "$tool" ]]; then
        log_error "$app_name: no tool specified for mise handler"
        return 1
    fi

    if _mise_is_installed "$tool"; then
        log_ok "$app_name: already installed"
        return 0
    fi

    local ref
    ref=$(_mise_resolve_ref "$install_entry")

    log_info "$app_name: installing via mise ($ref)..."
    if mise use -g "$ref"; then
        log_ok "$app_name: installed"
    else
        log_error "$app_name: installation failed"
        return 1
    fi
}

handler_mise_upgrade() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    if ! _mise_is_installed "$tool"; then
        log_warn "$app_name: not installed, installing..."
        handler_mise_install "$app_name" "$install_entry" "$app_json"
        return $?
    fi

    local current_version
    current_version=$(handler_mise_current_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true

    # Pinning guard: hold at the pinned version, advancing only if drifted
    local pinned_version
    pinned_version=$(_mise_get_pinned_version "$install_entry")
    if [[ -n "$pinned_version" ]]; then
        if [[ -n "$current_version" && "$current_version" != "installed, version unknown" && "$current_version" == "$pinned_version" ]]; then
            log_ok "$app_name: already at pinned version ($pinned_version)"
            return 0
        fi
        log_info "$app_name: pinned to $pinned_version, updating..."
        if mise use -g "${tool}@${pinned_version}"; then
            log_ok "$app_name: set to pinned version ($pinned_version)"
        else
            log_error "$app_name: upgrade failed"
            return 1
        fi
        return 0
    fi

    # Unpinned: advance to latest when behind
    local latest_version
    latest_version=$(handler_mise_latest_version "$app_name" "$install_entry" "$app_json" 2>/dev/null) || true
    if [[ -n "$current_version" && "$current_version" != "installed, version unknown" && -n "$latest_version" && "$current_version" == "$latest_version" ]]; then
        log_ok "$app_name: already up to date ($current_version)"
        return 0
    fi

    log_info "$app_name: upgrading via mise..."
    if mise use -g "${tool}@latest"; then
        log_ok "$app_name: upgraded"
    else
        log_error "$app_name: upgrade failed"
        return 1
    fi
}

handler_mise_uninstall() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    if ! _mise_is_installed "$tool"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    log_info "$app_name: removing via mise..."
    # Drop it from the global config, then remove every installed version
    # (--all avoids the "multiple versions" ambiguity when more than one exists).
    if mise use -g --rm "$tool" && mise uninstall --all "$tool"; then
        log_ok "$app_name: uninstalled"
    else
        log_error "$app_name: uninstall failed"
        return 1
    fi
}

handler_mise_latest_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    # `mise latest <tool>` prints the bare newest version (empty on failure,
    # which doctor treats as "cannot check", same as go/custom).
    mise latest "$tool" 2>/dev/null || true
}

handler_mise_outdated() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    if ! _mise_is_installed "$tool"; then
        log_skip "$app_name: not installed"
        return 0
    fi

    local current_version
    current_version=$(handler_mise_current_version "$app_name" "$install_entry" "$app_json")

    if [[ -z "$current_version" || "$current_version" == "installed, version unknown" ]]; then
        log_warn "$app_name: cannot check (no version info)"
        return 0
    fi

    local latest_version
    latest_version=$(handler_mise_latest_version "$app_name" "$install_entry" "$app_json")

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

handler_mise_current_version() {
    local app_name="$1"
    local install_entry="$2"
    local app_json="$3"

    local tool
    tool=$(_mise_get_tool "$install_entry")

    local ver
    ver=$(mise current "$tool" 2>/dev/null)
    echo "${ver:-installed, version unknown}"
}
