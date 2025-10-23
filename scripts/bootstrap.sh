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

if [[ -d "$HOME_SOURCE_DIR" ]]; then
  while IFS= read -r src; do
    rel="${src#$HOME_SOURCE_DIR/}"
    dest="$HOME/$rel"
    dest_dir="$(dirname "$dest")"
    [[ -d "$dest_dir" ]] || ensure_dir "$dest_dir"
    link_path "$src" "$dest"
  done < <(find "$HOME_SOURCE_DIR" -mindepth 1 -maxdepth 1 -print | sort)
else
  printf '⚠︎ home directory missing at %s; skipping base dotfiles\n' "$HOME_SOURCE_DIR"
fi

ensure_dir "$HOME/.config"

case "$VIM_FLAVOR" in
  lazy)
    if [[ -d "$CONFIGS_DIR/nvim-lazy" ]]; then
      link_path "$CONFIGS_DIR/nvim-lazy" "$HOME/.config/nvim"
    else
      printf '⚠︎ lazy Neovim config missing; skipping Neovim link\n'
    fi
    ;;
  classic)
    if [[ -d "$CONFIGS_DIR/nvim-classic" ]]; then
      link_path "$CONFIGS_DIR/nvim-classic" "$HOME/.config/nvim"
    else
      printf '⚠︎ classic Neovim config missing; skipping Neovim link\n'
    fi
    ;;
esac

if command -v tmux >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" || true
fi

printf '\nAll done. Review warnings above and rerun with --force if needed.\n'
