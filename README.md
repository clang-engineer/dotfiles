# Dotfiles

My personal environment, managed with [chezmoi](https://chezmoi.io). On a fresh
machine `chezmoi apply` links every config, runs the one-time installs, generates
machine-local bits, and installs public packages in one command on macOS, Linux,
and Windows. The private `secrets` companion has a separate bootstrap.

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

## How it works

The chezmoi source lives in `chezmoi/` (a home-mirror tree). `chezmoi apply`
turns it into your home directory:

| chezmoi source | becomes | kind |
|---|---|---|
| `dot_zshrc`, `dot_gitconfig`, `dot_tmux.conf`, … | `~/.zshrc`, `~/.gitconfig`, … | **managed file** (copy) |
| `private_dot_ssh/` | `~/.ssh/` (0700) | managed files; keys stay per-machine |
| `dot_config/symlink_nvim.tmpl` | `~/.config/nvim` → `nvim/lazy` | **symlink** |
| `symlink_dot_hammerspoon.tmpl` | `~/.hammerspoon` → `hammerspoon/` | symlink |
| `dot_claude/` | selected files in `~/.claude/` | managed files |
| agent command templates | Claude, Codex, and OpenCode command dirs | managed files |
| `run_once_*` / `run_onchange_*` | packages, TPM plugins, and mise runtimes | scripts |

**Managed vs symlink:** big, live-edited config directories (`nvim/`,
`hammerspoon/`) stay as their own folders and are symlinked. Claude's runtime
directory stays local while chezmoi manages only its public config files. Everything
else is a managed file; edit with `chezmoi edit --apply ~/.zshrc`.

## Layout

| Folder | What |
|---|---|
| `chezmoi/` | chezmoi source — managed dotfiles, OS-branched via `.chezmoiignore.tmpl` |
| `nvim/` | Neovim (LazyVim) — symlinked to `~/.config/nvim` |
| `hammerspoon/` | macOS automation — symlinked to `~/.hammerspoon` |
| `docs/` | tool-specific reference guides |
| `packages/` | package manifests — Brewfile (macOS/Linux), casks (macOS), Scoop (Windows) |
| `scripts/` | tooling: key generation, workspace identity, and Windows installers |
| `vim/` | legacy Vim (not linked; kept for reference) |

## Cross-platform

`chezmoi/.chezmoiignore.tmpl` branches by OS. Linux skips macOS-only AeroSpace,
Hammerspoon, and casks. Windows uses AppData for Neovim, installs shared CLI tools
with Scoop, and manages Git Bash startup files alongside a PowerShell 7 all-hosts
profile. Terminal appearance remains host-specific. **Windows is scaffolded and
must still be verified on a real machine after the migration.**

## Secrets

Nothing private lives in this repo. `chezmoi apply` installs only the public config.
The private `secrets` companion (real SSH hosts, nvim DB connections, `~/.pgpass`) owns
its own bootstrap — clone it and run its `./setup.sh`; see that repo's README for the
command. Public clones simply skip it. See [SETUP.md](SETUP.md#8-security).

> Comments inside the config files are in Korean, but the configs themselves are
> language-agnostic — the setup works the same regardless.
