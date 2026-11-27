# Dotfiles

My personal environment, managed with [chezmoi](https://chezmoi.io). On a fresh
machine `chezmoi apply` links every config, runs the one-time installs, generates
machine-local bits, and installs public packages in one command on macOS, Linux,
and Windows. The private `secrets` companion has a separate bootstrap.

## Design principle

**Do not add personal customization when a default or widely adopted standard
already solves the problem.** Prefer, in order:

1. built-in/default behavior
2. official or widely adopted integration/plugin
3. minimal configuration
4. custom scripts/keymaps only when the above are insufficient

Custom configuration should have a concrete reason to exist. Avoid duplicating a
tool's defaults, introducing new keybindings without a clear benefit, or keeping
integration layers that are no longer used.

> The previous shell / `bootstrap.sh` version (symlink-based) is preserved at the
> **`pre-chezmoi`** git tag — restore with `git checkout pre-chezmoi`.

## Quick start

**macOS / Linux**

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
brew install chezmoi
git clone <repo> ~/dotfiles

# one-time: generate ~/.config/chezmoi/chezmoi.toml — prompts once for your
# git name/email and derives sourceDir from where you cloned (~ is expanded)
chezmoi init --source ~/dotfiles

chezmoi apply
```

**Windows (PowerShell)** — _scaffolded, verify on a real machine_

```powershell
# Enable Windows Developer Mode first (required for the Neovim symlink).
winget install Git.Git twpayne.chezmoi
# clone, then `chezmoi init --source <path>` (prompts, writes chezmoi.toml), then:
chezmoi apply
```

- Setup walkthrough — including secret handling (SSH keys, `~/.secrets`, identity): [SETUP.md](SETUP.md)
- Tool and plugin review: [RECOMMENDATIONS.md](RECOMMENDATIONS.md)

## How it works

The chezmoi source lives in `chezmoi/` (a home-mirror tree). `chezmoi apply`
turns it into your home directory:

| chezmoi source | becomes | kind |
|---|---|---|
| `dot_zshrc.tmpl`, `dot_bashrc.tmpl`, `dot_gitconfig.tmpl`, `dot_tmux.conf`, … | `~/.zshrc`, `~/.bashrc`, `~/.gitconfig`, … | **managed file** (copy/render) |
| `dot_config/fish/` | `~/.config/fish/` | managed fish startup, functions, and completions |
| `private_dot_ssh/` | `~/.ssh/` (0700) | managed files; keys stay per-machine |
| `dot_config/symlink_nvim.tmpl` | `~/.config/nvim` → `nvim/lazy` | **symlink** |
| `symlink_dot_hammerspoon.tmpl` | `~/.hammerspoon` → `hammerspoon/` | symlink |
| `symlink_dot_sops.yaml.tmpl` | `~/.sops.yaml` → `sops/.sops.yaml` | symlink; public age recipient rules, private identity stays outside Git |
| `dot_claude/` | selected files in `~/.claude/` | managed files |
| `run_once_*` / `run_onchange_*` | packages, TPM plugins, and mise runtimes | scripts |

**Managed vs symlink:** big, live-edited config directories (`nvim/`,
`hammerspoon/`) stay as their own folders and are symlinked. Claude's runtime
directory stays local while chezmoi manages only its public config files. Everything
else is a managed file; edit with `chezmoi edit --apply ~/.zshrc`.

## Layout

| Folder | What |
|---|---|
| `chezmoi/` | chezmoi source — managed dotfiles, OS-branched via `.chezmoiignore.tmpl` |
| `chezmoi/dot_local/bin/executable_repos` | `~/.local/bin/repos` — sync configured Git repositories or repositories directly under a chosen directory |
| `nvim/` | Neovim — `lazy/` LazyVim → `~/.config/nvim` |
| `hammerspoon/` | macOS automation — symlinked to `~/.hammerspoon` |
| `packages/` | package manifests — Brewfile (macOS/Linux), casks (macOS), Scoop (Windows) |
| `scripts/` | tooling: key generation, workspace identity, and Windows installers |
| `tools/harlequin-config/` | [Go Harlequin configuration generator](tools/harlequin-config/README.md) — use native `harlequin -P` profile completion |
| `vim/` | legacy Vim config snapshots (not linked; kept for reference) |

### SOPS public recipient

`sops/.sops.yaml` contains the public age recipient used for new SOPS files.
`chezmoi apply ~/.sops.yaml` links it into the home directory; SOPS discovers
it automatically from projects under `$HOME`. Keep age private keys outside Git.

Ghostty is managed in `chezmoi/dot_config/ghostty/config`; available fonts are
installed via `packages/Brewfile.cask`. See [Terminal fonts](TERMINAL-FONTS.md)
for the current font stack, Korean glyph mapping, alternatives, and switching.
Ghostty extends the bottom tmux status-row colors into leftover window pixels;
vertical padding is disabled. Open a new Ghostty tab after changing padding
settings, since existing terminals retain their prior padding.

Zsh is the reference for the Bash, Zsh, and Fish interactive environment.
`chezmoi/.chezmoidata/shell.yaml` contains only shared values: command aliases
(`cat`/`ls`), the C++ standard, environment variables, local/SSH editors, and the
Harlequin/Vertica config paths. Bash, Zsh, Fish, and the Windows PowerShell profile
render these values directly in their own startup templates. Edit the YAML, then
run `chezmoi apply`; do not edit generated home files to change shared values.

### Repository sync

`repos` is installed by `chezmoi apply`. Configure the default repository list in
`${XDG_CONFIG_HOME:-$HOME/.config}/repos/config`, a **trusted Bash file** sourced
by the command:

```bash
repo "$HOME/projects/site" "git@github.com:you/site.git"
repo "$HOME/projects/docs" "https://github.com/you/docs.git"
```

Each `repo` entry supplies a local path and its clone URL. No account, host, or
repository paths are built into the executable. The private `secrets` repository
provides this machine's list via its `setup.sh`; other users can create their own
config file. Only source a config file you trust.

```bash
repos clone                      # clone missing configured repositories
repos pull                       # fast-forward configured repositories
repos push                       # push configured repositories ahead of upstream
repos pull --workspace           # configured list plus $WORKSPACE_DIR's direct children
repos pull .                     # repositories immediately under the current directory
repos push "$HOME/projects"      # repositories immediately under this path
```

The path form needs no config. `clone`, the default pull/push, and `--workspace`
require at least one configured entry; `--workspace` additionally needs
`WORKSPACE_DIR`. A missing config is an error, not a silent no-op.

Failed pulls include a Git diagnostic in the summary (or the exit status if Git
prints nothing). Local-only repositories without a remote cannot be pulled; add
a remote and upstream branch when they are ready to sync.

### Themes (macOS/Linux)

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
lives in `chezmoi/dot_local/bin/executable_tinty-tmux-theme`; managed upstream
plugins live under `~/.config/tmux/plugins`. Existing themeset files are left
untouched but are no longer loaded.
Delta and fzf use Tinty's generated themes after `tinty sync` and `tinty apply`;
there are no separate bundled themes or first-run seeds. Windows remains
independently configured. Shell syntax highlighting, OpenCode, Claude Code,
JankyBorders and desktop GUI application themes remain independently managed.

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
`pbcopy`, then closes without inserting. There is no custom Alt+Y binding.
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
inserting. This copy key matches Ctrl+T; Alt+Y has no custom binding.
The picker fills the current terminal pane, including inside tmux, without a popup.
The preview starts visible on the right at 50%, with matching-line highlighting
and scrolling. Ctrl+/ toggles it; Ctrl+Down shows it below at 40%, and Ctrl+Right
shows it on the right at 50%, matching the Ctrl+T preview controls.
Ctrl+F preserves existing command text, inserts accepted file paths at the
cursor, and leaves the command line unchanged on cancellation or clipboard copy.
Ctrl+T and Alt+C retain their file selection and directory navigation roles.
When run directly, `rg.fzf` prints one path per line; `rg.fzf --print0 [QUERY]`
prints NUL-delimited paths for shell integration.

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

## Cross-platform

`chezmoi/.chezmoiignore.tmpl` branches by OS. Linux skips macOS-only AeroSpace,
Hammerspoon, and casks. Windows uses AppData for Neovim, installs shared CLI tools
with Scoop, and manages Git Bash startup files alongside a PowerShell 7 all-hosts
profile. The Harlequin config generator is macOS/Linux-only; its build hook and wrapper are
excluded on Windows. Terminal appearance remains host-specific. **Windows is
scaffolded and must still be verified on a real machine after the migration.**

## Git identity and GitHub accounts

GitHub authentication and commit identity are separate concerns:

```text
SSH Host alias + IdentityFile
→ which GitHub account is used for fetch/push

Git includeIf + workspace config
→ which user.name / user.email is written into commits
```

The shared `~/.gitconfig` is rendered from `dot_gitconfig.tmpl` and includes the
machine-local `~/.gitconfig.local`. Default identity is created once during
`chezmoi init`; workspace-specific identity can be added with
`scripts/add-workspace-user.sh`. SSH host aliases live under `~/.ssh/config.d/`,
while private keys and real host entries stay outside this public repo.

## Secrets

Nothing private lives in this repo. `chezmoi apply` installs only the public config.
Personal agent instructions and skills belong to the private companion; its
`setup.sh` links shared instructions and supplemental docs into Pi's agent directory.
Pi settings and package declarations remain managed here.
OMP's `~/.omp/agent/config.yml` is partially managed by
`chezmoi/private_dot_omp/private_agent/modify_private_config.yml`: apply enforces
`defaultThinkingLevel: auto`, text thinking-level labels, the built-in
`dark-catppuccin` dark theme, and role-specific effort (`smol: "@default:low"`,
`slow`/`plan: "@default:high"`) while preserving the machine-local default model
and light theme. Role aliases follow the default model without
pinning another provider or model. Authentication databases, sessions, and caches
stay unmanaged. See the official [model-role docs](https://omp.sh/docs/roles) and
[alias/effort rules](https://github.com/can1357/oh-my-pi/blob/main/docs/models.md).
Thinking-level meanings and controls are documented in the
[OMP cheatsheet](https://github.com/clang-engineer/devkit/blob/main/reference/cheatsheets/omp.md#추론-강도).
After applying, restart OMP; an existing session may retain its saved thinking level.
The `modify_` source is a chezmoi Go template, not raw YAML; the repository's
YAML syntax hook excludes chezmoi modify scripts.
The private `secrets` companion (real SSH hosts and Harlequin connection sources) owns
its own bootstrap — clone it and run its `./setup.sh`; see that repo's README for the
command. Public clones simply skip it. See [SETUP.md](SETUP.md#9-security).

> Comments inside the config files are in Korean, but the configs themselves are
> language-agnostic — the setup works the same regardless.

## Verify tmux local changes against upstream

- Use this when you want to check whether the rendered `dot_tmux.conf.local.tmpl`
  has drifted from upstream OMT defaults.

```zsh
git diff --no-index --color=always \
  <(curl -fsSL 'https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local') \
  <(chezmoi cat ~/.tmux.conf.local)
```

- If you only want to compare the currently applied file with upstream:

```zsh
git diff --no-index --color=always \
  <(curl -fsSL 'https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local') \
  ~/.tmux.conf.local
```

- No output means the files match.
- `git diff --no-index` exits with status `1` when differences are found, which is
  expected and does not indicate command failure.

- If you want to force `delta` even when your shell decides to suppress pager
  output (eg. inside pipes), use:

```zsh
git diff --no-index --color=always \
  <(curl -fsSL 'https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local') \
  <(chezmoi cat ~/.tmux.conf.local) \
  | delta
```

- If you want a plain change summary only:

```python
import urllib.request
import difflib
import subprocess
from pathlib import Path

upstream_url = 'https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local'
up = urllib.request.urlopen(upstream_url).read().decode().splitlines()
local = subprocess.check_output(
    ['chezmoi', 'cat', str(Path.home() / '.tmux.conf.local')],
    text=True,
).splitlines()

diff_lines = list(difflib.unified_diff(up, local, lineterm=''))
print('added', sum(1 for l in diff_lines if l.startswith('+') and not l.startswith('+++')))
print('removed', sum(1 for l in diff_lines if l.startswith('-') and not l.startswith('---')))
```
