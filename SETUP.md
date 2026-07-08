# 셋업 가이드

## 사전 준비

- macOS
- Homebrew 설치:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- chezmoi 설치: `brew install chezmoi`
- 이 저장소를 클론: `git clone <repo> ~/Desktop/_zero/private/dotfiles`

## 1. chezmoi 연결 (머신-로컬, 1회)

chezmoi가 이 repo를 소스로 쓰도록 `~/.config/chezmoi/chezmoi.toml`을 만든다:

```sh
mkdir -p ~/.config/chezmoi
echo 'sourceDir = "~/Desktop/_zero/private/dotfiles"' > ~/.config/chezmoi/chezmoi.toml
```

> `~`는 chezmoi가 확장하므로 머신마다 고칠 필요 없다. 템플릿은 repo 경로를
> `{{ .chezmoi.sourceDir | dir }}`로 유도하므로 `dotfilesDir` 같은 추가 설정이 필요 없다.
>
> `.chezmoiroot`가 소스 루트를 `chezmoi/` 하위로 잡으므로, docs·packages·scripts는
> chezmoi 대상에서 자동 제외된다.

## 2. 적용

```sh
chezmoi diff     # 무엇이 바뀔지 미리보기
chezmoi apply    # 링크·복사·설치·생성 한 번에
```

`chezmoi apply`가 순서대로 수행하는 것 — 파일 배치(소스→타겟, managed vs symlink)는
[README](README.md#how-it-works) 표가 1차 출처다. 여기서는 실행되는 스크립트만 정리한다:

### 스크립트 (run\_)

| 스크립트 | 동작 |
|---|---|
| `run_once_after_10-install-shell-tools.sh` | oh-my-zsh, zsh 플러그인, TPM, jenv |
| `run_after_20-generate-claude-settings.sh` | `~/.secrets` env로 `claude/settings.json` 생성 |
| `run_after_30-secrets-overlay.sh` | `SECRETS_DIR` 있으면 secrets repo 오버레이 실행 |

> 이후 config 수정은 `chezmoi edit --apply ~/.zshrc` (소스 편집 + 즉시 적용).
> nvim/hammerspoon/claude는 symlink라 평소처럼 직접 편집하면 된다.

## 3. 패키지 설치

```sh
brew bundle --file packages/Brewfile
```

## 4. 머신-로컬 시크릿 (`~/.secrets`)

토큰·머신 경로는 `~/.secrets`에 둔다 (repo에 안 들어감). 셸이 자동 source.

```sh
cp scripts/.secrets.example ~/.secrets && chmod 600 ~/.secrets
$EDITOR ~/.secrets   # GITHUB_TOKEN, 워크스페이스 경로, (선택) SECRETS_REPO 등
```

## 5. Git identity 설정

`dot_gitconfig`는 공통 설정 + `[include] ~/.gitconfig.local`만 있다. 본인 identity는
`~/.gitconfig.local`에 둔다:

```sh
cp scripts/.gitconfig.local.example ~/.gitconfig.local
# 편집하여 [user] name/email 입력
```

## 6. Neovim 플러그인 동기화

```sh
nvim --headless "+Lazy sync" +qa
```

## 7. 선택 사항 (scripts/)

필요한 것만 골라서 실행한다.

### SSH 키 생성 & GitHub 다중 계정

```sh
./scripts/generate-key.sh [LABEL] [EMAIL]
```

`~/.ssh/id_rsa_{LABEL}`에 키를 생성하고 ssh-agent에 등록한다. LABEL은 자유 식별자
(`github_myuser`, `gcp_yorez333` 등). GitHub용이라면 공개키를
https://github.com/settings/keys 에 추가한다.

Host 별칭은 `~/.ssh/config.d/`에 추가한다 (`~/.ssh/config`가 `Include config.d/*`).
공개 repo는 `00-global`만 관리하고, 실제 사설 호스트는 `secrets` repo가 오버레이한다:

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
./scripts/add-workspace-user.sh [WORKSPACE_PATH] [GIT_NAME] [GIT_EMAIL]
```

특정 디렉터리 하위의 Git 저장소에서 다른 이름/이메일을 사용하도록 설정한다.
회사/개인 계정을 분리할 때 사용.

### Java 버전 관리

```sh
./scripts/setup-java-versions.sh
```

Homebrew openjdk(8, 11, 17, 21)에 대해 `/Library/Java/JavaVirtualMachines/` 심링크를
만들고 jenv에 등록한다. sudo 필요.

### Neovim Java LSP 설정

프로젝트 루트에서 Neovim 명령으로 `.nvim.lua` 생성:

```vim
:JvmEnvInit 21 17
```
