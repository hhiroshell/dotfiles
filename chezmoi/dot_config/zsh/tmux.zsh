# Organize tmux panes into a two-pane IDE layout:
#   Left: Helix editor (2/3 width on wide terminals)
#   Right: Claude Code (1/3 width on wide terminals)
#
# Uses a phased approach to handle any starting state robustly:
#   1. Find panes by title (HELIX_PANE / CLAUDE_PANE)
#   2. Detect untitled panes by running command (hx / claude)
#   3. Reuse the caller's pane for an unassigned role
#   4. Create any still-missing panes via split
#   5. Launch apps, clean up extras, arrange layout
ide() {
    if [[ -z "$TMUX" ]]; then
        echo "ide: not inside a tmux session" >&2
        return 1
    fi

    local threshold=256
    local window_id=$(tmux display-message -p "#{window_id}")
    local current_pane=$(tmux display-message -p "#{pane_id}")
    local hx_pane cl_pane p

    # On macOS, 'claude' is a symlink to a versioned binary (e.g., "2.1.76"), so
    # tmux's pane_current_command returns the target's basename, not "claude".
    # Resolve the real name so all comparisons work on both macOS and Linux.
    local claude_bin
    claude_bin=$(basename "$(readlink "$(command -v claude)" 2>/dev/null)" 2>/dev/null)
    [[ -z "$claude_bin" ]] && claude_bin="claude"

    # --- Phase 1: Find panes by title ---
    hx_pane=$(tmux list-panes -t "$window_id" -F "#{pane_id} #{pane_title}" \
        | awk '/HELIX_PANE/ {print $1; exit}')
    cl_pane=$(tmux list-panes -t "$window_id" -F "#{pane_id} #{pane_title}" \
        | awk '/CLAUDE_PANE/ {print $1; exit}')

    # --- Phase 2: Detect untitled panes by running command ---
    if [[ -z "$hx_pane" || -z "$cl_pane" ]]; then
        local cmd
        for p in $(tmux list-panes -t "$window_id" -F "#{pane_id}"); do
            [[ "$p" == "$hx_pane" || "$p" == "$cl_pane" ]] && continue
            cmd=$(tmux display-message -t "$p" -p "#{pane_current_command}")
            if [[ -z "$hx_pane" && "$cmd" == "hx" ]]; then
                hx_pane="$p"
                tmux select-pane -t "$hx_pane" -T "HELIX_PANE"
            elif [[ -z "$cl_pane" && "$cmd" == "$claude_bin" ]]; then
                cl_pane="$p"
                tmux select-pane -t "$cl_pane" -T "CLAUDE_PANE"
            fi
        done
    fi

    # --- Phase 3: Reuse the caller's pane for an unassigned role ---
    # Prefer helix — the caller likely typed "ide" in a shell they want
    # replaced with an editor.  Never assign a pane already running the
    # other program.
    if [[ "$current_pane" != "$hx_pane" && "$current_pane" != "$cl_pane" ]]; then
        local cur_cmd=$(tmux display-message -t "$current_pane" -p "#{pane_current_command}")
        if [[ -z "$hx_pane" && "$cur_cmd" != "$claude_bin" ]]; then
            hx_pane="$current_pane"
            tmux select-pane -t "$hx_pane" -T "HELIX_PANE"
        elif [[ -z "$cl_pane" && "$cur_cmd" != "hx" ]]; then
            cl_pane="$current_pane"
            tmux select-pane -t "$cl_pane" -T "CLAUDE_PANE"
        fi
    fi

    # --- Phase 4: Create any still-missing panes ---
    if [[ -z "$hx_pane" ]]; then
        local split_target="${cl_pane:-$current_pane}"
        hx_pane=$(tmux split-window -hb -t "$split_target" -P -F "#{pane_id}" \
            -c "#{pane_current_path}")
        tmux select-pane -t "$hx_pane" -T "HELIX_PANE"
    fi

    if [[ -z "$cl_pane" ]]; then
        cl_pane=$(tmux split-window -h -t "$hx_pane" -P -F "#{pane_id}" \
            -c "#{pane_current_path}")
        tmux select-pane -t "$cl_pane" -T "CLAUDE_PANE"
    fi

    # --- Phase 5: Launch apps if not already running ---
    local hx_cmd=$(tmux display-message -t "$hx_pane" -p "#{pane_current_command}")
    if [[ "$hx_cmd" != "hx" ]]; then
        tmux send-keys -t "$hx_pane" C-u "hx README.md" C-m
    fi

    local cl_cmd=$(tmux display-message -t "$cl_pane" -p "#{pane_current_command}")
    if [[ "$cl_cmd" != "$claude_bin" ]]; then
        tmux send-keys -t "$cl_pane" C-u "claude" C-m
    fi

    # --- Phase 6: Kill extra panes ---
    for p in $(tmux list-panes -t "$window_id" -F "#{pane_id}"); do
        if [[ "$p" != "$hx_pane" && "$p" != "$cl_pane" ]]; then
            tmux kill-pane -t "$p"
        fi
    done

    # --- Phase 7: Arrange layout (Helix left, Claude right) ---
    local hx_left=$(tmux display-message -t "$hx_pane" -p "#{pane_left}")
    local cl_left=$(tmux display-message -t "$cl_pane" -p "#{pane_left}")
    if [[ "$hx_left" -gt "$cl_left" ]]; then
        tmux swap-pane -s "$hx_pane" -t "$cl_pane"
    fi

    tmux select-layout -t "$window_id" even-horizontal
    local width=$(tmux display-message -p "#{window_width}")
    if [[ "$width" -ge "$threshold" ]]; then
        tmux resize-pane -t "$hx_pane" -x $(( width * 2 / 3 ))
    fi

    tmux select-pane -t "$hx_pane"
}

