# pkgmux doctor — periodic background health check
#
# Flow:
#   1. _pkgmux_doctor_schedule runs at shell startup
#   2. If the timestamp is stale (> 24h), it launches `pkgmux doctor --json`
#      in the background and registers _pkgmux_doctor_display as a precmd hook
#   3. _pkgmux_doctor_display fires before each prompt, waiting for the
#      background job to finish (output file exists and is non-empty)
#   4. Once results are ready, it formats and displays problems, then unhooks

autoload -Uz add-zsh-hook

_pkgmux_cache_dir="${HOME}/.cache/pkgmux"
_pkgmux_output_file="${_pkgmux_cache_dir}/doctor-output"
_pkgmux_timestamp_file="${_pkgmux_cache_dir}/last-doctor"
_pkgmux_interval=$((24 * 60 * 60))  # 24 hours

# --- precmd hook: format and display doctor results (one-shot) ---
_pkgmux_doctor_display() {
    if [[ -f "$_pkgmux_output_file" && -s "$_pkgmux_output_file" ]]; then
        local problems
        problems=$(jq -r '
            .apps[] | select(
                (.installed == false and .skipped == false) or
                .outdated == true or
                .pinned_drift == true or
                (.missing_requires | length > 0)
            ) |
            if .installed == false then "  \(.name): not installed"
            elif .pinned_drift == true then "  \(.name): pinned \(.pinned_version), installed \(.version)"
            elif (.missing_requires | length > 0) then "  \(.name): missing requires: \(.missing_requires | join(", "))"
            elif .outdated == true then "  \(.name): \(.version) -> \(.latest_version)"
            else empty end
        ' "$_pkgmux_output_file" 2>/dev/null)

        if [[ -n "$problems" ]]; then
            echo ""
            print -P "%F{yellow}%B💊 Report from pkgmux doctor%b%f"
            echo "$problems"
        fi

        add-zsh-hook -d precmd _pkgmux_doctor_display
    fi
}

# --- Entrypoint: check staleness and kick off background doctor run ---
_pkgmux_doctor_schedule() {
    # Skip if pkgmux is not available
    command -v pkgmux &>/dev/null || return

    mkdir -p "$_pkgmux_cache_dir"

    # Check if a new run is needed
    if [[ -f "$_pkgmux_timestamp_file" ]]; then
        local last_run
        last_run=$(cat "$_pkgmux_timestamp_file")
        if (( EPOCHSECONDS - last_run < _pkgmux_interval )); then
            return
        fi
    fi

    # Update timestamp immediately to prevent concurrent runs
    echo "$EPOCHSECONDS" > "$_pkgmux_timestamp_file"

    # Remove stale output so precmd doesn't show old results
    rm -f "$_pkgmux_output_file"

    # Run doctor in background, save raw JSON output
    {
        pkgmux doctor --json 2>/dev/null > "$_pkgmux_output_file"
    } &!

    # Register the hook to display results in next prompt
    add-zsh-hook precmd _pkgmux_doctor_display
}

_pkgmux_doctor_schedule
