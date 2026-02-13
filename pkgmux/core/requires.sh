#!/usr/bin/env bash
# Dependency checking

# Check if all required apps/commands are available
check_requires() {
    local app_json="$1"

    local requires
    requires=$(echo "$app_json" | jq -r '.requires // [] | .[]')

    if [[ -z "$requires" ]]; then
        return 0
    fi

    local missing=()
    for req in $requires; do
        if ! command_exists "$req"; then
            missing+=("$req")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        local app_name
        app_name=$(echo "$app_json" | jq -r '.name')
        log_error "$app_name: missing requirements: ${missing[*]}"
        log_info "Install them first: pkgmux install ${missing[*]}"
        return 1
    fi

    return 0
}

# List all requirements for an app
list_requires() {
    local app_json="$1"
    echo "$app_json" | jq -r '.requires // [] | .[]'
}
