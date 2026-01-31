#!/usr/bin/env bash

set -euo pipefail

FORCE="${FORCE:-false}"

link_path() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      printf '✓ %s already linked\n' "$dest"
      return 0
    fi
    if [[ "$FORCE" == true ]]; then
      rm -f "$dest"
    else
      printf '⚠︎ %s exists; use --force to replace\n' "$dest"
      return 0
    fi
  elif [[ -e "$dest" ]]; then
    if [[ "$FORCE" == true ]]; then
      rm -rf "$dest"
    else
      printf '⚠︎ %s exists; skipping (use --force to replace)\n' "$dest"
      return 0
    fi
  fi

  ln -s "$src" "$dest"
  printf '→ Linked %s → %s\n' "$dest" "$src"
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    printf '→ Created directory %s\n' "$dir"
  fi
}
