# tmux 자동 실행 (이미 tmux 안이 아닐 때만)
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
  tmux attach -t default || tmux new -s default
fi

# Load secrets (tokens, credentials) from a local-only file
[ -f ~/.secrets ] && source ~/.secrets

# brew prefix 캐싱 (brew --prefix는 느려서 한 번만 호출)
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
fi

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
# 테마 전환: "powerlevel10k/powerlevel10k" 또는 "robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git brew
    zsh-syntax-highlighting
    zsh-autosuggestions
)

source ~/.oh-my-zsh/oh-my-zsh.sh

# Project directories (WORKSPACE_DIR is set in ~/.secrets per machine)
export TOOLBOX_DIR="$WORKSPACE_DIR/toolbox"
export BLOG_DIR="$WORKSPACE_DIR/clang-engineer.github.io"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# c++ alias
alias g++="g++ -std=c++17"
alias clang++="clang++ -std=c++17"

# OpenCode aliases
[ -f ~/.opencode_aliases ] && source ~/.opencode_aliases

# rbenv
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init - zsh)"
fi

# nvm
export NVM_DIR=~/.nvm
if [[ -n "$BREW_PREFIX" && -s "$BREW_PREFIX/opt/nvm/nvm.sh" ]]; then
  source "$BREW_PREFIX/opt/nvm/nvm.sh"
fi

# jenv
if command -v jenv &>/dev/null; then
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
fi

# pyenv
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# autojump
if [[ -n "$BREW_PREFIX" ]]; then
  AUTOJUMP_SH="$BREW_PREFIX/etc/profile.d/autojump.sh"
  [[ -s "$AUTOJUMP_SH" ]] && source "$AUTOJUMP_SH"
elif [[ -s /usr/share/autojump/autojump.sh ]]; then
  source /usr/share/autojump/autojump.sh
fi

# powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
