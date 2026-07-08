#!/bin/sh
# Set up the default tmux layout
# Usage: ./tmux/tmux-layout.sh (run outside of tmux)

SESSION_DEFAULT="default"
SESSION_WORKSPACE="workspace1"

# Running inside tmux would kill this very session, so block it
if [ -n "$TMUX" ]; then
  echo "Please run outside of tmux"
  exit 1
fi

# Clear all existing sessions (kill individually to prevent continuum auto-restore)
tmux list-sessions -F '#S' 2>/dev/null | while read -r s; do
  tmux kill-session -t "$s"
done

# -- default session (create first so it stays at the top of the session list) --
tmux new-session -d -s "$SESSION_DEFAULT"

# -- workspace session --
tmux new-session -d -s "$SESSION_WORKSPACE" -n "server"

# server window: split top/bottom → split the top pane left/right
# ┌───────┬───────┐
# │       │       │
# ├───────┴───────┤
# │               │
# └───────────────┘
tmux split-window -v -t "$SESSION_WORKSPACE:server"
tmux select-pane -t "$SESSION_WORKSPACE:server.0"
tmux split-window -h -t "$SESSION_WORKSPACE:server.0"

# editor window: single pane
tmux new-window -t "$SESSION_WORKSPACE" -n "editor"

# focus the first pane of the server window
tmux select-window -t "$SESSION_WORKSPACE:server"
tmux select-pane -t "$SESSION_WORKSPACE:server.0"

# attach
tmux attach-session -t "$SESSION_WORKSPACE"
