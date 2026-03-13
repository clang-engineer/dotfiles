#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

VIM_FLAVOR="lazy"

ensure_dir "$HOME/.config"
link_path "$REPO/nvim/$VIM_FLAVOR" "$HOME/.config/nvim"

# exrc
link_path "$REPO/nvim/exrc/exrc-unix.lua" "$HOME/.exrc.lua"
