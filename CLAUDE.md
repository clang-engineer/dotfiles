# Dotfiles — Claude Code 프로젝트 지시사항

## 프로젝트 개요
macOS 개발환경 설정 파일 모음. 셸, 에디터, 도구 설정을 한 곳에서 관리한다.

## 모듈 구조
- `zsh/` — Zsh/Bash 설정 + 플러그인 설치 스크립트
- `tmux/` — tmux 설정 + TPM 설치 스크립트
- `git/` — Git 설정 + 다중 계정 관리 스크립트
- `ssh/` — SSH 설정 (수동 실행)
- `nvim/` — LazyVim 기반 Neovim 설정
- `vim/` — Legacy Vim 설정 (vim-plug + coc, Vundle 두 스냅샷, 자동 링크 안 함)
- `hammerspoon/` — macOS 자동화 (윈도우 관리, 단축키)
- `claude/` — Claude Code 설정 (hooks, keybindings, 슬래시 커맨드)
- `home/` — 단독 설정 파일 (`.ideavimrc`, `.clang-format`, `.vimrc` 등)
- `packages/` — Brewfile 기반 패키지 정의
- `scripts/` — 부트스트랩 오케스트레이터, 공통 라이브러리
- 각 모듈 폴더의 `README.md` — 모듈별 가이드 문서

## 빌드 및 검증 명령
```sh
./bootstrap.sh [--force]              # 심링크 생성
brew bundle check --file packages/Brewfile  # 패키지 누락 확인
nvim --headless "+Lazy sync" +qa      # 플러그인 동기화
tmux source-file ~/.tmux.conf         # tmux 설정 반영
```

## 코딩 컨벤션
- 셸 스크립트: 2-space indent, POSIX 호환
- Lua: stylua 기준 (indent 2, column 120)
- 파일명: 소문자 + 하이픈 (`my-script.sh`)
- 커밋: `feat(scope):`, `fix(scope):`, `chore:` 형식

## 보안
- `.env`, `.secrets`, `credentials` 파일은 절대 커밋하지 않는다
- `ssh/` 등 민감 경로는 링크 후 퍼미션 재확인
- 실제 키 대신 템플릿만 버전 관리
