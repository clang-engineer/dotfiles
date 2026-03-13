#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup.sh [--force]

Options:
  --force           Replace existing files/symlinks at the destination.
USAGE
}

FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

export FORCE

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# -- linking (module setup scripts) --
"$REPO"/home/setup.sh
"$REPO"/claude/setup.sh
"$REPO"/ssh/setup.sh
"$REPO"/hammerspoon/setup.sh
"$REPO"/nvim/setup.sh

# -- install --
"$REPO"/scripts/unix/install-oh-my-zsh.sh
"$REPO"/scripts/unix/install-zsh-plugins.sh
"$REPO"/scripts/unix/install-tpm.sh

# -- post-install --
if command -v tmux >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" || true
fi

if command -v jenv >/dev/null 2>&1; then
  jenv enable-plugin export || true
  printf '→ Enabled jenv export plugin\n'
fi

printf '\nAll done. Review warnings above and rerun with --force if needed.\n'
