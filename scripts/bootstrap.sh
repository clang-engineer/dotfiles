#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--force] [--vim lazy|classic]

Symlink dotfiles from the repository into the current user home directory.
  --force           Replace existing files/symlinks at the destination.
  --vim             Choose Neovim config: `lazy` (default) or `classic`.
EOF
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

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_SOURCE_DIR="$REPO_DIR/home"
CONFIGS_DIR="$REPO_DIR/configs"
MODULES_DIR="$REPO_DIR/scripts/modules"

# Utility functions
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

# Source modules
source "$MODULES_DIR/install-oh-my-zsh.sh"
source "$MODULES_DIR/install-zsh-plugins.sh"
source "$MODULES_DIR/link-dotfiles.sh"
source "$MODULES_DIR/link-nvim-config.sh"

# Execute installation steps
install_oh_my_zsh
install_zsh_plugins
link_dotfiles "$HOME_SOURCE_DIR"
link_nvim_config "$CONFIGS_DIR" "$VIM_FLAVOR"

if command -v tmux >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" || true
fi

printf '\nAll done. Review warnings above and rerun with --force if needed.\n'
