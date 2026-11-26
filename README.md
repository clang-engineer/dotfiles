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
| `nvim/` | Neovim — `lazy/` LazyVim → `~/.config/nvim` |
| `hammerspoon/` | macOS automation — symlinked to `~/.hammerspoon` |
| `packages/` | package manifests — Brewfile (macOS/Linux), casks (macOS), Scoop (Windows) |
| `scripts/` | tooling: key generation, workspace identity, and Windows installers |
| `tools/harlequin-config/` | [Go Harlequin configuration generator](tools/harlequin-config/README.md) — use native `harlequin -P` profile completion |
| `vim/` | legacy Vim config snapshots (not linked; kept for reference) |

Ghostty is managed in `chezmoi/dot_config/ghostty/config.tmpl`; available fonts are
installed via `packages/Brewfile.cask`. See [Terminal fonts](TERMINAL-FONTS.md)
for the current font stack, Korean glyph mapping, alternatives, and switching.

Zsh is the reference for the Bash, Zsh, and Fish interactive environment.
`chezmoi/.chezmoidata/shell.yaml` contains only shared values: command aliases
(`cat`/`ls`), the C++ standard, environment variables, local/SSH editors, and the
Harlequin/Vertica config paths. Bash, Zsh, Fish, and the Windows PowerShell profile
render these values directly in their own startup templates. Edit the YAML, then
run `chezmoi apply`; do not edit generated home files to change shared values.

### Themes (macOS/Linux)

