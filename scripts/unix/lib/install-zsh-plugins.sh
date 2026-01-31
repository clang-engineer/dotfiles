#!/usr/bin/env bash

# Install zsh plugins if oh-my-zsh is installed
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
install_zsh_plugins() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ZSH_PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"
    ensure_dir "$ZSH_PLUGIN_DIR"

    # Install zsh-syntax-highlighting
    if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]]; then
      printf '→ Installing zsh-syntax-highlighting...\n'
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" 2>/dev/null || \
        printf '⚠︎ Failed to install zsh-syntax-highlighting\n'
    else
      printf '✓ zsh-syntax-highlighting already installed\n'
    fi

    # Install zsh-autosuggestions
    if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]]; then
      printf '→ Installing zsh-autosuggestions...\n'
      git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_PLUGIN_DIR/zsh-autosuggestions" 2>/dev/null || \
        printf '⚠︎ Failed to install zsh-autosuggestions\n'
    else
      printf '✓ zsh-autosuggestions already installed\n'
    fi

    # Install autojump
    if command -v brew &>/dev/null; then
      if ! brew list autojump &>/dev/null; then
        printf '→ Installing autojump via Homebrew...\n'
        brew install autojump 2>/dev/null || \
          printf '⚠︎ Failed to install autojump\n'
      else
        printf '✓ autojump already installed\n'
      fi
    elif command -v apt-get &>/dev/null; then
      if ! command -v autojump &>/dev/null; then
        printf '→ Installing autojump via apt...\n'
        sudo apt-get install -y autojump 2>/dev/null || \
          printf '⚠︎ Failed to install autojump\n'
      else
        printf '✓ autojump already installed\n'
      fi
    else
      printf '⚠︎ Package manager not found; skipping autojump installation\n'
    fi
  else
    printf '⚠︎ oh-my-zsh not found; skipping zsh plugin installation\n'
  fi
}
