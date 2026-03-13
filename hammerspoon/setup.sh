#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"
link_path "$REPO/hammerspoon" "$HOME/.hammerspoon"
