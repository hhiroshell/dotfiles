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

    # A single jq -e collapses the three checks into one subprocess:
    #   - profiles absent/null => universal (applies everywhere)
    #   - no active profile    => filter inert (backward compatible)
    #   - otherwise            => active profile must be in the list
    # Uses `has("profiles") and .profiles != null` rather than `.profiles // null`
    # so a YAML-coerced falsy value (e.g. `profiles: no`) fails closed to the
    # membership test instead of being treated as absent. Normalizes a bare
    # string to a single-element array, mirroring matches_os in selector.sh.
    echo "$app_json" | jq -e --arg p "${PKGMUX_PROFILE:-}" '
        if (has("profiles") | not) or .profiles == null or $p == "" then
            true
        else
            (.profiles | if type == "array" then . else [.] end) | any(. == $p)
        end
    ' &>/dev/null
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
