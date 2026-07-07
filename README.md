# Dotfiles

My personal environment, managed with [chezmoi](https://chezmoi.io). On a fresh
machine `chezmoi apply` links every config, runs the one-time installs, generates
machine-local bits, and (optionally) pulls the private `secrets` companion — one
command, macOS and Windows.

## Quick start

**macOS / Linux**

```sh
brew install chezmoi
git clone <repo> ~/Desktop/_zero/private/dotfiles

# one-time, machine-local: point chezmoi at the repo (~ is expanded)
mkdir -p ~/.config/chezmoi
echo 'sourceDir = "~/Desktop/_zero/private/dotfiles"' > ~/.config/chezmoi/chezmoi.toml

chezmoi apply
brew bundle --file packages/Brewfile
```

**Windows (PowerShell)** — _scaffolded, verify on a real machine_

```powershell
winget install twpayne.chezmoi
# clone, write chezmoi.toml (sourceDir), then:
chezmoi apply
.\scripts\windows\install-windows.ps1   # packages, Nerd Font, terminal
```

- Setup walkthrough: [SETUP.md](SETUP.md)
- Secret handling (SSH keys, `~/.secrets`, identity): [SECURITY.md](SECURITY.md)

## How it works

The chezmoi source lives in `chezmoi/` (a home-mirror tree). `chezmoi apply`
turns it into your home directory:

| chezmoi source | becomes | kind |
|---|---|---|
| `dot_zshrc`, `dot_gitconfig`, `dot_tmux.conf`, … | `~/.zshrc`, `~/.gitconfig`, … | **managed file** (copy) |
| `private_dot_ssh/` | `~/.ssh/` (0700) | managed files; keys stay per-machine |
| `symlink_dot_config/nvim.tmpl` | `~/.config/nvim` → `nvim/lazy` | **symlink** |
| `symlink_dot_hammerspoon.tmpl` | `~/.hammerspoon` → `hammerspoon/` | symlink |
| `symlink_dot_claude.tmpl` | `~/.claude` → `claude/` | symlink |
| `run_once_*`, `run_after_*` | installs · claude settings · secrets overlay | scripts |
| `.chezmoiexternal.toml.tmpl` | pulls the private `secrets` repo | external |

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
| `scripts/` | tooling: key gen, workspace identity, secrets/pgpass/java setup, Windows installers |
| `vim/` | legacy Vim (not linked; kept for reference) |

## Cross-platform

`chezmoi/.chezmoiignore.tmpl` branches by OS — Unix ignores the PowerShell profile
and Windows nvim path; Windows ignores `.zshrc`/`.tmux.conf`/etc. and the `.sh`
run-scripts. **Windows is scaffolded but untested after the migration**: the claude
settings + secrets-overlay run-scripts are `.sh` (Unix-only); PowerShell equivalents
are a TODO.

## Secrets

Nothing private lives in this repo. The private `secrets` companion (real SSH hosts,
nvim DB connections) is pulled by `.chezmoiexternal` **only when `SECRETS_REPO` is
set** in `~/.secrets`; a public clone without it just skips the whole thing. See
[SECURITY.md](SECURITY.md).

## Related repositories

The Claude Code skills in `claude/` (`/notes`, `/blog`, `/notes-cleanup`, …) file
and publish notes into the repositories below.

| Repository | What |
|---|---|
| vault _(private)_ | TIL / analysis notes. Resolved via `$VAULT_DIR` |
| [devkit](https://github.com/clang-engineer/devkit) | Public reference — cheatsheets & templates |
| [clang-engineer.github.io](https://github.com/clang-engineer/clang-engineer.github.io) | Tech blog. Published to `$BLOG_DIR/_posts/` |

> Comments inside the config files are in Korean, but the configs themselves are
> language-agnostic — the setup works the same regardless.
