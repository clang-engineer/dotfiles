#!/usr/bin/env bash

# Install TPM (Tmux Plugin Manager) if not already installed
install_tpm() {
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    if command -v tmux >/dev/null 2>&1; then
      printf '→ Installing TPM (Tmux Plugin Manager)...\n'
      git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || \
        printf '⚠︎ Failed to install TPM\n'
    else
      printf '⚠︎ tmux not found; skipping TPM installation\n'
    fi
  else
    printf '✓ TPM already installed\n'
  fi
}
