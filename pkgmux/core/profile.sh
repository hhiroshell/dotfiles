#!/usr/bin/env bash
# Machine profile (environment) detection

detect_profile() {
    # 1. Explicit env var override wins if set and non-empty
    if [[ -n "${PKGMUX_PROFILE:-}" ]]; then
        echo "$PKGMUX_PROFILE"
        return
    fi

    # 2. Marker file (per-machine, not managed by git)
    local marker="${XDG_CONFIG_HOME:-$HOME/.config}/pkgmux/profile"
    if [[ -f "$marker" ]]; then
        # First whitespace-delimited token on the first non-empty line
        awk 'NF{print $1; exit}' "$marker"
        return
    fi

    # 3. Safe default: no profile (universal apps only, no profile pins)
    echo ""
}

# Export for use in other scripts
PKGMUX_PROFILE="$(detect_profile)"
export PKGMUX_PROFILE
