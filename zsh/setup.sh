#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/scripts/lib/common.sh"

# -- link configs --
for f in "$REPO"/zsh/.*; do
  [[ -f "$f" ]] || continue
  link_path "$f" "$HOME/$(basename "$f")"
done

# -- install (order matters: oh-my-zsh before plugins) --
sh "$REPO/zsh/install-oh-my-zsh.sh"
sh "$REPO/zsh/install-zsh-plugins.sh"
