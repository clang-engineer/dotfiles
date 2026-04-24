#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

CLAUDE_DIR="$HOME/.claude"

if [[ -L "$CLAUDE_DIR" ]]; then
  printf '⚠︎ %s is a symlink (legacy whole-dir setup); skipping claude linking.\n' "$CLAUDE_DIR"
  printf '  Remove it manually, then rerun to migrate to per-file links.\n'
  exit 0
fi

ensure_dir "$CLAUDE_DIR"

for f in CLAUDE.md settings.json; do
  [[ -f "$REPO/claude/$f" ]] || continue
  link_path "$REPO/claude/$f" "$CLAUDE_DIR/$f"
done

for d in commands hooks; do
  [[ -d "$REPO/claude/$d" ]] || continue
  link_path "$REPO/claude/$d" "$CLAUDE_DIR/$d"
done