# Keep the tmux window running a Claude Code session named
# "<repo>: <claude-session-name>" so the window/status bar reflects which
# conversation is running. Intended to run as a Claude Code hook (SessionStart
# / Stop), which passes session_id/cwd as a JSON payload on stdin.
#
# The session's live title (auto-slug, or whatever /rename set) and its exact
# tmux target live in ~/.claude/sessions/<pid>.json — NOT in
# sessions-index.json, which on this machine is only rewritten sporadically and
# has no entry at all for a session that's still running. Matching by tmux
# target (rather than trusting $TMUX in the hook's own environment) also means
# this works correctly even if the hook subprocess's env differs from the pane
# that's actually running Claude.
#
# Renaming directly from the hook does NOT work reliably: Claude Code writes
# the name asynchronously and at moments no hook observes. At SessionStart it
# is still a placeholder ("<repo>-<n>"), the derived name lands around or after
# the first Stop, and /rename fires no hook at all — so a one-shot rename shows
# a stale name most of the time. The hook therefore only starts a watcher that
# polls the session file for as long as the Claude process lives.
sync-tmux-window-name() {
    command -v tmux >/dev/null 2>&1 || return 0

    local input session_id
    input=$(cat)
    session_id=$(echo "$input" | jq -r '.session_id // empty')
    [[ -z "$session_id" ]] && return 0

    # Newest first: a dead session leaves its file behind, and a resumed
    # session reuses the same sessionId under a new pid. Taking any match
    # would rename whatever window the *old* run happened to occupy.
    local session_file f
    for f in ~/.claude/sessions/*.json(Nom); do
        if [[ "$(jq -r '.sessionId // empty' "$f" 2>/dev/null)" == "$session_id" ]]; then
            # A file whose pid is still alive is the running session; anything
            # else is a leftover. Keep the newest match as a fallback.
            if kill -0 "${f:t:r}" 2>/dev/null; then
                session_file="$f"
                break
            fi
            [[ -z "$session_file" ]] && session_file="$f"
        fi
    done
    [[ -z "$session_file" ]] && return 0

    # No tmux target means this session isn't running under tmux. Bail out
    # before touching tmux at all, so a non-tmux session never spawns a server.
    [[ -n "$(jq -r '.tmux // empty' "$session_file" 2>/dev/null)" ]] || return 0

    # The filename stem is the pid. Insist on digits: it is interpolated into
    # the `zsh -c` string below, so a name like `1'; rm -rf ~; '.json` in that
    # directory would be shell code rather than an argument.
    local claude_pid="${session_file:t:r}"
    [[ "$claude_pid" == <-> ]] || return 0

    _sync-tmux-window-name-locked "$claude_pid" && return 0

    # Start via `tmux run-shell -b` so the watcher is a child of the tmux
    # server, not of this hook: Claude Code may reap the hook's process tree
    # once the hook returns, which would kill a plain background job. As a
    # bonus the watcher goes away with the tmux server.
    tmux run-shell -b \
        "zsh -c 'source ~/.config/zsh/tmux.zsh && _sync-tmux-window-name-watch ${claude_pid}'"
}

# Path of the watcher's lock for a Claude pid. The hook and the watcher must
# agree on it byte for byte or the single-watcher guard silently stops working,
# so it is derived in exactly one place.
_sync-tmux-window-name-lock() {
    print -r -- "${TMPDIR:-/tmp}/cc-winname-$1.pid"
}

# True while a live watcher already owns the lock for this Claude pid. The
# session file is a second signal on purpose: once it is gone the session has
# ended, so a lock naming it is stale no matter which pid it records. That is
# what stops a recycled watcher pid from making a leftover lock look live and
# wedging the guard for good.
_sync-tmux-window-name-locked() {
    local lock="$(_sync-tmux-window-name-lock "$1")"
    [[ -f "$lock" && -f "$HOME/.claude/sessions/$1.json" ]] || return 1
    kill -0 "$(<"$lock")" 2>/dev/null
}

# Poll one Claude Code session file and keep its tmux window name in sync.
# Exits once the session's process is gone. Started only by
# sync-tmux-window-name; not meant to be run by hand.
_sync-tmux-window-name-watch() {
    local claude_pid="$1"
    local session_file="$HOME/.claude/sessions/${claude_pid}.json"
    local lock="$(_sync-tmux-window-name-lock "$claude_pid")"

    # Re-check the lock now that we're the process that will hold it. Two
    # hooks racing could still both get here; a duplicate watcher is harmless
    # (both compute the same name) and the loser's lock is cleaned up below.
    _sync-tmux-window-name-locked "$claude_pid" && return 0
    print -r -- $$ >! "$lock"

    local max_len=40
    local name tmux_target window_target cwd last_cwd repo_name desired

    while kill -0 "$claude_pid" 2>/dev/null && [[ -f "$session_file" ]]; do
        # One jq per poll rather than one per field: three invocations would
        # spawn ~1.5 processes/second for the whole session, and could each
        # observe a different mid-write state of the file. A parse failure
        # (file caught half-written) leaves every field empty, so the guard
        # below just waits for the next tick.
        IFS=$'\t' read -r name tmux_target cwd < <(
            jq -r '[.name // "", .tmux // "", .cwd // ""] | @tsv' "$session_file" 2>/dev/null
        )

        # All three are needed to build the name. Requiring cwd here also means
        # last_cwd (initially empty) can never spuriously match it and skip the
        # repo_name lookup, which would rename the window to a bare ": <name>".
        if [[ -n "$name" && -n "$tmux_target" && -n "$cwd" ]]; then
            if [[ "$cwd" != "$last_cwd" ]]; then
                repo_name=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")")
                last_cwd="$cwd"
            fi

            # The name is model-derived and lands in the status line, which
            # interprets escape sequences — drop control characters before it
            # gets there. Strip first so truncation counts visible characters.
            name="${name//[[:cntrl:]]/}"
            (( ${#name} > max_len )) && name="${name[1,$max_len]}…"
            desired="${repo_name}: ${name}"

            # tmux_target is "session:window.pane" — renaming needs "session:window".
            # Compare against the window's actual name rather than the last value
            # we wrote, so a name clobbered by anything else is repaired too.
            window_target="${tmux_target%.*}"
            if [[ "$(tmux display-message -t "$window_target" -p '#{window_name}' 2>/dev/null)" != "$desired" ]]; then
                tmux rename-window -t "$window_target" "$desired" 2>/dev/null
            fi
        fi

        sleep 2
    done

    rm -f "$lock"
}

# Reload all buffers in a Helix pane within the current tmux window.
# Silently does nothing if not in tmux or no HELIX_PANE is found.
hx-reload() {
    [[ -z "$TMUX" ]] && return 0

    local window_id=$(tmux display-message -p "#{window_id}")
    local hx_pane
    hx_pane=$(tmux list-panes -t "$window_id" -F "#{pane_id} #{pane_title}" \
        | awk '/HELIX_PANE/ {print $1; exit}')

    [[ -z "$hx_pane" ]] && return 0

    tmux send-keys -t "$hx_pane" Escape
    sleep 0.05
    tmux send-keys -t "$hx_pane" ":reload-all" Enter
}
