#!/usr/bin/env bash

# Symlink dotfiles from home/ directory
link_dotfiles() {
  local home_source_dir="$1"

  if [[ -d "$home_source_dir" ]]; then
    while IFS= read -r src; do
      rel="${src#$home_source_dir/}"
      dest="$HOME/$rel"
      dest_dir="$(dirname "$dest")"
      [[ -d "$dest_dir" ]] || ensure_dir "$dest_dir"
      link_path "$src" "$dest"
    done < <(find "$home_source_dir" -mindepth 1 -maxdepth 1 -print | sort)
  else
    printf '⚠︎ home directory missing at %s; skipping base dotfiles\n' "$home_source_dir"
  fi
}
