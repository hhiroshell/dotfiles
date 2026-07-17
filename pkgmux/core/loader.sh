#!/usr/bin/env bash
# YAML loading via yq → JSON

# Load an app definition file and output as JSON
load_app() {
    local app_name="$1"
    local apps_dir="$2"
    local app_file="${apps_dir}/${app_name}.yaml"

    if [[ ! -f "$app_file" ]]; then
        log_error "App definition not found: $app_file"
        return 1
    fi

    yq -o=json "$app_file"
}

# Check if an app is disabled
is_disabled() {
    local app_json="$1"
    [[ $(echo "$app_json" | jq -r '.disabled // false') == "true" ]]
}

# Check if an app applies to the current profile (PKGMUX_PROFILE)
in_profile() {
    local app_json="$1"

    # No profiles field (or null) => universal (applies everywhere)
    if ! echo "$app_json" | jq -e '(.profiles // null) != null' &>/dev/null; then
        return 0
    fi

    # No active profile => filter inert (backward compatible)
    [[ -z "${PKGMUX_PROFILE:-}" ]] && return 0

    # Applies if the active profile is in the list. Normalize a bare string to
    # a single-element array, mirroring matches_os in selector.sh.
    echo "$app_json" | jq -e --arg p "$PKGMUX_PROFILE" \
        '(.profiles | if type == "array" then . else [.] end) | any(. == $p)' &>/dev/null
}

# List all available app names
list_apps() {
    local apps_dir="$1"

    if [[ ! -d "$apps_dir" ]]; then
        log_error "Apps directory not found: $apps_dir"
        return 1
    fi

    find "$apps_dir" -name "*.yaml" -type f | while read -r file; do
        basename "$file" .yaml
    done | sort
}
