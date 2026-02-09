#!/usr/bin/env bash
# Version policy logic

# Get version policy from app definition
# Returns: "latest" or "pinned"
get_version_policy() {
    local app_json="$1"
    echo "$app_json" | jq -r '.version.policy // "latest"'
}

# Get pinned version value
get_pinned_version() {
    local app_json="$1"
    echo "$app_json" | jq -r '.version.value // empty'
}

# Check if installed version matches policy
# Returns 0 if ok, 1 if version drift detected
check_version() {
    local app_name="$1"
    local app_json="$2"
    local installed_version="$3"

    local policy
    policy=$(get_version_policy "$app_json")

    if [[ "$policy" == "pinned" ]]; then
        local pinned_version
        pinned_version=$(get_pinned_version "$app_json")

        if [[ -n "$pinned_version" && "$installed_version" != "$pinned_version" ]]; then
            log_warn "$app_name: version drift (installed: $installed_version, pinned: $pinned_version)"
            return 1
        fi
    fi

    return 0
}
