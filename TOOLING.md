# Tooling Integration Notes

이 문서는 `packages/Brewfile`에 패키지를 추가하는 것만으로 끝나지 않고,
**dotfiles에서 별도의 integration/setup을 추가한 도구**를 기록한다.

도구의 일반적인 사용법과 비교는 `clang-engineer/devkit`의 cheatsheet에 두고,
이 문서에는 이 저장소에서 실제로 어떤 설정을 추가했는지만 남긴다.

## sesh

`chezmoi/dot_tmux.conf.local.tmpl`에서 `prefix + Shift+t`로 내장 선택기를 연다.

```tmux
bind-key T display-popup -h 90% -w 70% -E "sesh picker -i"
```

기존 tmux 세션, zoxide 디렉터리 이력, sesh에 등록한 세션을 검색해 선택한다.
기존 세션은 전환하고, 세션이 없는 디렉터리는 새 세션을 만든다.
별도 시작 명령 없이 새 세션은 해당 디렉터리의 셸 하나로 시작한다.

## tmux-fingers

`chezmoi/dot_tmux.conf.local.tmpl`에서 OMT의 TPM 연동으로 설치한다.

```tmux
set -g @plugin 'Morantron/tmux-fingers'
```

기존 tmux-fzf를 대체한다. 기본 `prefix + F`로 현재 pane의 경로·SHA·IP 등에
문자 힌트를 표시하고, 힌트를 입력해 tmux 버퍼와 시스템 클립보드로 복사한다.
Shift와 함께 선택하면 붙여넣고, Escape로 취소한다. OMT의 PathPicker
바인딩은 이후 로드되는 fingers가 덮어쓰므로 별도 실행 바인딩은 추가하지 않는다.

점프 모드는 기본 `prefix + J`를 사용한다. 기존 pane 크기 조절 바인딩은
fingers의 점프 모드가 덮어쓴다.

macOS arm64에서는 `.chezmoiexternal.toml`이 공식 2.7.1 단독 바이너리를
SHA256 검증 후 `~/.local/bin/tmux-fingers`에 실행 파일로 설치한다.
Homebrew 소스 빌드의 Crystal/LLVM 의존성은 설치하지 않는다.
다른 플랫폼에서는 upstream의 최초 실행 설치 마법사를 사용한다.
플러그인 업데이트로 바이너리 버전이 바뀌면 이 외부 파일의 URL과 체크섬도 함께 갱신한다.

`prefix + Tab`의 extrakto는 화면·Scrollback 검색 추출용으로 유지하고,
프로젝트 디렉터리 기반 세션 생성·전환은 기존 sesh를 사용한다.

## tmux-sessionx

`chezmoi/dot_tmux.conf.local.tmpl`에서 OMT의 TPM 연동으로 설치한다.

```tmux
set -g @plugin 'omerxx/tmux-sessionx'
```

추가 옵션 없이 기본 `prefix + O` (`Shift+o`)로 세션·윈도우 검색과
미리보기를 연다. 기존 `prefix + o`의 다음 pane 이동은 유지한다.
필수 의존성인 fzf (`fzf-tmux` 포함)와 bat은 기존 Brewfile 선언을 사용한다.
zoxide 자동 경로 매칭 옵션은 기본값인 off로 두며, 프로젝트 진입용 sesh도
그대로 유지한다.

## tmux-open

`chezmoi/dot_tmux.conf.local.tmpl`에서 OMT의 TPM 연동으로 설치한다.

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
기존 extrakto의 `prefix + Tab`과 tmux-fingers의 `prefix + F`는 유지한다.

## tmux Copy Mode 커스텀 키

