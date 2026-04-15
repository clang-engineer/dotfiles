#!/bin/bash
# PostToolUse hook for ExitPlanMode
# Saves the approved plan to docs/plans/{date}.md in the current project

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

# Extract [ProjectName] from title, default to [General]
PROJECT=$(echo "$TITLE" | grep -o '^\[.*\]' | head -1)
if [ -z "$PROJECT" ]; then
  PROJECT="[General]"
else
  TITLE=$(echo "$TITLE" | sed 's/^\[.*\] *//')
fi

DATE=$(date +%Y-%m-%d)
TARGET="docs/plans/${DATE}.md"
mkdir -p docs/plans

# Skip if already recorded
if [ -f "$TARGET" ] && grep -qF "$TITLE" "$TARGET"; then
  exit 0
fi

# Append plan body (everything after the first heading)
BODY=$(echo "$PLAN_CONTENT" | tail -n +2)

{
  echo ""
  echo "## ${PROJECT} ${TITLE}"
  echo "${BODY}"
  echo ""
} >> "$TARGET"
