# Tooling Integration Notes

이 문서는 `packages/Brewfile`에 패키지를 추가하는 것만으로 끝나지 않고,
**dotfiles에서 별도의 integration/setup을 추가한 도구**를 기록한다.

도구의 일반적인 사용법과 비교는 `clang-engineer/devkit`의 cheatsheet에 두고,
이 문서에는 이 저장소에서 실제로 어떤 설정을 추가했는지만 남긴다.

## Atuin

### 설치

`packages/Brewfile`:

```ruby
brew "atuin"
```

### 추가 셋업

`chezmoi/dot_zshrc`에서 fzf를 먼저 초기화한 뒤 Atuin을 초기화한다.

```zsh
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi
```

초기화 순서를 이렇게 둔 이유는 기존 fzf shell integration의 `Ctrl-R` history
binding을 Atuin이 최종적으로 가져가게 하기 위해서다.

현재 역할 분담:

```text
Ctrl-R -> Atuin history
Ctrl-T -> fzf file/path picker
Alt-C  -> fzf directory picker
gco    -> fzf branch picker
```

Atuin sync는 현재 필수 설정이 아니다. 동기화를 켜기 전에는 command argument에
secret/token이 기록될 수 있으므로 history filtering 정책을 먼저 검토한다.

## Yazi

### 설치

`packages/Brewfile`:

```ruby
brew "yazi"
```

### 추가 셋업

기본 실행 명령은 `yazi`다. `chezmoi/dot_zshrc`에는 별도로 `y()` wrapper를 두어
Yazi 종료 시 마지막 디렉터리를 현재 shell cwd로 넘긴다.

동작 흐름:

```text
y
-> Yazi에서 디렉터리 탐색
-> Yazi가 마지막 cwd를 임시 파일에 기록
-> wrapper가 해당 경로를 읽음
-> shell에서 cd
```

따라서 사용 기준은 다음처럼 나눈다.

```text
목적지를 알고 있음       -> zoxide (`z`)
구조를 보면서 찾아야 함  -> Yazi (`y`)
```

`yazi` 명령 자체는 그대로 남아 있어 cwd handoff 없이 실행할 수도 있다.

## Global Git quality hook + prek

### 설치

`packages/Brewfile`에서 공통 검사 도구를 설치한다.

```ruby
brew "shellcheck"
brew "shfmt"
brew "typos-cli"
brew "stylua"
brew "prek"
```

### 전역 hook

`chezmoi/dot_gitconfig`에서 Git의 전역 hook 경로를 지정한다.

```ini
[core]
    hooksPath = ~/.config/git/hooks
```

chezmoi가 `~/.config/git/hooks/pre-commit`을 관리하므로 **이 머신의 모든 Git
repository**에서 commit 전에 같은 가벼운 검사가 실행된다.

```text
staged shell files -> ShellCheck + shfmt --diff
staged Lua files   -> Stylua --check
staged text files  -> typos
```

검사 도구가 설치되지 않은 머신에서는 해당 검사만 건너뛴다. 전역 hook은 staged
파일만 대상으로 하므로 unrelated 파일 때문에 commit이 막히는 범위를 줄인다.

### repository별 확장

전역 hook은 공통 최소 검사만 담당한다. repository 루트에
`.pre-commit-config.yaml`이 있으면 같은 전역 hook이 추가로:

```bash
prek run
```

을 실행한다. 따라서 Java/Node/Python 등 프로젝트별 lint/test는 각 repository의
prek config에 두고, 별도로 `prek install`을 실행할 필요는 없다.

```text
git commit
  -> ~/.config/git/hooks/pre-commit
       -> 공통 staged-file 검사
       -> .pre-commit-config.yaml 있음?
            -> prek run
```

기존 `chezmoi/run_onchange_after_15-prek-install.sh.tmpl` 방식은 dotfiles repository
하나에만 `.git/hooks/pre-commit`을 설치했으므로 제거했다.

## chezmoi apply와 Homebrew

`chezmoi/run_onchange_after_05-brew-bundle.sh.tmpl`은 `packages/Brewfile`과 macOS
cask Brewfile의 hash를 추적한다. 패키지 선언이 바뀌면 `chezmoi apply`가 자동으로:

```bash
brew bundle --no-upgrade --file=...
```

을 실행한다.

`--no-upgrade`를 사용하므로 기존 설치 패키지를 일괄 업그레이드하지 않고 누락된
패키지를 설치하는 데 집중한다.

## 문서화 원칙

앞으로 새 도구를 추가할 때 다음 기준으로 기록한다.

```text
설치만 하면 끝                -> Brewfile 주석으로 충분
shell init/key binding 필요    -> 이 문서에 추가
wrapper/alias/function 추가    -> 이 문서에 추가
Git hook/driver 등록 필요      -> 이 문서에 추가
로그인/daemon 자동실행 필요   -> 이 문서에 추가
Neovim extra/plugin 설정 필요  -> 이 문서에 추가
OS별 별도 설치/분기 필요      -> 이 문서에 추가
```

일반적인 명령어와 사용법은 devkit cheatsheet에, 이 저장소에서 실제로 적용한
integration은 이 문서에 남긴다.
