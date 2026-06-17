# 셋업 가이드

## 사전 준비

- macOS
- Homebrew 설치:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- 이 저장소를 클론: `git clone <repo> ~/Desktop/_zero/dotfiles`

## 1. 패키지 설치

```sh
brew bundle --file packages/Brewfile
```

## 2. 심링크 및 도구 설치

```sh
./bootstrap.sh [--force]
```

이 스크립트가 아래 작업을 순서대로 수행한다:

### 심링크 생성

| 모듈 스크립트 | 동작 |
|---|---|
| `home/setup.sh` | `home/.*` 파일들 → `~/` (`.zshrc`, `.gitconfig`, `.tmux.conf` 등) |
| `claude/setup.sh` | `claude/` → `~/.claude` |
| `ssh/setup.sh` | `ssh/` → `~/.ssh` |
| `hammerspoon/setup.sh` | `hammerspoon/` → `~/.hammerspoon` |
| `nvim/setup.sh` | `nvim/lazy/` → `~/.config/nvim` |

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

## 3. Git identity 설정

`git/.gitconfig`는 공통 설정만 들어 있다. 본인 identity는 `~/.gitconfig.local`에 둔다.

```sh
cp git/.gitconfig.local.example ~/.gitconfig.local
# 편집하여 [user] name/email 입력
```

## 4. Neovim 플러그인 동기화

```sh
nvim --headless "+Lazy sync" +qa
```

## 5. 선택 사항 (scripts/unix/opt/)

필요한 것만 골라서 실행한다.

### SSH 키 생성 & GitHub 다중 계정

```sh
./ssh/generate-key.sh [LABEL] [EMAIL]
```

`~/.ssh/id_rsa_{LABEL}`에 키를 생성하고 ssh-agent에 등록한다. LABEL은 자유 식별자(`github_myuser`, `gcp_yorez333` 등). GitHub용이라면 생성된 공개키를 https://github.com/settings/keys 에 추가한다.

같은 머신에서 GitHub 계정을 여러 개 쓰려면 `ssh/config.d/10-personal` 같은 파일에 Host 별칭을 추가한다 (`ssh/config`가 `Include config.d/*` 처리):

```ssh
Host github.com-myuser
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_github_myuser
```

이후 별칭으로 clone/remote 설정:

```sh
git clone git@github.com-myuser:username/repo.git
git remote set-url origin git@github.com-myuser:username/repo.git
ssh -T git@github.com-myuser   # 연결 확인
```

### Git includeIf 설정 (워크스페이스별 계정 분리)

```sh
./git/add-workspace-user.sh [WORKSPACE_PATH] [GIT_NAME] [GIT_EMAIL]
```

특정 디렉터리 하위의 Git 저장소에서 다른 이름/이메일을 사용하도록 설정한다. 회사/개인 계정을 분리할 때 사용.

### Java 버전 관리

```sh
./scripts/setup-java-versions.sh
```

Homebrew로 설치된 openjdk(8, 11, 17, 21)에 대해 `/Library/Java/JavaVirtualMachines/` 심링크를 만들고 jenv에 등록한다. sudo 필요.

### Neovim Java LSP 설정

```sh
./nvim/opt/generate-nvim-java.sh
```
