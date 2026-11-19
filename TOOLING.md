# Tooling Integration Notes

이 문서는 `packages/Brewfile`에 패키지를 추가하는 것만으로 끝나지 않고,
**dotfiles에서 별도의 integration/setup을 추가한 도구**를 기록한다.

도구의 일반적인 사용법과 비교는 `clang-engineer/devkit`의 cheatsheet에 두고,
이 문서에는 이 저장소에서 실제로 어떤 설정을 추가했는지만 남긴다.

## sesh

`chezmoi/dot_tmux.conf.local`에서 `prefix + Shift+t`로 내장 선택기를 연다.

```tmux
bind-key T display-popup -h 90% -w 70% -E "sesh picker -i"
```

기존 tmux 세션, zoxide 디렉터리 이력, sesh에 등록한 세션을 검색해 선택한다.
기존 세션은 전환하고, 세션이 없는 디렉터리는 새 세션을 만든다.
별도 시작 명령 없이 새 세션은 해당 디렉터리의 셸 하나로 시작한다.

## tmux-fzf

### 설치·키 소유권

`chezmoi/dot_tmux.conf.local`에서 OMT의 TPM 연동으로 설치한다.

```tmux
set -g @plugin 'sainnhe/tmux-fzf'
```

tmux-fzf의 기본 `prefix + F`를 그대로 사용한다. OMT 본체가 정의한
PathPicker 바인딩은 이후 로드되는 tmux-fzf가 덮어쓴다. 별도 중복 바인딩이나
수동 TPM 초기화는 추가하지 않는다.

사용하지 않는 PathPicker의 `fpp` 패키지 선언과 `FPP_EDITOR` 설정은 제거했다.
이미 실행 중인 서버를 전환할 때는 남아 있는 `FPP_EDITOR` 환경도 해제한다.

현재 역할 분담:

- `prefix + F`: tmux-fzf로 세션·윈도우·pane·명령·키 바인딩·tmux 버퍼 관리.
- `prefix + Tab`: 기존 extrakto로 화면·Scrollback 텍스트 추출.
- 프로젝트 디렉터리 기반 세션 생성·전환: 기존 sesh 설정 유지.

시스템 클립보드 이력을 위한 CopyQ나 프로세스 트리를 위한 pstree는 선택
의존성이므로 추가 설치하지 않는다. CopyQ가 없으면 tmux 버퍼를 사용한다.

## tmux-sessionx

`chezmoi/dot_tmux.conf.local`에서 OMT의 TPM 연동으로 설치한다.

```tmux
set -g @plugin 'omerxx/tmux-sessionx'
```

추가 옵션 없이 기본 `prefix + O` (`Shift+o`)로 세션·윈도우 검색과
미리보기를 연다. 기존 `prefix + o`의 다음 pane 이동은 유지한다.
필수 의존성인 fzf (`fzf-tmux` 포함)와 bat은 기존 Brewfile 선언을 사용한다.
zoxide 자동 경로 매칭 옵션은 기본값인 off로 두며, 프로젝트 진입용 sesh와
전체 tmux 객체 관리용 tmux-fzf도 그대로 유지한다.

## tmux-open

`chezmoi/dot_tmux.conf.local`에서 OMT의 TPM 연동으로 설치한다.

```tmux
set -g @open-editor-command 'nvim'
set -g @open-S 'https://www.google.com/search?q='
set -g @plugin 'tmux-plugins/tmux-open'
```

Copy Mode에서 선택한 텍스트에 다음 동작을 적용한다.

| 키 | 현재 설정 |
|---|---|
| `o` | macOS `open`으로 파일·URL을 기본 앱에서 열기 |
| `Ctrl+o` | Neovim으로 파일 열기 |
| `Shift+s` | 선택 문구를 Google에서 검색 |

