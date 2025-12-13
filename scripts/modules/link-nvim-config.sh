#!/usr/bin/env bash

# Symlink Neovim config
link_nvim_config() {
  local configs_dir="$1"
  local vim_flavor="$2"

  ensure_dir "$HOME/.config"

  case "$vim_flavor" in
    lazy)
      if [[ -d "$configs_dir/nvim-lazy" ]]; then
        link_path "$configs_dir/nvim-lazy" "$HOME/.config/nvim"
      else
        printf '⚠︎ lazy Neovim config missing; skipping Neovim link\n'
      fi
      ;;
    classic)
      if [[ -d "$configs_dir/nvim-classic" ]]; then
        link_path "$configs_dir/nvim-classic" "$HOME/.config/nvim"
      else
        printf '⚠︎ classic Neovim config missing; skipping Neovim link\n'
      fi
      ;;
  esac
}
