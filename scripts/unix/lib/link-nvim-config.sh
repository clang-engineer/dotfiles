#!/usr/bin/env bash

# Symlink Neovim config
source "$(dirname "${BASH_SOURCE[0]}")/context.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
link_nvim_config() {
  local nvim_dir="$1"
  local vim_flavor="$2"

  ensure_dir "$HOME/.config"

  case "$vim_flavor" in
    lazy)
      if [[ -d "$nvim_dir/lazy" ]]; then
        link_path "$nvim_dir/lazy" "$HOME/.config/nvim"
      else
        printf '⚠︎ lazy Neovim config missing; skipping Neovim link\n'
      fi
      ;;
    classic)
      if [[ -d "$nvim_dir/classic" ]]; then
        link_path "$nvim_dir/classic" "$HOME/.config/nvim"
      else
        printf '⚠︎ classic Neovim config missing; skipping Neovim link\n'
      fi
      ;;
  esac
}
