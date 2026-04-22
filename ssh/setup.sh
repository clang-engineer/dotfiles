#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

SSH_DIR="$HOME/.ssh"

if [[ -L "$SSH_DIR" ]]; then
  printf '⚠︎ %s is a symlink (legacy whole-dir setup); skipping ssh linking.\n' "$SSH_DIR"
  printf '  Remove it manually, then rerun to migrate to per-file links.\n'
  exit 0
fi

ensure_dir "$SSH_DIR"
chmod 700 "$SSH_DIR"

for f in config github_actions github_actions.pub; do
  [[ -f "$REPO/ssh/$f" ]] || continue
  link_path "$REPO/ssh/$f" "$SSH_DIR/$f"
done
