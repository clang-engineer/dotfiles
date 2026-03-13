#!/usr/bin/env bash

input=$(cat)

# 현재 작업 디렉토리
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Git 브랜치
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')

# 컨텍스트 사용량
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# 기본 표시: cwd + branch
parts="cwd: $cwd"
[ -n "$branch" ] && parts="$parts | branch: $branch"

# 컨텍스트 사용량 추가 (데이터가 있을 때만)
if [ -n "$used" ]; then
  ctx_info="ctx: ${used}%"
  if [ -n "$total_in" ] && [ -n "$total_out" ]; then
    ctx_info="$ctx_info (in: $total_in / out: $total_out)"
  fi
  parts="$parts | $ctx_info"
fi

echo "$parts"
