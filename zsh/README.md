# Zsh 설정

## 구조

| 파일 | 설명 |
|------|------|
| `.zshrc` | 메인 설정. oh-my-zsh, 플러그인, 버전 매니저, fzf 등 로드 |
| `setup.sh` | oh-my-zsh 및 플러그인 설치 스크립트 |

## .zshrc 로드 순서

1. tmux 자동 실행
2. locale, secrets
3. brew prefix 캐싱
4. oh-my-zsh + 플러그인 (git, brew, zsh-syntax-highlighting, zsh-autosuggestions)
5. 에디터, alias
6. 버전 매니저 (rbenv, nvm, jenv, pyenv)
7. fzf 키바인딩
8. zoxide (autojump 대체, z/zi 명령어)
