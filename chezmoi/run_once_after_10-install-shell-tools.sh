#!/usr/bin/env bash
# One-time shell tool installs, absorbed from the old zsh/tmux install scripts.
# Runs once (chezmoi tracks it); each step is idempotent and skips if present.
set -euo pipefail

# zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting) are installed via
# Homebrew (packages/Brewfile) and sourced directly in .zshrc — no framework.

# --- TPM (Tmux Plugin Manager) + declared plugins ---
# Require ~/.tmux to be the oh-my-tmux clone (the .chezmoiexternal git-repo).
# Without this guard, a failed/skipped external clone would let `git clone tpm`
# create ~/.tmux/plugins/ on its own, leaving ~/.tmux a non-git dir that later
# breaks `chezmoi apply` (git pull → exit 128).
if command -v tmux >/dev/null 2>&1 && [ -d "$HOME/.tmux/.git" ]; then
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    printf '→ Installing TPM...\n'
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
      || printf '⚠︎ TPM install failed\n'
  fi
  # install plugins declared in ~/.tmux.conf (non-interactive, was: prefix + I)
  if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
  fi
fi

# --- mise: install declared runtimes (node/ruby/java) ---
# Versions live in ~/.config/mise/config.toml (chezmoi-managed). mise builds/
# downloads each and puts them on PATH via `mise activate` in the shell rc.
if command -v mise >/dev/null 2>&1; then
  mise install >/dev/null 2>&1 || printf '⚠︎ mise install failed (run `mise install` manually)\n'
fi
