# Dotfiles

My personal environment, managed with [chezmoi](https://chezmoi.io). On a fresh
machine `chezmoi apply` links every config, runs the one-time installs, generates
machine-local bits, and (optionally) pulls the private `secrets` companion — one
command, macOS and Windows.

> The previous shell / `bootstrap.sh` version (symlink-based) is preserved at the
> **`pre-chezmoi`** git tag — restore with `git checkout pre-chezmoi`.

## Quick start

**macOS / Linux**

```sh
brew install chezmoi
git clone <repo> ~/dotfiles

# one-time: generate ~/.config/chezmoi/chezmoi.toml — prompts once for your
# git name/email and derives sourceDir from where you cloned (~ is expanded)
chezmoi init --source ~/dotfiles

chezmoi apply
brew bundle --file packages/Brewfile
```

**Windows (PowerShell)** — _scaffolded, verify on a real machine_

```powershell
winget install twpayne.chezmoi
# clone, then `chezmoi init --source <path>` (prompts, writes chezmoi.toml), then:
chezmoi apply
.\scripts\windows\install-windows.ps1   # packages, Nerd Font, terminal
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
| `symlink_dot_claude.tmpl` | `~/.claude` → `claude/` | symlink |
| `run_once_*` | shell-tool installs (oh-my-zsh, plugins, TPM, jenv) | scripts |

**Managed vs symlink:** big, live-edited config directories (`nvim/`,
`hammerspoon/`, `claude/`) stay as their own folders and are symlinked — edit in
place, no round-trip. Everything else is a managed file; edit with
`chezmoi edit --apply ~/.zshrc`.

## Layout

| Folder | What |
|---|---|
| `chezmoi/` | chezmoi source — managed dotfiles, OS-branched via `.chezmoiignore.tmpl` |
| `nvim/` | Neovim (LazyVim) — symlinked to `~/.config/nvim` |
| `hammerspoon/` | macOS automation — symlinked to `~/.hammerspoon` |
| `claude/` | Claude Code config — symlinked to `~/.claude` |
| `packages/` | package manifests only — Brewfile (macOS), scoop-packages.txt (Windows) |
| `scripts/` | tooling: key gen, workspace identity, secrets/java setup, Windows installers |
| `vim/` | legacy Vim (not linked; kept for reference) |

## Cross-platform

`chezmoi/.chezmoiignore.tmpl` branches by OS — Unix ignores the PowerShell profile
and Windows nvim path; Windows ignores `.zshrc`/`.tmux.conf`/etc. and the `.sh`
run-scripts. **Windows is scaffolded but untested after the migration**: the install
run-script is `.sh` (Unix-only); PowerShell equivalents are a TODO.

## Secrets

Nothing private lives in this repo. `chezmoi apply` installs only the public config.
The private `secrets` companion (real SSH hosts, nvim DB connections, `~/.pgpass`) owns
its own bootstrap — clone it and run its `./setup.sh`; see that repo's README for the
command. Public clones simply skip it. See [SETUP.md](SETUP.md#8-security).

> Comments inside the config files are in Korean, but the configs themselves are
> language-agnostic — the setup works the same regardless.