커스텀 바인딩은 독립 플러그인
[`tmux-vim-copy`](https://github.com/clang-engineer/tmux-vim-copy)에서 관리한다.
`chezmoi/dot_tmux.conf.local.tmpl`에서 tmux-open 뒤에 TPM 플러그인으로 선언한다.

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

### fzf 대신 사용하는 이유

fzf의 `Ctrl-R`은 셸 히스토리를 퍼지 검색하는 기능이고, Atuin은 명령 이력을
별도 SQLite DB에 저장하고 검색하는 도구다. 히스토리 검색에는 Atuin을 사용해
디렉터리·세션 등 실행 맥락으로 범위를 좁히고, 실행 시각·소요 시간·종료 코드도
함께 기록한다. 프로젝트별로 이전 명령을 다시 찾는 용도에 적합하다.

단순히 최근 명령을 문자열로 찾는 용도라면 fzf만으로도 충분하다. Atuin은 별도
초기화와 DB 관리가 추가되는 대신 히스토리 관리 기능을 제공한다.
fzf 자체를 대체하는 것은 아니며 파일·디렉터리 선택에는 계속 사용한다.

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

실행 명령은 `yazi`다. 별도의 `y` 단축 함수나 종료 시 셸 디렉터리 이동은 설정하지 않는다.
Windows Git Bash에서는 native `mise activate bash`가 세미콜론 구분 `PATH`를
내보내므로 `.bashrc`가 mise shims를 직접 추가한다.

따라서 사용 기준은 다음처럼 나눈다.

```text
목적지를 알고 있음       -> zoxide (`z`)
구조를 보면서 찾아야 함  -> Yazi (`yazi`)
```

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

## Themes (macOS/Linux)

[`Tinty`](https://github.com/tinted-theming/tinty) is the theme manager.
Use its native commands, not a dotfiles wrapper:

```sh
chezmoi diff
chezmoi apply
tinty sync
tinty apply base16-dracula
tinty current
```

`sync` downloads/updates the scheme catalog and official template repositories;
`apply` selects their prebuilt app themes and runs the configured hooks.
In Fish, `tinty apply ` and `tinty info ` complete available scheme IDs with
Tab. Shift+Tab opens a Base16 fzf list sorted by GitHub project Stars (Radar),
with a live `tinty info` color preview on the right. Enter inserts the selected
ID; Escape leaves the command unchanged. Tab retains Tinty's full native list,
including Base24 and Tinted8. The ranked picker requires `jq`; without it,
Shift+Tab retains standard fzf completion. Rankings refresh at most daily and
use the last cached values offline. Outside `apply` and `info`, Shift+Tab retains
Fish completion. Run `tinty sync` first to download the catalog. `tinty gallery`
opens a browser gallery for preview and application; it takes no scheme argument.

The managed configuration is
`chezmoi/dot_config/tinted-theming/tinty/config.toml.tmpl`. Edit that source to change
targets. Start with **Base16**: it is the common supported system
across these integrations. Base24 and Tinted8 are different palette systems,
not higher-quality versions, and not all configured targets support them.
Most targets use Tinted renditions, not the original app-specific
Dracula/Catppuccin palettes; native tmux ports are the exception.

| Application | Tinty integration |
| --- | --- |
| Ghostty | Native theme file; fonts and terminal behavior remain managed separately |
| Neovim | `tinted-vim` themes from Tinty's synced repository; new Neovim sessions read Tinty's current scheme |
| tmux | `tinted-tmux` colors plus theme-author statusbars where available; otherwise OMT layout with Tinty-driven ANSI colors |
| fzf | Generated `fzf.opts` read by Bash/Zsh/Fish through `FZF_DEFAULT_OPTS_FILE` |
| Yazi | Native `tinted-scheme` flavor; other theme settings, layout and keymaps are preserved |
| delta | Native theme written to `~/.config/delta/theme.gitconfig`, included by Git |
| lazygit | Official theme merged after native config through `LG_CONFIG_FILE`; explicit user overrides win |

After the first apply, open a new shell so the lazygit merge environment and
`FZF_DEFAULT_OPTS_FILE` are refreshed. Later fzf/delta invocations read the new
theme directly; reopen lazygit, Yazi, and Neovim. A new Neovim session reads
Tinty's current scheme from its data directory and loads the matching `tinted-vim`
colorscheme. Open sessions keep their existing theme.
Ghostty reloads automatically via SIGUSR2. For tmux, `tinty apply` resets the
running server to OMT, then applies Tinty colors and any matching native
statusbar. The same order runs on tmux startup/reload, so a previous statusbar
cannot leak into the next theme.

Native tmux ports installed by `chezmoi apply`: Catppuccin (four flavors),
Rosé Pine (main, moon, dawn), Dracula, Nord, Gruvbox (dark/light), Everforest
(dark/light hard, medium, soft; unqualified Everforest uses dark-medium),
Tomorrow (default/night/eighties), and the first-party Nightfox variants
(Nightfox, Carbonfox, Dawnfox, Dayfox, Duskfox, Nordfox, Terafox).
These trusted upstream tmux configs may execute shell code; Catppuccin is pinned
to v2.3.2. Matching Base16 and Base24 IDs use the same native tmux port.
Other schemes retain OMT's status layout, with Tinty colors from Ghostty and
`tinted-tmux`. Native plugin palettes may differ from Tinted renditions in
other apps.

The GitHub Stars ranking measures scheme popularity, not native tmux support.
For example, Solarized's dedicated tmux port only changes colors, so it
uses OMT's status layout instead of masquerading as a native statusbar.

Choosing a Base24 scheme does not update the Base16-only Yazi and lazygit targets.
For a consistent theme across these integrations, select a `base16-…` scheme.

After changing Tinty items, run `tinty sync` and `tinty apply <scheme-id>`.

Chezmoi places app configs under its usual home-directory targets. If you
override `XDG_CONFIG_HOME` or `YAZI_CONFIG_HOME`, use the same location for Yazi's
config. Tinty's Yazi hook selects the `tinted-scheme`
flavor in `theme.toml` while preserving unrelated settings. Run `tinty apply`
before opening Yazi on a fresh install to create its flavor file.

Other apps keep their own native settings, not a Tinty hook. Chezmoi selects
bat's `base16-256` theme on new installs and replaces a previous Dracula selection
without discarding other bat options; its ANSI colors follow the terminal.
Starship uses its own local config (or defaults); its ANSI color names also follow the
terminal when no named palette is selected. Chezmoi no longer manages the
Starship prompt. Atuin, btop, eza, lazydocker, and Harlequin do not
automatically follow new Tinty selections. An explicit `BAT_THEME` export
takes precedence over bat's native config.

The former themeset runtime is not used. The native tmux provider mapping
is managed under `chezmoi/dot_config/tinted-theming/tinty/hooks/tmux/`; managed upstream
plugins live under `~/.config/tmux/plugins`. Existing themeset files are left
untouched but are no longer loaded.
Delta and fzf use Tinty's generated themes after `tinty sync` and `tinty apply`;
there are no separate bundled themes or first-run seeds. Windows remains
independently configured. Shell syntax highlighting, OpenCode, Claude Code,
JankyBorders and desktop GUI application themes remain independently managed.

## fzf and shell integration

`chezmoi/.chezmoidata/fzf.yaml` is the single source for Bash/Zsh/Fish fzf
settings. `fileCommand` uses `fd --type f --exclude .git` for both plain
fzf and Ctrl+T: only non-hidden, non-ignored files are listed. `.git`
directories are excluded and fd's default ignore rules (including `.gitignore`)
still apply. Fish Ctrl+T also searches from the directory parsed from the current
token. Piped input bypasses this command.

In the Ctrl+T file picker, Shift-H toggles hidden files and Shift-I toggles
ignored files independently. The prompt shows both states; each key reloads
the list while retaining the current query. The Fish widget retains its parsed
search directory on reload. These bindings do not affect piped fzf input or
the separate `rg.fzf` content-search picker.

On macOS, Ctrl+Y copies the selected file's absolute path, shows confirmation
on the fzf header border for two seconds, then restores its `FILES` label
without closing the picker. Repeated copies restart the timer.

`ctrlT` holds common picker options; `ctrlTByOS` adds options for the chezmoi
target OS. `ctrlTHeader` and `ctrlTHeaderByOS` provide the shared multiline header
and platform-specific help. Each shell template renders these values before initializing fzf;
there is no runtime config loader. Edit the YAML and run `chezmoi apply` to update
the generated shell files.

Zsh uses Homebrew's `fzf-tab` for general Tab completion, including command
options, paths, and Harlequin profiles. It loads after `compinit` and fzf's shell
integration, before autosuggestions and syntax highlighting. Ctrl+T remains the
fzf file picker; Ctrl+R remains Atuin. After applying `~/.zshrc`, open a new Zsh
session (`exec zsh`) to load the completion settings.

Tinty writes fzf's theme-only `fzf.opts` to
`~/.config/tinted-theming/tinty/generated/`; Bash/Zsh/Fish read it through
`FZF_DEFAULT_OPTS_FILE`. Its color flags apply to plain fzf, Ctrl+T, and
`rg.fzf`, without replacing picker key bindings, headers, previews, or layout.
The file appears after the first `tinty apply`; until then fzf uses its defaults.

Inside tmux, Ctrl+H/J/K/L moves between panes even while a shell fzf picker is
open. `@vim_navigator_pattern` excludes fzf from Vim detection; Vim/Neovim
retain their integrated split navigation. Use arrow keys to navigate fzf results.

Startup logic stays explicit in each shell file: Homebrew/secrets loading, tool
initialization, tmux, Zsh completion/plugins, Fish key bindings, and Git Bash's
Scoop/mise shims. A little duplication is intentional; there is no cross-shell
initialization dispatcher or shared tool list. Bash/Zsh/Fish initialize
mise → fzf → Atuin → zoxide → Starship, use Emacs editing, and auto-attach tmux
outside existing tmux sessions and JetBrains terminals. Noninteractive Bash/Fish
startup skips interactive tools. Fish uses built-in suggestions/highlighting.
Harlequin completion remains Zsh/Fish-specific.
Bash, Zsh, and Fish Ctrl+T file pickers use `--no-height` to fill the current
terminal pane, with a hidden-by-default right-side 50% `bat` preview with line numbers.
Like `rg.fzf`, Ctrl+T uses the default bottom-input layout, a bordered multiline
query/help header without bold/dim escape codes, and a border separating the preview.
Picker help is in English; both pickers use a standalone query title, a single
action-help row, and a macOS-only absolute-path copy hint.
Fish reconstructs the header with a startup action so its shell integration
cannot flatten embedded newlines while collecting default options.
Ctrl+/ toggles the preview on and off; Ctrl+Down shows it below at 40%, and
Ctrl+Right shows it on the right at 50%. `/` remains available for search.
Enter inserts selected paths into the command line; Ctrl+O opens a file in
`$EDITOR` (Vim if unset) and returns to the picker when the editor exits.
On macOS, disable conflicting Mission Control shortcuts to let Ctrl+arrow reach fzf.
On macOS, Ctrl+Y copies the focused file's absolute path via `realpath` and
`pbcopy` without closing the Ctrl+T picker. There is no custom Alt+Y binding.
The copy binding and its header are omitted on Linux and Windows.

For interactive file-content search, press Ctrl+F in Zsh/Fish, or run
`rg.fzf [QUERY]` from a project directory. In Zsh/Fish, Ctrl+F replaces Emacs
forward-character editing when `rg.fzf` is installed; the right arrow remains
available. Bash keeps its standard Ctrl+F cursor movement and has no custom
content-picker insertion binding; `rg.fzf` remains available as a command.
Chezmoi installs `chezmoi/dot_local/bin/executable_rg.fzf` to `~/.local/bin/rg.fzf`
on macOS/Linux. The managed script is adapted from a
[pinned upstream revision](https://github.com/junegunn/everything.fzf/blob/77edfb6e763281efb09d0d0aa925822ec64d7426/rg.fzf),
with its license retained. It requires Bash, fzf, ripgrep, and bat.
Content search includes hidden files and directories, excludes `.git`, and
continues to respect ripgrep's default ignore rules, including `.gitignore`.
Type `pattern / filter` to search contents with rg and narrow the results with fzf
(for example, `rg.fzf 'handleLogin / .ts:'`). Enter returns selected file paths,
without line numbers or matched text; the Ctrl+F shell binding inserts them
with shell escaping. Multiple matches in the same file yield one path.
Ctrl+O opens the matching file and line in `$EDITOR` (Vim if unset) without
exiting the picker. Tab selects multiple results; Vim/Neovim receive multiple
matches as a quickfix list when opened with Ctrl+O.
On macOS, Ctrl+Y copies the focused file's absolute path, then closes without
inserting. Ctrl+T uses the same key but keeps its picker open; Alt+Y has no custom binding.
The picker fills the current terminal pane, including inside tmux, without a popup.
The preview starts visible on the right at 50%, with matching-line highlighting
and scrolling. Ctrl+/ toggles it; Ctrl+Down shows it below at 40%, and Ctrl+Right
shows it on the right at 50%, matching the Ctrl+T preview controls.
Ctrl+F preserves existing command text, inserts accepted file paths at the
cursor, and leaves the command line unchanged on cancellation or clipboard copy.
Ctrl+T and Alt+C retain their file selection and directory navigation roles.
When run directly, `rg.fzf` prints one path per line; `rg.fzf --print0 [QUERY]`
prints NUL-delimited paths for shell integration.

## PowerShell and tmux shell selection

`chezmoi/Documents/PowerShell/profile.ps1.tmpl` uses the same shared values while
keeping native PSReadLine/PSFzf, Scoop, and `.secrets.ps1` handling. Command aliases
map one name to one executable; C++ flags use native wrapper functions because
PowerShell aliases cannot carry arguments. Windows tool integrations remain
independent rather than imitating Unix initialization. DB paths are used only when
the files exist, with existing environment values taking precedence.
Compiler wrappers preserve piped source input as well as ordinary file arguments.
`scripts/windows/test-shell-profile.ps1` checks both paths and compiler failure
status; it requires PowerShell 7, chezmoi, and `g++.exe` or `clang++.exe` on PATH.

See [shell setup](SETUP.md#fish-interactive-shell) for trying Fish and selecting a
login shell; chezmoi does not change the account shell.

Tmux explicitly starts new windows and panes with `/opt/homebrew/bin/fish`,
independent of the account login shell. This Apple Silicon Homebrew path is set
in `chezmoi/dot_tmux.conf.local.tmpl`; adjust it when using another installation path.

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
