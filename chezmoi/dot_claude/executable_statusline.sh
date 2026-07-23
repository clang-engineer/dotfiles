#!/usr/bin/env bash
# Claude Code statusline: pin the current working directory + git branch at the bottom of the screen.
# Claude Code streams session info as JSON on stdin.
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd')

dir="${cwd/#$HOME/~}"
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
# cwd itself/its subdirs are already inside the permission boundary, so add-dir is meaningless → exclude from display
added=$(printf '%s' "$input" | jq -r --arg cwd "$cwd" '.workspace.added_dirs[]? | select(startswith($cwd) | not) | split("/") | last' | paste -sd ' ' -)

out="📁 $dir"
[[ -n "$branch" ]] && out+="  ⎇ $branch"
[[ -n "$added" ]] && out+="  ➕ $added"
printf '%s' "$out"
