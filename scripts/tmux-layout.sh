#!/bin/sh
# tmux 기본 레이아웃 구성
# Usage: ./tmux/tmux-layout.sh (tmux 밖에서 실행)

SESSION_DEFAULT="default"
SESSION_WORKSPACE="workspace1"

# tmux 안에서 실행하면 세션 kill 시 자기 자신이 죽으므로 차단
if [ -n "$TMUX" ]; then
  echo "tmux 밖에서 실행해 주세요"
  exit 1
fi

# 기존 세션 전부 정리 (continuum 자동복원 방지를 위해 개별 kill)
tmux list-sessions -F '#S' 2>/dev/null | while read -r s; do
  tmux kill-session -t "$s"
done

# -- default 세션 (먼저 생성해서 세션 목록 상단 유지) --
tmux new-session -d -s "$SESSION_DEFAULT"

# -- workspace 세션 --
tmux new-session -d -s "$SESSION_WORKSPACE" -n "server"

# server 윈도우: 위아래 분할 → 위쪽을 좌우 분할
# ┌───────┬───────┐
# │       │       │
# ├───────┴───────┤
# │               │
# └───────────────┘
tmux split-window -v -t "$SESSION_WORKSPACE:server"
tmux select-pane -t "$SESSION_WORKSPACE:server.0"
tmux split-window -h -t "$SESSION_WORKSPACE:server.0"

# editor 윈도우: 단일 패인
tmux new-window -t "$SESSION_WORKSPACE" -n "editor"

# server 윈도우 첫 번째 패인으로 포커스
tmux select-window -t "$SESSION_WORKSPACE:server"
tmux select-pane -t "$SESSION_WORKSPACE:server.0"

# attach
tmux attach-session -t "$SESSION_WORKSPACE"
