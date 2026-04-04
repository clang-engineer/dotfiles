# Dotfiles — Claude Code 프로젝트 지시사항

## 프로젝트 개요
macOS 개발환경 설정 파일 모음. 셸, 에디터, 도구 설정을 한 곳에서 관리한다.

## 모듈 구조
- `home/` — 홈 디렉터리 1:1 매핑 (`.zshrc`, `.gitconfig`, `.tmux.conf` 등)
- `nvim/` — Neovim 설정 (`lazy/`: LazyVim Lua, `classic/`: Vimscript)
- `hammerspoon/` — macOS 자동화 (윈도우 관리, 단축키)
- `claude/` — Claude Code 설정 (hooks, keybindings, 슬래시 커맨드)
- `packages/` — Brewfile 기반 패키지 정의
- `scripts/` — 설치·링크·유틸리티 스크립트
- `docs/` — 가이드 문서

## 빌드 및 검증 명령
```sh
./scripts/setup.sh [--force]          # 심링크 생성
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
