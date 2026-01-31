#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup.sh [--force] [--vim lazy|classic]

Runs setup tasks in order:
  01-link-dotfiles
  02-oh-my-zsh
  03-zsh-plugins
  04-tpm
  05-nvim

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

source "$(dirname "${BASH_SOURCE[0]}")/lib/context.sh"

TASKS_DIR="$SCRIPTS_DIR/tasks"

run_task() {
  local task="$1"
  local task_path="$TASKS_DIR/$task"

  if [[ -x "$task_path" ]]; then
    printf '\n==> %s\n' "$task"
    "$task_path"
  else
    printf '⚠︎ Missing task: %s\n' "$task_path"
  fi
}

run_task "01-link-dotfiles.sh"
run_task "02-oh-my-zsh.sh"
run_task "03-zsh-plugins.sh"
run_task "04-tpm.sh"
run_task "05-nvim.sh"

if command -v tmux >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" || true
fi

if command -v jenv >/dev/null 2>&1; then
  jenv enable-plugin export || true
  printf '→ Enabled jenv export plugin\n'
fi

printf '\nAll done. Review warnings above and rerun with --force if needed.\n'
