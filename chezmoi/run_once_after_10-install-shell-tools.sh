#!/usr/bin/env bash
# One-time shell tool installs, absorbed from the old zsh/tmux install scripts.
# Runs once (chezmoi tracks it); each step is idempotent and skips if present.
set -euo pipefail

# --- oh-my-zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if command -v zsh >/dev/null 2>&1; then
    printf '→ Installing oh-my-zsh...\n'
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      || printf '⚠︎ oh-my-zsh install failed\n'
  else
    printf '⚠︎ zsh not found; skipping oh-my-zsh\n'
  fi
else
  printf '✓ oh-my-zsh present\n'
fi

# --- zsh plugins ---
if [ -d "$HOME/.oh-my-zsh" ]; then
  plugin_dir="$HOME/.oh-my-zsh/custom/plugins"
  mkdir -p "$plugin_dir"
  for p in zsh-syntax-highlighting zsh-autosuggestions; do
    if [ ! -d "$plugin_dir/$p" ]; then
      printf '→ Installing %s...\n' "$p"
      git clone "https://github.com/zsh-users/$p.git" "$plugin_dir/$p" 2>/dev/null \
        || printf '⚠︎ %s install failed\n' "$p"
    fi
  done
fi

# --- TPM (Tmux Plugin Manager) ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ] && command -v tmux >/dev/null 2>&1; then
  printf '→ Installing TPM...\n'
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
    || printf '⚠︎ TPM install failed\n'
fi

# --- jenv export plugin ---
if command -v jenv >/dev/null 2>&1; then
  jenv enable-plugin export || true
fi
