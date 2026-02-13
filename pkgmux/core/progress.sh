#!/usr/bin/env bash
# Progress bar utility for pkgmux
# Displays a live progress bar on stderr using \r-based overwriting.
# Suppressed when stderr is not a terminal.

_PROGRESS_ENABLED=false
_PROGRESS_TOTAL=0
_PROGRESS_CURRENT=0
_PROGRESS_LABEL=""

progress_start() {
    local total="$1"
    if [[ "$total" -le 0 ]] || [[ ! -t 2 ]]; then
        return
    fi
    _PROGRESS_TOTAL="$total"
    _PROGRESS_CURRENT=0
    _PROGRESS_LABEL=""
    _PROGRESS_ENABLED=true
    # Hide cursor
    printf '\033[?25l' >&2
    trap '_progress_cleanup' EXIT INT TERM
}

progress_update() {
    $_PROGRESS_ENABLED || return 0
    _PROGRESS_CURRENT="$1"
    _PROGRESS_LABEL="$2"
    _progress_draw
}

progress_clear() {
    $_PROGRESS_ENABLED || return 0
    printf '\r\033[K' >&2
}

progress_done() {
    $_PROGRESS_ENABLED || return 0
    progress_clear
    # Show cursor
    printf '\033[?25h' >&2
    _PROGRESS_ENABLED=false
}

_progress_draw() {
    $_PROGRESS_ENABLED || return 0

    local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
    # Format: [####............] 16/25 checking: label
    local counter="${_PROGRESS_CURRENT}/${_PROGRESS_TOTAL}"
    local suffix="checking: ${_PROGRESS_LABEL}"
    # Overhead: [ ] + space + counter + space + suffix = 4 + len(counter) + len(suffix)
    local overhead=$(( 4 + ${#counter} + ${#suffix} ))
    local bar_width=$(( cols - overhead ))

    if [[ "$bar_width" -lt 10 ]]; then
        # Terminal too narrow for bar, show counter only
        printf '\r\033[K%s %s' "$counter" "$suffix" >&2
        return
    fi

    local filled=$(( bar_width * _PROGRESS_CURRENT / _PROGRESS_TOTAL ))
    local empty=$(( bar_width - filled ))

    local bar_filled=""
    local bar_empty=""
    if [[ "$filled" -gt 0 ]]; then
        bar_filled=$(printf '%*s' "$filled" '' | tr ' ' '#')
    fi
    if [[ "$empty" -gt 0 ]]; then
        bar_empty=$(printf '%*s' "$empty" '' | tr ' ' '.')
    fi

    printf '\r\033[K[%s%s] %s %s' "$bar_filled" "$bar_empty" "$counter" "$suffix" >&2
}

_progress_cleanup() {
    if $_PROGRESS_ENABLED; then
        progress_clear
        printf '\033[?25h' >&2
        _PROGRESS_ENABLED=false
    fi
}
