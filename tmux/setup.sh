#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

link_path "$REPO/tmux/.tmux.conf" "$HOME/.tmux.conf"

# -- install --
sh "$REPO/tmux/install-tpm.sh"
