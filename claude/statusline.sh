#!/usr/bin/env bash
# Claude Code statusline: 현재 작업 디렉토리 + git 브랜치를 화면 하단에 고정 표시.
# Claude Code가 세션 정보를 JSON으로 stdin에 흘려준다.
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd')

dir="${cwd/#$HOME/~}"
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

out="📁 $dir"
[[ -n "$branch" ]] && out+="  ⎇ $branch"
printf '%s' "$out"
