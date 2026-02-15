# Organize tmux panes into a two-pane IDE layout:
#   Left: Helix editor (2/3 width on wide terminals)
#   Right: Claude Code (1/3 width on wide terminals)
ide() {
    if [[ -z "$TMUX" ]]; then
        echo "ide: not inside a tmux session" >&2
        return 1
    fi

    local threshold=200
    local window_id=$(tmux display-message -p "#{window_id}")

    # Find existing panes by title in the current window
    local hx_pane=$(tmux list-panes -t "$window_id" -F "#{pane_id} #{pane_title}" \
        | awk '/HELIX_PANE/ {print $1; exit}')
    local cl_pane=$(tmux list-panes -t "$window_id" -F "#{pane_id} #{pane_title}" \
        | awk '/CLAUDE_PANE/ {print $1; exit}')

    # Prepare Helix pane: use current pane if none found
    if [[ -z "$hx_pane" ]]; then
        local candidate=$(tmux display-message -p "#{pane_id}")
        if [[ "$candidate" != "$cl_pane" ]]; then
            # Current pane is not the Claude pane; reuse it as Helix
            hx_pane="$candidate"
        else
            # Current pane is the Claude pane; create a new pane to its left
            hx_pane=$(tmux split-window -hb -t "$cl_pane" -P -F "#{pane_id}" \
                -c "#{pane_current_path}")
        fi
        tmux select-pane -t "$hx_pane" -T "HELIX_PANE"
        # Only launch Helix if not already running in this pane
        local hx_cmd=$(tmux display-message -t "$hx_pane" -p "#{pane_current_command}")
        if [[ "$hx_cmd" != "hx" ]]; then
            tmux send-keys -t "$hx_pane" C-u "hx" C-m
        fi
    fi

    # Prepare Claude pane: use current pane if none found
    if [[ -z "$cl_pane" ]]; then
        local candidate=$(tmux display-message -p "#{pane_id}")
        if [[ "$candidate" != "$hx_pane" ]]; then
            cl_pane="$candidate"
        else
            cl_pane=$(tmux split-window -h -t "$hx_pane" -P -F "#{pane_id}" \
                -c "#{pane_current_path}")
        fi
        tmux select-pane -t "$cl_pane" -T "CLAUDE_PANE"
        # Only launch Claude if not already running in this pane
        local cl_cmd=$(tmux display-message -t "$cl_pane" -p "#{pane_current_command}")
        if [[ "$cl_cmd" != "claude" ]]; then
            tmux send-keys -t "$cl_pane" C-u "claude" C-m
        fi
    fi

    # Kill extra panes in the current window (defer current pane if needed)
    local current_pane=$(tmux display-message -p "#{pane_id}")
    local kill_current=false
    local p
    for p in $(tmux list-panes -t "$window_id" -F "#{pane_id}"); do
        if [[ "$p" != "$hx_pane" && "$p" != "$cl_pane" ]]; then
            if [[ "$p" == "$current_pane" ]]; then
                kill_current=true
            else
                tmux kill-pane -t "$p"
            fi
        fi
    done

    # Ensure Helix is on the left, Claude on the right
    local hx_left=$(tmux display-message -t "$hx_pane" -p "#{pane_left}")
    local cl_left=$(tmux display-message -t "$cl_pane" -p "#{pane_left}")
    if [[ "$hx_left" -gt "$cl_left" ]]; then
        tmux swap-pane -s "$hx_pane" -t "$cl_pane"
    fi

    # Apply horizontal layout, then resize for wide terminals
    tmux select-layout -t "$window_id" even-horizontal
    local width=$(tmux display-message -p "#{window_width}")
    if [[ "$width" -ge "$threshold" ]]; then
        tmux resize-pane -t "$hx_pane" -x $(( width * 2 / 3 ))
    fi

    # Focus Helix pane
    tmux select-pane -t "$hx_pane"

    # Kill current pane last if it was an extra (terminates this shell)
    if [[ "$kill_current" == true ]]; then
        tmux kill-pane -t "$current_pane"
    fi
}
