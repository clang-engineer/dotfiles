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

# --- jenv: register brew JDKs + export plugin ---
if command -v jenv >/dev/null 2>&1; then
  jenv enable-plugin export || true
  # Register each brew-installed JDK via its version-independent opt path.
  # (Cellar paths embed the patch version, so `brew cleanup` after a patch
  #  upgrade deletes the old dir and leaves jenv symlinks dangling.)
  for v in 11 17 21; do
    home="$(brew --prefix)/opt/openjdk@$v/libexec/openjdk.jdk/Contents/Home"
    [ -x "$home/bin/java" ] && jenv add "$home" >/dev/null 2>&1 || true
  done
  jenv rehash >/dev/null 2>&1 || true
  # Default global to 11 only if nothing is pinned yet.
  [ "$(jenv global 2>/dev/null)" = "system" ] && jenv global 11 || true
fi
