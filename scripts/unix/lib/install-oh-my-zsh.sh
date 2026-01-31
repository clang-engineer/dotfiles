#!/usr/bin/env bash

# Install oh-my-zsh if not already installed
install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    if command -v zsh >/dev/null 2>&1; then
      printf '→ Installing oh-my-zsh...\n'
      RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || \
        printf '⚠︎ Failed to install oh-my-zsh\n'
    else
      printf '⚠︎ zsh not found; skipping oh-my-zsh installation\n'
    fi
  else
    printf '✓ oh-my-zsh already installed\n'
  fi
}
