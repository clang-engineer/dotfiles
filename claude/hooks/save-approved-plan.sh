#!/bin/bash
# PostToolUse hook for ExitPlanMode
# Saves the approved plan to dotfiles/docs/plans/{project}/{date}.md

DOTFILES="${HOME}/Desktop/_zero/dotfiles"
PLANS_DIR="${HOME}/.claude/plans"
PLAN_FILE=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$PLAN_FILE" ]; then
  exit 0
fi

# Only process if the plan file was modified in the last 60 seconds
MOD_TIME=$(stat -f %m "$PLAN_FILE")
NOW=$(date +%s)
if [ $((NOW - MOD_TIME)) -gt 60 ]; then
  exit 0
fi

PLAN_CONTENT=$(cat "$PLAN_FILE")

# Extract title: "# Plan: title" or "# title"
TITLE=$(echo "$PLAN_CONTENT" | grep -m1 '^# ' | sed 's/^# Plan: //' | sed 's/^# //')
if [ -z "$TITLE" ]; then
  TITLE="Untitled"
fi

PROJECT=$(basename "$PWD")
DATE=$(date +%Y-%m-%d)
TARGET_DIR="${DOTFILES}/docs/plans/${PROJECT}"
TARGET="${TARGET_DIR}/${DATE}.md"
mkdir -p "$TARGET_DIR"

# Skip if already recorded
if [ -f "$TARGET" ] && grep -qF "$TITLE" "$TARGET"; then
  exit 0
fi

BODY=$(echo "$PLAN_CONTENT" | tail -n +2)

{
  echo ""
  echo "## ${TITLE}"
  echo "${BODY}"
  echo ""
} >> "$TARGET"
