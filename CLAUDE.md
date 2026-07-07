# Dotfiles — Claude Code 프로젝트 지시사항

## 프로젝트 개요
macOS 개발환경 설정 파일 모음. 셸, 에디터, 도구 설정을 한 곳에서 관리한다.

## 구조
[chezmoi](https://chezmoi.io)로 관리한다. 소스는 `chezmoi/`(홈미러 트리)에 있고,
`chezmoi apply`가 홈에 배치한다.
- `chezmoi/` — chezmoi 소스. managed 실파일(`dot_zshrc`, `dot_gitconfig` 등),
  `private_dot_ssh/`, symlink 엔트리, `run_*` 스크립트, `.chezmoiignore.tmpl`(OS 분기),
  `.chezmoiexternal.toml.tmpl`(secrets pull)
- `nvim/` — LazyVim 기반 Neovim 설정. `~/.config/nvim`으로 **symlink**
- `hammerspoon/` — macOS 자동화. `~/.hammerspoon`으로 **symlink**
- `claude/` — Claude Code 설정. `~/.claude`로 **symlink**
- `vim/` — Legacy Vim 설정 (자동 링크 안 함, 참조용)
- `packages/` — Brewfile / scoop 패키지 정의
- `scripts/` — 툴링 (키 생성, 워크스페이스 identity, secrets/pgpass/java 셋업, 윈도우 설치)
- **managed vs symlink**: 대형 라이브 설정(nvim·hammerspoon·claude)만 symlink(라이브 편집),
  나머지 dotfile은 managed 실파일(`chezmoi edit --apply`로 수정).
- 구조 설명은 루트 `README.md` 표가 1차 출처.

## 빌드 및 검증 명령
```sh
chezmoi diff                          # 적용 전 미리보기
chezmoi apply                         # 링크·복사·설치·생성
chezmoi status                        # 대기 중 변경 (R = run 스크립트)
brew bundle check --file packages/Brewfile  # 패키지 누락 확인
nvim --headless "+Lazy sync" +qa      # 플러그인 동기화
```

## 코딩 컨벤션
- 셸 스크립트: 2-space indent, POSIX 호환
- Lua: stylua 기준 (indent 2, column 120)
- 파일명: 소문자 + 하이픈 (`my-script.sh`)
- 커밋: `feat(scope):`, `fix(scope):`, `chore:` 형식

## 보안
- `.env`, `.secrets`, `credentials` 파일은 절대 커밋하지 않는다
- SSH는 `chezmoi/private_dot_ssh/`로 관리 — `private_`가 `~/.ssh` 0700 보장, 키는 미관리(머신-로컬)
- 실제 키 대신 템플릿만 버전 관리. 사설 값은 `~/.secrets` + `secrets` repo
