#!/usr/bin/env bash
# Select the appropriate install entry for current OS

# Select install entry matching current OS
# Returns JSON of the selected install entry, or empty if none match
select_install_entry() {
    local app_json="$1"
    local current_os="$PKGMUX_OS"

    # Get install array and find matching entry
    echo "$app_json" | jq -c --arg os "$current_os" '
        .install[] | select(
            .os == $os or
            .os == null or
            (type == "object" and .os | type == "array" and any(. == $os))
        )
    ' | head -n 1
}

# Get handler type from install entry
get_handler_type() {
    local install_entry="$1"
    echo "$install_entry" | jq -r '.type // empty'
}

# Check if an install entry matches current OS
matches_os() {
    local install_entry="$1"
    local current_os="$PKGMUX_OS"

    local os_field
    os_field=$(echo "$install_entry" | jq -r '.os // empty')

    # No OS specified means all OS
    [[ -z "$os_field" ]] && return 0

    # Check if it's an array or string
    if echo "$install_entry" | jq -e '.os | type == "array"' &>/dev/null; then
        echo "$install_entry" | jq -e --arg os "$current_os" '.os | any(. == $os)' &>/dev/null
    else
        [[ "$os_field" == "$current_os" ]]
    fi
}