vi Copy Mode의 기본 `o`(`other-end`)는 사용하지 않으므로 의도적으로
덮어쓴다. tmux 서버의 `$EDITOR` 유무와 관계없이 Neovim을 사용하도록
`@open-editor-command`를 지정한다. 검색 바인딩도 `@open-S`로 명시한다.

`Ctrl+o`는 원래 pane에 `nvim -- "선택한 경로"`와 Enter를 보내므로
셸 프롬프트에서 사용한다. 실행 중인 다른 프로그램에 명령을 보내지 않도록
주의한다. 웹 검색 전에 선택 문구에 토큰·개인정보가 없는지도 확인한다.
기존 extrakto의 `prefix + Tab`과 tmux-fzf의 `prefix + F`는 유지한다.

## tmux Copy Mode 커스텀 키

커스텀 바인딩은 독립 플러그인
[`tmux-vim-copy`](https://github.com/clang-engineer/tmux-vim-copy)에서 관리한다.
`chezmoi/dot_tmux.conf.local`에서 tmux-open 뒤에 TPM 플러그인으로 선언한다.

```tmux
set -g @plugin 'clang-engineer/tmux-vim-copy'
```

기존 `~/.config/tmux/keybindings.conf` 복사본과 `source-file`은 제거한다.
tmux 3.7+와 Python 3.9+가 필요하며, 별도 뷰어 대신 기존 Copy Mode를 쓴다.
`v`·`V`·`Ctrl+v` 선택 전환, `i`/`a` 텍스트 오브젝트, `y`/`yy`, `gg`·`ge`·`gE`,
`zt`·`zz`·`zb`를 제공한다. 지원 키는
[tmux cheatsheet](https://github.com/clang-engineer/devkit/blob/main/reference/cheatsheets/tmux.md)에 정리한다.

`o`·`Ctrl+o`·`Shift+s`는 tmux-open에 남겨두고, 선택 끝 교환에는 기본 `O`를
쓴다. 기본 복사 정책은 복사 후 Copy Mode 종료이며,
`@vim-copy-yank-exit off`로 선택·Copy Mode를 유지할 수 있다.
숫자 반복은 기존 tmux 이동 키에서 유지되고, 새 helper 동작의 숫자 접두사는
지원하지 않는다. `g`·`z`는 접두사이므로 기존 단일 키 동작은 `gg`·`zz`로 쓴다.

괄호는 중첩·여러 줄·터미널 폭 줄바꿈을 처리한다. 따옴표는 논리적인 한 줄에서
찾는다. 프로그래밍 언어 문법을 해석하지 않으며, 복합 emoji가 있는 줄의
helper 선택은 오류 메시지와 함께 기존 선택을 유지한다.

## Atuin

### 설치

`packages/Brewfile`:

```ruby
brew "atuin"
```

### 추가 셋업

`chezmoi/dot_zshrc.tmpl`에서 fzf를 먼저 초기화한 뒤 Atuin을 초기화한다.

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
```

Atuin sync는 현재 필수 설정이 아니다. 동기화를 켜기 전에는 command argument에
secret/token이 기록될 수 있으므로 history filtering 정책을 먼저 검토한다.

## Yazi

### 설치

macOS/Linux의 `packages/Brewfile`:

```ruby
brew "yazi"
```

Windows의 `packages/scoop-packages.txt`:

```text
yazi
```

### 추가 셋업

기본 실행 명령은 `yazi`다. `chezmoi/dot_zshrc.tmpl`, `chezmoi/dot_bashrc.tmpl`,
`chezmoi/Documents/PowerShell/profile.ps1.tmpl`에는 각각 `y` wrapper를 두어 Yazi
종료 시 마지막 디렉터리를 현재 shell cwd로 넘긴다.
Windows Git Bash에서는 native `mise activate bash`가 세미콜론 구분 `PATH`를
내보내므로 `.bashrc`가 mise shims를 직접 추가한다.

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

## AeroSpace + JankyBorders

### 운영 원칙

AeroSpace는 주력 앱만 workspace에 자동 배치하고, 이 앱들은 AeroSpace 기본 tiling
동작을 그대로 사용한다. 그 외 미지정 앱은 catch-all 규칙으로 floating 처리한다.

```text
1: Browser   -> Chrome / Safari / Claude / ChatGPT : tiling
2: Terminal  -> Ghostty                            : tiling
3: Company   -> Teams / Outlook                    : tiling
4: JetBrains -> IntelliJ / DataGrip                : tiling
그 외 앱                                              : floating
```

`Alt-H/J/K/L`의 `focus`는 tiled 창 안에서만 이동하는 키가 아니라 현재 workspace의
창 포커스를 방향 기준으로 이동하며, tiled와 floating 창 사이도 이동할 수 있다.

Chrome DevTools를 별도 창으로 분리한 경우에는 일반 Chrome과 같은 app-id를 사용하므로
window title에 `DevTools`가 포함된 창만 floating 예외로 둔다. 일반 Chrome 창은 계속
tiling을 유지한다.

### JankyBorders

AeroSpace tiling에서 현재 focus 창을 더 쉽게 식별하기 위해 JankyBorders를 사용한다.
`packages/Brewfile`에서 `FelixKratz/formulae`의 `borders` formula를 설치하고,
Homebrew의 third-party tap trust 정책 때문에 해당 formula만 명시적으로 trust한다.

AeroSpace의 `after-startup-command`에서 GUI PATH 문제를 피하기 위해 Homebrew 절대
경로로 실행한다. 현재 스타일은 JankyBorders 공식 README 예시값을 그대로 사용한다.

```text
active_color   = 0xffe1e3e4
inactive_color = 0xff494d64
width          = 5.0
```

`after-startup-command`는 `aerospace reload-config` 시 다시 실행되지 않고 AeroSpace
프로세스가 실제로 시작될 때만 실행된다. 실행 여부는 다음처럼 확인할 수 있다.

```bash
ps aux | grep -i '[b]orders'
```

## Global Git quality hook + prek

### 설치

`packages/Brewfile`에서 공통 검사 도구를 설치한다.

```ruby
brew "shellcheck"
brew "shfmt"
brew "stylua"
brew "prek"
```

### 전역 hook

`chezmoi/dot_gitconfig.tmpl`에서 Git의 전역 hook 경로를 지정한다.

```ini
[core]
    hooksPath = ~/.config/git/hooks
```

chezmoi가 `~/.config/git/hooks/pre-commit`을 관리한다. 이 hook 자체에는 검사 로직을
넣지 않고, 공통 prek config를 호출하는 얇은 진입점으로 유지한다.

```bash
prek run --config "$HOME/.config/prek/global.yaml"
```

공통 검사 정의는 `chezmoi/dot_config/prek/global.yaml.tmpl`에 둔다.

```text
Shell -> ShellCheck + shfmt --diff
Lua   -> Stylua --check
```

`typos-cli`는 수동 검사 도구로 설치하지만 전역 hook에는 등록하지 않는다.
Lua 포맷은 Neovim과 Hammerspoon 각각의 `stylua.toml`에서 2칸 들여쓰기를 지정한다.

즉 검사 종류나 옵션을 바꿀 때는 hook shell script가 아니라 global prek config만
수정하면 된다.

### repository별 확장

전역 hook은 공통 최소 검사만 담당한다. repository 루트에
`.pre-commit-config.yaml`이 있으면 같은 hook이 이어서:

```bash
prek run
```

을 실행한다. Java/Node/Python 등 프로젝트별 lint/test는 각 repository의 config에
두고, 전역 검사와 중복되는 hook은 넣지 않는 것을 원칙으로 한다.

```text
git commit
  -> ~/.config/git/hooks/pre-commit
       -> ~/.config/prek/global.yaml
       -> .pre-commit-config.yaml 있음?
            -> repo 전용 prek run
```

별도로 각 repository에서 `prek install`을 할 필요는 없다.

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
