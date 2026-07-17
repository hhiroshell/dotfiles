#!/usr/bin/env bash
# Machine profile (environment) detection
#
# Resolves PKGMUX_PROFILE with the following precedence (first match wins):
#   1. PKGMUX_PROFILE env var, if already set and non-empty (explicit override)
#   2. Marker file ${XDG_CONFIG_HOME:-$HOME/.config}/pkgmux/profile
#      (first whitespace-delimited token of the first non-empty line)
#   3. Empty string (no profile; universal apps only, no profile pins)

detect_profile() {
    # 1. Explicit env var override wins if set and non-empty
    if [[ -n "${PKGMUX_PROFILE:-}" ]]; then
        echo "$PKGMUX_PROFILE"
        return
    fi

    # 2. Marker file (per-machine, not managed by git).
    #    Parsed with bash builtins (no subprocess) so an unreadable or
    #    vanishing file degrades to the empty default instead of aborting the
    #    caller under `set -e`. CRLF endings are tolerated.
    local marker="${XDG_CONFIG_HOME:-$HOME/.config}/pkgmux/profile"
    if [[ -r "$marker" ]]; then
        local first _rest
        while read -r first _rest || [[ -n "$first" ]]; do
            first="${first%$'\r'}"      # tolerate CRLF line endings
            if [[ -z "$first" ]]; then
                continue                # skip blank lines
            fi
            printf '%s\n' "$first"      # first token of first non-empty line
            return
        done < "$marker"
    fi

    # 3. Safe default: no profile (universal apps only, no profile pins)
    echo ""
}

# Export for use in other scripts.
# Note: detect_profile honors any pre-set PKGMUX_PROFILE as an override, so
# re-assigning the same variable here is intentional and idempotent.
PKGMUX_PROFILE="$(detect_profile)"

# Validate at this single trust boundary: PKGMUX_PROFILE (from the environment
# or the marker file) is later used to select apps and version pins, so restrict
# it to a safe charset to avoid path traversal / injection in consumers.
if [[ -n "$PKGMUX_PROFILE" && ! "$PKGMUX_PROFILE" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "pkgmux: ignoring invalid PKGMUX_PROFILE value: '$PKGMUX_PROFILE'" >&2
    PKGMUX_PROFILE=""
fi

export PKGMUX_PROFILE
