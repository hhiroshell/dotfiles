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
            elif [[ -z "$cl_pane" && "$cmd" == "claude" ]]; then
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
        if [[ -z "$hx_pane" && "$cur_cmd" != "claude" ]]; then
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
        tmux send-keys -t "$hx_pane" C-u "hx ." C-m
    fi

    local cl_cmd=$(tmux display-message -t "$cl_pane" -p "#{pane_current_command}")
    if [[ "$cl_cmd" != "claude" ]]; then
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
}

# Reload all buffers in a Helix pane within the current tmux session.
# Silently does nothing if not in tmux or no HELIX_PANE is found.
hx-reload() {
    [[ -z "$TMUX" ]] && return 0

    local hx_pane
    hx_pane=$(tmux list-panes -s -F "#{pane_id} #{pane_title}" \
        | awk '/HELIX_PANE/ {print $1; exit}')

    [[ -z "$hx_pane" ]] && return 0

    tmux send-keys -t "$hx_pane" Escape ":rla" Enter
}
