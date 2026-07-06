# Dotfiles

개인 환경 설정 모음. 새 머신에서 `bootstrap.sh` 한 줄로 zsh / tmux / git / nvim / claude / hammerspoon을 셋업합니다.

## 빠른 시작

```sh
./bootstrap.sh           # macOS / Linux  — 상세: SETUP.md
./bootstrap.ps1          # Windows PowerShell — 프로필 링크 + Neovim 구성 + 패키지 설치
```

설치 후 패키지를 한 번에 채우려면:

```sh
brew bundle install --file packages/Brewfile   # macOS
```

- 상세 셋업 절차(macOS): [SETUP.md](SETUP.md)
- 비밀 관리(SSH 키, `~/.secrets`, identity 등): [SECURITY.md](SECURITY.md)

## 저장소 구조

| 폴더 | 설명 | bootstrap |
|---|---|:-:|
| `zsh/` | Zsh/Bash 설정 + 플러그인 설치 | ✅ |
| `tmux/` | tmux 설정 + TPM 설치 | ✅ |
| `git/` | 공통 `.gitconfig` + workspace 분리 스크립트 | ✅ |
| `nvim/` | Neovim 설정 (LazyVim 기본, classic 별도) | ✅ |
| `claude/` | Claude Code 설정 (`~/.claude` 링크) | ✅ |
| `hammerspoon/` | macOS 자동화 (`~/.hammerspoon` 링크) | ✅ |
| `home/` | 단독 파일 (`.ideavimrc`, `.clang-format` 등) | ✅ |
| `ssh/` | SSH config + 키 생성 스크립트 | ❌ 수동 |

`ssh/`는 기존 키 유실 위험 때문에 bootstrap에서 자동화하지 않습니다 (`--force`도 건너뜀). `packages/`(Brewfile)와 `scripts/`(부트스트랩 오케스트레이터)는 직접 만질 일이 거의 없습니다.

## 옵션

- `--force`: 대상 위치의 기존 파일/링크를 덮어씁니다.
- `--help`: 사용법 출력.

## 관련 저장소

`claude/`에 정의된 Claude Code 스킬(`/notes`, `/blog`, `/notes-cleanup` 등)이 아래 두 저장소로 메모를 적재·발행합니다.

| 저장소 | 설명 |
|---|---|
| toolbox _(private)_ | TIL·cheatsheet·분석 노트 적재. `$TOOLBOX_DIR`로 연결 |
| [clang-engineer.github.io](https://github.com/clang-engineer/clang-engineer.github.io) | 기술 블로그. `$BLOG_DIR/_posts/`로 발행 |
