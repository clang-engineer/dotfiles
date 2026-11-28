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
git clone https://github.com/clang-engineer/dotfiles.git ~/dotfiles

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

### Tool integrations

See [TOOLING.md](TOOLING.md) for [Tinty themes](TOOLING.md#themes-macoslinux), [fzf and shell integration](TOOLING.md#fzf-and-shell-integration), and platform-specific shell settings.

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
