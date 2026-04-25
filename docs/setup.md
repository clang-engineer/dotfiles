# 셋업 가이드

## 사전 준비

- macOS + Homebrew 설치
- 이 저장소를 클론: `git clone <repo> ~/Desktop/_zero/dotfiles`

## 1. 패키지 설치

```sh
brew bundle --file packages/Brewfile
```

## 2. 심링크 및 도구 설치

```sh
./scripts/setup.sh [--force]
```

이 스크립트가 아래 작업을 순서대로 수행한다:

### 심링크 생성

| 모듈 스크립트 | 동작 |
|---|---|
| `home/setup.sh` | `home/.*` 파일들 → `~/` (`.zshrc`, `.gitconfig`, `.tmux.conf` 등) |
| `claude/setup.sh` | `claude/` → `~/.claude` |
| `ssh/setup.sh` | `ssh/` → `~/.ssh` |
| `hammerspoon/setup.sh` | `hammerspoon/` → `~/.hammerspoon` |
| `nvim/setup.sh` | `nvim/lazy/` → `~/.config/nvim`, `nvim/exrc/exrc-unix.lua` → `~/.exrc.lua` |

### 도구 설치

| 스크립트 | 동작 |
|---|---|
| `install-oh-my-zsh.sh` | oh-my-zsh 설치 |
| `install-zsh-plugins.sh` | zsh-syntax-highlighting, zsh-autosuggestions, autojump 설치 |
| `install-tpm.sh` | tmux plugin manager 설치 |

### 후처리

- tmux 설정 반영 (`tmux source-file`)
- jenv export 플러그인 활성화 (jenv가 있는 경우)

> 기존 파일이 있으면 경고만 출력하고 건너뛴다. `--force`를 붙이면 기존 파일을 덮어쓴다.

## 3. Neovim 플러그인 동기화

```sh
nvim --headless "+Lazy sync" +qa
```

## 4. 선택 사항 (scripts/unix/opt/)

필요한 것만 골라서 실행한다.

### SSH 키 생성

```sh
./git/opt/generate-ssh-key.sh [USERNAME] [EMAIL]
```

GitHub용 SSH 키를 `~/.ssh/id_rsa_github_{USERNAME}`에 생성하고 ssh-agent에 등록한다. 생성된 공개키를 https://github.com/settings/keys 에 추가할 것.

### Git includeIf 설정 (워크스페이스별 계정 분리)

```sh
./git/opt/setup-git-includeif.sh [WORKSPACE_PATH] [GIT_NAME] [GIT_EMAIL]
```

특정 디렉터리 하위의 Git 저장소에서 다른 이름/이메일을 사용하도록 설정한다. 회사/개인 계정을 분리할 때 사용.

### Java 버전 관리

```sh
./scripts/unix/opt/setup-java-versions.sh
```

Homebrew로 설치된 openjdk(8, 11, 17, 21)에 대해 `/Library/Java/JavaVirtualMachines/` 심링크를 만들고 jenv에 등록한다. sudo 필요.

### Neovim Java LSP 설정

```sh
./nvim/opt/generate-nvim-java.sh
```
