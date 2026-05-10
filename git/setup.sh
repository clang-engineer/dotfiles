#!/usr/bin/env bash
# Link git/.gitconfig → ~/.gitconfig.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

link_path "$REPO/git/.gitconfig" "$HOME/.gitconfig"
