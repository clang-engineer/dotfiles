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

`chezmoi/.chezmoidata/themes.yaml` holds the independent, per-tool theme choices
used by the default `custom` profile. Shared profiles can override Ghostty,
Neovim, and tmux together; all other tools retain their independent settings.
Chezmoi renders the native configs. The custom defaults select Dracula. Ghostty, fzf, Starship, and
delta use their [official Dracula integrations](https://draculatheme.com/), with
pinned upstream sources and licenses beside the managed assets. Neovim uses
the official `dracula/vim` plugin; bat and Harlequin use their built-in Dracula themes.
`themes.delta.syntax` chooses syntax highlighting; `themes.delta.feature` selects
the included delta feature. For tmux, `themes.tmux.colours` adapts the official
Dracula colors to the 17 Oh my tmux! palette slots. It does not install the Dracula
tmux plugin or replace the existing status layout.
Neovim's symlinked config reads a small generated `dotfiles/theme.lua` beside its
config directory, so GUI launches do not depend on shell environment variables.
The source plugin declarations still determine which Neovim themes are installed.
Bash/Zsh/Fish and PowerShell export native `BAT_THEME`.
Unix shells use `themes.fzf` for `FZF_DEFAULT_OPTS_FILE`.
Harlequin has no global theme environment variable, so the Unix shell function
passes `themes.harlequin` via `--theme` for every profile, overriding profile theme
values. An explicit later `--theme` overrides it. Direct executable invocations
bypass that shell default.
Change the central values, run `chezmoi apply`, then reload/restart the affected
apps or shell. Theme names must be supported/installed by each tool; this does not
install arbitrary palettes or change the existing layouts/keymaps.

The Unix `theme` command switches Ghostty, Neovim, and Oh my tmux! together:

```sh
# Install the command and integrations after updating the checkout.
chezmoi apply ~/.local/bin/theme ~/.config/ghostty/config \
  ~/.config/ghostty/themes ~/.config/dotfiles/theme.lua ~/.tmux.conf.local \
  ~/.config/fish/completions/theme.fish
# Install the additional Neovim providers once.
nvim --headless "+Lazy! install kanagawa.nvim everforest onedark.nvim github-nvim-theme moonfly vscode.nvim sonokai modus-themes.nvim" +qa

theme list
theme show
theme set catppuccin-mocha
theme set dracula
theme set custom
```

Available shared profiles (plus `custom`):

| Profile | Variant | Neovim provider |
| --- | --- | --- |
| `catppuccin-mocha` | Mocha | [catppuccin/nvim](https://github.com/catppuccin/nvim) |
| `cyberdream` | Default dark | [scottmckendry/cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim) |
| `dracula` | Dracula | [dracula/vim](https://github.com/dracula/vim) |
| `everforest` | Dark, medium contrast | [sainnhe/everforest](https://github.com/sainnhe/everforest) |
| `github-dark-high-contrast` | GitHub Dark High Contrast | [projekt0n/github-nvim-theme](https://github.com/projekt0n/github-nvim-theme) |
| `gruvbox` | Dark, medium contrast | [ellisonleao/gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) |
| `gruvbox-hard` | Dark, hard contrast | [ellisonleao/gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) |
| `kanagawa` | Wave | [rebelot/kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) |
| `modus-vivendi` | Default dark, accessibility-focused | [miikanissi/modus-themes.nvim](https://github.com/miikanissi/modus-themes.nvim) |
| `moonfly` | Dark charcoal | [bluz71/vim-moonfly-colors](https://github.com/bluz71/vim-moonfly-colors) |
| `nord` | Nord | [nordtheme/vim](https://github.com/nordtheme/vim) |
| `onedark` | Default dark | [navarasu/onedark.nvim](https://github.com/navarasu/onedark.nvim) |
| `rose-pine` | Main | [rose-pine/neovim](https://github.com/rose-pine/neovim) |
| `sonokai` | Default dark, vivid Monokai-inspired colors | [sainnhe/sonokai](https://github.com/sainnhe/sonokai) |
| `tokyonight` | Night | [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) |
| `vscode-dark` | VS Code Dark+ inspired | [Mofiqul/vscode.nvim](https://github.com/Mofiqul/vscode.nvim) |

Named profiles explicitly select Neovim's dark background, including when
switching from a light colorscheme. `custom` leaves that option untouched.
`gruvbox-hard` sets `gruvboxContrast: hard`; ordinary `gruvbox` resets it to medium.
The generated Lua returns contrast alongside the shared `gruvbox` colorscheme
name, so both initial plugin loading and live reloads apply the selected variant.
Restart existing Neovim instances once after updating this integration.
Moonfly is a dark-charcoal option, not an accessibility-certified high-contrast theme.
`vscode-dark` uses the upstream dark palette, not VS Code's High Contrast theme.
The plugin also adjusts JavaScript/TypeScript Tree-sitter queries to more closely
match VS Code syntax highlighting.
Sonokai pins its `default` style; Modus Vivendi pins the default dark variant,
not tinted. The Modus Neovim port documents WCAG AAA contrast; this does not
certify the Ghostty or Oh my tmux! mappings.

Fish completes the subcommands and fetches profile candidates from `theme list`
for `theme set <Tab>`. If an existing Fish session has already tried completing
`theme`, load the new definition once with
`source ~/.config/fish/completions/theme.fish`; new sessions load it automatically.

`theme set` updates `chezmoi/.chezmoidata/theme-profile.yaml` in the active
chezmoi source, then applies only those three app configs, without install hooks.
The selection survives subsequent `chezmoi apply` runs and appears as a source
checkout change; it is not committed automatically. Profiles live in
`chezmoi/.chezmoidata/theme-profiles.yaml`. `custom` restores the choices in
`themes.yaml`, not a snapshot of previously running apps.

Ghostty uses bundled equivalents for Catppuccin Mocha, Nord, Rosé Pine,
TokyoNight Night, Gruvbox Dark/Hard, Kanagawa Wave, GitHub Dark High Contrast,
Sonokai, and Modus Vivendi. Bundled themes can lag upstream in details such as
bright ANSI or selection colors. In particular, bundled Modus Vivendi matches
the main background/foreground and base accents, but its bright ANSI and
selection colors differ from the current Neovim extra.
Dracula, Cyberdream, Moonfly, and VS Code Dark use managed upstream theme files;
Everforest and One Dark use managed adapters of their
official Neovim palettes to match the selected backgrounds and accents. Sources
and licenses are kept beside those assets. The tmux profiles adapt each palette
to the existing 17 Oh my tmux! slots without changing the status layout.
Neovim providers are lazy-loaded; run the plugin installation on a fresh setup
before switching. Starship, fzf, bat, delta, Harlequin, and the current shell
environment are **not** changed by this command.

Running apps reload as follows:

- **Neovim:** restart once after installing the integration. Afterwards a directory
  watcher reloads the generated colorscheme, including atomic file replacements.
  If watching fails, an error is reported and focus changes retry the theme load.
- **tmux:** updates the current/default server through Oh my tmux!'s theme stage,
  preserving the status layout and avoiding plugin updates. Separate servers must
  be refreshed separately.
- **Ghostty on macOS:** invokes its native AppleScript `reload_config` action.
  macOS may request Automation permission. If unavailable or denied, the command
  reports failure; use `Cmd+Shift+,` to reload manually. It does not use simulated
  keystrokes or require Accessibility permission.
- **Ghostty on Linux:** sends the documented `SIGUSR2` reload signal to running
  Ghostty processes. This path is not verified on Linux. See the
  [Ghostty reload documentation](https://ghostty.org/docs/linux/systemd).

Unknown profile names are rejected before writing. Apply conflicts stop the
command without forcing overwrites; the requested source selection remains, so
resolve the conflict and rerun the command. Reload failures likewise do not undo
the saved configuration. The command is excluded on Windows.

`chezmoi/.chezmoidata/fzf.yaml` is the single source for Bash/Zsh/Fish fzf
settings. `fileCommand` uses `fd --type f --hidden --exclude .git` for both plain
fzf and Ctrl+T: only files are listed, including hidden entries, while `.git`
directories are excluded and fd's default ignore rules (including `.gitignore`)
still apply. Fish Ctrl+T also searches from the directory parsed from the current
token. Piped input bypasses this command.
`ctrlT` holds common picker options; `ctrlTByOS` adds options for the chezmoi
target OS. `ctrlTHeader` and `ctrlTHeaderByOS` provide the shared multiline header
and platform-specific help. Each shell template renders these values before initializing fzf;
there is no runtime config loader. Edit the YAML and run `chezmoi apply` to update
the generated shell files.

`themes.fzf` selects the shared options file relative to the shell's config home.
The managed `chezmoi/dot_config/fzf/dracula` becomes `~/.config/fzf/dracula`;
Bash/Zsh/Fish export its path as `FZF_DEFAULT_OPTS_FILE`, using `$XDG_CONFIG_HOME`
when set. Its color-only options apply to plain fzf, Ctrl+T, and `rg.fzf`, without
changing key bindings or layout. It contains the [official Dracula fzf colors](https://draculatheme.com/fzf),
including the background. The existing `fzf/catppuccin-mocha` file remains available
as another central selection; its main background override is omitted.
Edit the managed theme file and run `chezmoi apply` to change colors; bat's syntax
highlighting remains independently configured.

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
