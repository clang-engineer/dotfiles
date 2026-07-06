#!/usr/bin/env bash
# Link ssh/config and the generic config.d entries into ~/.ssh/ (per-file, not whole-dir).
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

link_path "$REPO/ssh/config" "$SSH_DIR/config"

# Link the generic config.d entries (skip *.example templates).
# Private, machine-specific hosts are linked separately by the `secrets` repo.
ensure_dir "$SSH_DIR/config.d"
for f in "$REPO"/ssh/config.d/*; do
  case "$f" in *.example) continue ;; esac
  link_path "$f" "$SSH_DIR/config.d/$(basename "$f")"
done

# Keys are generated per machine (see ssh/generate-key.sh), never committed.
