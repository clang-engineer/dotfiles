# Dotfiles

My personal environment setup. On a fresh machine, `bootstrap.sh` sets up
zsh / tmux / git / nvim / claude / hammerspoon in one command.

## Quick start

```sh
./bootstrap.sh           # macOS / Linux  — details: SETUP.md
./bootstrap.ps1          # Windows PowerShell — profile links + Neovim + packages
```

Then install packages in one go:

```sh
brew bundle install --file packages/Brewfile   # macOS
```

- Full setup walkthrough (macOS): [SETUP.md](SETUP.md)
- Secret handling (SSH keys, `~/.secrets`, identity, etc.): [SECURITY.md](SECURITY.md)

## Repository layout

| Folder | What | bootstrap |
|---|---|:-:|
| `zsh/` | Zsh/Bash config + plugin install | ✅ |
| `tmux/` | tmux config + TPM install | ✅ |
| `git/` | Shared `.gitconfig` + per-workspace identity split | ✅ |
| `nvim/` | Neovim config (LazyVim by default, classic kept separate) | ✅ |
| `claude/` | Claude Code config (linked to `~/.claude`) | ✅ |
| `hammerspoon/` | macOS automation (linked to `~/.hammerspoon`) | ✅ |
| `home/` | Standalone files (`.ideavimrc`, `.clang-format`, etc.) | ✅ |
| `ssh/` | SSH config + key generation scripts | ❌ manual |

`ssh/` is not automated by bootstrap (skipped even with `--force`) to avoid
clobbering existing keys. `packages/` (Brewfile) and `scripts/` (the bootstrap
orchestrator) rarely need to be touched directly.

> Comments inside the config files are in Korean, but the configs themselves are
> language-agnostic — the setup works the same regardless.

## Options

- `--force`: overwrite existing files/links at the target location.
- `--help`: print usage.

## Related repositories

The Claude Code skills defined in `claude/` (`/notes`, `/blog`, `/notes-cleanup`,
etc.) file and publish notes into the repositories below.

| Repository | What |
|---|---|
| vault _(private)_ | TIL / analysis notes. Resolved via `$VAULT_DIR` |
| [devkit](https://github.com/clang-engineer/devkit) | Public reference — cheatsheets & templates |
| [clang-engineer.github.io](https://github.com/clang-engineer/clang-engineer.github.io) | Tech blog. Published to `$BLOG_DIR/_posts/` |