[`themeset`](https://github.com/clang-engineer/themeset) is an independent Go CLI, not a chezmoi wrapper.
Explicit user-registered per-tool ports take priority. Otherwise it selects an
installed native theme or fetches the current official/app-maintained theme file
over HTTPS. If none is available, it reports a
per-tool skip reason and preserves the application's previous settings.
Invalid user overrides fail rather than silently selecting other colors.
It never derives replacement colors from another application's palette.
A theme being listed does **not** promise that every tool supports it.

The CLI's curated default catalog includes Catppuccin Mocha, Dracula, Gruvbox,
Moonfly, Nord, Rosé Pine (Main), and Tokyo Night (Night), shared by `list`,
completion, and the picker. A listed theme need not support all 14 tools.
Additional theme IDs require an explicit entry under `themes` in the local JSON config.

Official theme files are fetched during `apply`; no theme assets are bundled.
fzf accepts all seven catalog themes. Catppuccin uses the Mauve accent; its fzf
options require fzf 0.52.0 or newer. Yazi imports style tables and the official
syntax theme while retaining local separators, icons, file rules, layouts, and
keymaps. Upstream source and licensing references live in themeset's notices.
Yazi Dracula, eza Dracula/Gruvbox Dark, btop Catppuccin/Dracula/Gruvbox
Dark/Nord, and Starship Catppuccin/Gruvbox Dark fetch current official sources.
Rosé Pine (Main) adds official assets for Starship, fzf, Delta, Atuin, lazygit,
btop, eza, and Yazi; Tokyo Night (Night) adds fzf, tmux (styles only), lazygit,
btop, eza, and Yazi. Unsupported targets are skipped without synthesizing colors.
Downloads happen on each apply, require network access, and are format-checked
before changing settings; dry-run does not download. Starship selects a palette
but cannot recolor hardcoded prompt styles. `paths.yazi`/`paths.eza` must match
the apps' actual config locations (including `YAZI_CONFIG_HOME`/`EZA_CONFIG_DIR` overrides).
These new recipes need a local source build until the next published release.

The published Homebrew package is declared in `packages/Brewfile`. Install it
directly, or let the normal Brewfile setup install it:

```sh
brew install clang-engineer/tap/themeset

# Review and install the dotfiles integration.
chezmoi diff
chezmoi apply
# Start a fresh login session to discard legacy BAT_THEME and Harlequin functions.

themeset list
themeset list tools
themeset apply dracula --dry-run
themeset apply dracula
themeset current
# Or select with a sourced preview, review the plan, and confirm:
themeset apply
```

`chezmoi/dot_config/themeset/create_config.json.tmpl` seeds
`~/.config/themeset/config.json` once. Its `tools` array declares the enabled
targets: Ghostty, Neovim, tmux, bat, delta, Harlequin, Starship, fzf, Yazi,
Atuin, lazygit, lazydocker, btop, and eza. Remove targets there to leave them
alone; `paths` overrides each adapter's native configuration destination.
Edit this **local JSON**, not the removed shared profile YAML, to configure the
CLI. Existing files with `create_` ownership are deliberately not reset by
later chezmoi applies. Config-directory environment overrides require matching
paths in this JSON and in the app's include/startup integration.

Ownership is split narrowly, so changing themes does not surrender management
of fonts, layouts, keymaps, or unrelated settings:

| Application | Theme ownership | Still managed by dotfiles |
| --- | --- | --- |
| Ghostty | `~/.config/themeset/ghostty.conf`, included last from its main config; create-only initial selector | Fonts, scrollback, official theme assets |
| Neovim | Optional `~/.config/themeset/neovim.lua`, loaded after Lazy setup | Symlinked config, installed providers, previous selection migrated once or default Dracula on fresh setups |
| tmux | Optional `~/.config/themeset/tmux.conf`, sourced **after** the upstream Oh my tmux! engine | Existing Dracula starting colors and status layout, plugins, keymaps; reload/edit bindings use the managed wrapper |
| delta | `~/.config/themeset/delta.gitconfig`, included last; create-only Dracula selector | Git behavior, delta navigation/layout, official Dracula feature |
| fzf | `~/.config/themeset/fzf.opts`; preserves previous color options or seeds official Dracula | Stable `FZF_DEFAULT_OPTS_FILE` in Bash/Zsh/Fish, independent picker options and commands |
| Starship | Existing `palette` selector and `palettes` tables survive the modify template | Prompt layout and module styles; official Dracula palette seeded only when missing |
| bat | Native `~/.config/bat/config`, create-only Dracula seed | No Unix `BAT_THEME` override |
| Harlequin | `profiles.<name>.theme` in the generated DB catalog, selected via `paths.harlequin` | Connection generator, keymaps, native profile completion; no forced `--theme` shell function |
| lazygit | Native `gui.theme` survives the modify template | Git diff renderers; macOS uses `~/Library/Application Support/lazygit/config.yml`, Linux uses `~/.config/lazygit/config.yml` |
| Yazi, Atuin, lazydocker, btop, eza | Native settings/assets belong to the app and themeset, not a palette generator | No theme selector or palette is reset by chezmoi |

The one-time `run_once_before_02-migrate-theme-selection.sh.tmpl` copies the old
Neovim selection into its new runtime-owned Lua file before obsolete-file cleanup.
It never overwrites an existing themeset script. Ghostty/fzf create-only seeds
also retain previous selections when migrating. No palette is generated.
Open a fresh terminal after applying the cutover, or explicitly `unset BAT_THEME`
in existing Unix shells: an inherited old export overrides bat's native config.

Harlequin reads an explicit `HARLEQUIN_CONFIG_PATH` first and selects whole
profiles by name. Therefore themeset targets the existing
`~/.config/db/harlequin.toml` catalog rather than a shadowed global theme.
`harlequin-config` preserves the selected theme of each surviving profile when
regenerating connection fields; newly added profiles start with Dracula.
Run `harlequin-config` to generate the catalog before applying themes on a fresh
setup. If you override `HARLEQUIN_CONFIG_PATH`, update `paths.harlequin` too.

To override a theme/tool pair, provide an actual app-native settings file and
register that specific override. For example, after installing a btop theme:

```json
{
  "themes": {
    "dracula": {
      "custom": {
        "btop": {
          "file": "~/.config/btop/themes/dracula.theme",
          "source": "https://draculatheme.com/btop"
        }
      }
    }
  }
}
```

Merge this entry into the existing config, keeping its `tools` and `paths`.
`file` must already exist and use that application's native format; it is not
a shared palette definition. `name` may select an existing native theme where
the adapter supports it, and `source` records provenance. Registered custom ports
take priority even when native/official support exists, without a fallback
warning. Missing or invalid override files fail visibly. In particular, tmux has
no general native theme registry: its existing Oh my tmux! Dracula layout stays
unchanged unless you register a real native tmux theme file. The CLI does not
generate Oh my tmux! color mappings or install the script-driven Dracula plugin.

The [official Dracula integrations](https://draculatheme.com/) for Ghostty,
fzf, Starship, and delta remain available; downloaded ports use current sources.
Neovim retains the official `dracula/vim` plugin and the other declared Lazy
theme providers. Install providers with Lazy before selecting them; the CLI
does not install editor plugins. Old generated palette assets already in a
home directory are left untouched, not silently deleted or used as automatic
fallbacks.

Starship takes effect on the next prompt; fzf, bat, delta, and eza on the next
invocation. Reopen Yazi, Atuin search, lazygit, lazydocker, and btop. Neovim loads
the optional native selection on its next launch; the old palette-file watcher
is gone. Ghostty may reload through its native integration; otherwise reload
the app manually. Native tmux custom configuration applies through its theme
include; separate tmux servers need their own reload.

The old `theme` executable, Fish completion, generated Neovim return-data file,
shared profile resolver, and palette adapters are removed. A subsequent
`chezmoi apply` removes those obsolete executable/integration files, but does
not revert themeset's native selections. Windows remains independently
configured and is not a supported themeset platform; its legacy PowerShell
`BAT_THEME` remains separate.

Other tools such as sesh, gh, ripgrep, fd, and tree use terminal/ANSI or their
existing picker colors. Shell syntax highlighting, OpenCode, Claude Code,
JankyBorders, and desktop GUI application themes remain independently managed.

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

The theme-only `~/.config/themeset/fzf.opts` is the stable
`FZF_DEFAULT_OPTS_FILE`, using `$XDG_CONFIG_HOME` when set. Its color flags apply
to plain fzf, Ctrl+T, and `rg.fzf`, without replacing picker key bindings,
headers, previews, or layout. The create-only seed uses the
[official Dracula fzf colors](https://draculatheme.com/fzf), including the
background; themeset owns subsequent changes.
Keep this options file comment-free: Fish's official integration joins file
lines with spaces before appending picker options, so a `#` comment would also
comment out Ctrl+T's options. The old shared generated `fzf/theme` is no longer
used.

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
