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

## ShellCheck + shfmt + typos + prek

### 설치

`packages/Brewfile`:

```ruby
brew "shellcheck"
brew "shfmt"
brew "typos-cli"
brew "prek"
```

### hook 설정

저장소 루트의 `.pre-commit-config.yaml`에서 system-installed binary를 사용하는
local hooks로 구성한다.

```text
ShellCheck -> shell static analysis
shfmt      -> shell formatting check (`-d`, 수정하지 않고 diff/실패)
typos      -> text file typo check
```

`shfmt`는 commit 시 파일을 자동 수정하지 않는다. 포맷이 맞지 않으면 diff를
보여주고 commit을 막아 명시적으로 수정하게 한다.

수동으로 전체 hook을 실행하려면:

```bash
prek run --all-files
```

### Git hook 설치 자동화

prek binary와 config만 있어서는 commit 때 자동 실행되지 않는다. Git hook shim을
설치해야 한다.

`chezmoi/run_onchange_after_15-prek-install.sh.tmpl`이
`.pre-commit-config.yaml`의 hash를 포함하고 있어 config가 바뀌면 `chezmoi apply`
시 다시 실행된다.

```text
chezmoi apply
-> Brewfile 변경 시 brew bundle --no-upgrade
-> prek 설치 확인
-> prek install
-> .git/hooks/pre-commit shim 설치
```

즉 새 머신에서도 별도로 `prek install`을 기억할 필요가 없도록 dotfiles 적용
과정에 포함했다.

## LazyVim chezmoi extra

### 활성화

`nvim/lazy/lazyvim.json`에 다음 extra를 활성화한다.

```text
lazyvim.plugins.extras.util.chezmoi
```

### 추가 셋업

이 저장소는 chezmoi source가 기본 `~/.local/share/chezmoi`가 아니라
`~/dotfiles/chezmoi`에 있으므로 `nvim/lazy/lua/plugins/chezmoi.lua`에서 source
path를 override한다.

주 사용 목적은 chezmoi source/template 파일을 Neovim에서 더 자연스럽게 다루는
것이다.

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
