# tmux 자동 실행 (이미 tmux 안이 아닐 때만, IDE 내장 터미널 제외)
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]] && [[ "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ]]; then
  tmux attach -t default || tmux new -s default
fi

# Locale
export LANG=ko_KR.UTF-8

# Load secrets (tokens, credentials) from a local-only file
[ -f ~/.secrets ] && source ~/.secrets

# brew prefix 캐싱 (brew --prefix는 느려서 한 번만 호출)
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
fi

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
# 테마 전환: 아래 둘 중 하나만 활성화
# ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME=""  # starship 사용 시 비워둘 것

plugins=(
    git brew
    zsh-syntax-highlighting
    zsh-autosuggestions
)

source ~/.oh-my-zsh/oh-my-zsh.sh

# Project directories (WORKSPACE_DIR, BLOG_DIR, TOOLBOX_DIR are set in ~/.secrets per machine)

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# 모던 CLI alias
if command -v bat &>/dev/null; then alias cat="bat"; fi
if command -v eza &>/dev/null; then alias ls="eza"; fi

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

# fzf (Ctrl+T 파일 선택, Ctrl+R 히스토리, Alt+C 디렉터리 이동)
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# zoxide (autojump 대체, z/zi 명령어)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

