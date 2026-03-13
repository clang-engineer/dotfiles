#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup.sh [--force] [--vim lazy|classic]

Options:
  --force           Replace existing files/symlinks at the destination.
  --vim             Choose Neovim config: `lazy` (default) or `classic`.
USAGE
}

FORCE=false
VIM_FLAVOR="lazy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    --vim)
      shift
      VIM_FLAVOR="${1:-}"
      [[ -n "$VIM_FLAVOR" ]] || { usage; exit 1; }
      shift
      ;;
    --vim=*)
      VIM_FLAVOR="${1#--vim=}"
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

case "$VIM_FLAVOR" in
  lazy|classic) ;;
  *)
    echo "Invalid vim flavor: $VIM_FLAVOR (expected lazy|classic)" >&2
    exit 1
    ;;
esac

export FORCE VIM_FLAVOR

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
