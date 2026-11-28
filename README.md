# Dotfiles

One command to set up a reproducible, keyboard-driven development environment with [chezmoi](https://chezmoi.io).

`chezmoi apply` installs packages and runtimes, deploys configuration, and sets up integrations.

**Native tools first. Minimal customization. One coherent terminal workflow.**

## Highlights

- **Declarative setup** — Homebrew/Scoop packages, mise runtimes, and managed configuration.
- **Unified themes** — Tinty coordinates Ghostty, Neovim, tmux, fzf, Yazi, Delta, and lazygit.
- **Ranked theme picker** — Fish completion with GitHub Stars from [Radar](https://clang-engineer.github.io/radar/), color previews, and native tmux theme indicators.
- **Consistent navigation** — fzf file and content search, Atuin history, zoxide, and sesh.
- **Native-first configuration** — LazyVim and Oh My Tmux, with upstream configuration preserved for comparison.
- **Public/private separation** — public configuration here; credentials and machine-specific secrets stay outside Git.

## Stack

| Layer | Tools |
|---|---|
| Terminal | Ghostty, Oh My Tmux, sesh |
| Shell | Fish, Zsh, Bash, PowerShell |
| Editor | LazyVim / Neovim |
| Navigation | fzf, ripgrep, fd, Atuin, zoxide, Yazi |
| Git | lazygit, Delta |
| Database | Harlequin |
| Desktop (macOS) | AeroSpace, Hammerspoon, JankyBorders |
| Setup | chezmoi, Homebrew, Scoop, mise |

## One-command setup

With Git, Homebrew and chezmoi installed on macOS/Linux:

```sh
chezmoi init --apply https://github.com/clang-engineer/dotfiles.git
```

To preview before applying, omit `--apply`, run `chezmoi diff`, then `chezmoi apply`.

Optional theme setup (macOS/Linux):

```sh
tinty sync
tinty apply base16-dracula
```

Windows support is scaffolded but not yet verified on a real machine. See [docs/setup.md](docs/setup.md) for prerequisites and platform-specific instructions.

## Design

Prefer built-in behavior, then official or widely adopted integrations, then minimal configuration. Write custom code only for a concrete need. Preserve upstream structure and keep historical Vim configurations for reference.

## Documentation

- [Setup and security](docs/setup.md) — installation, layout, identity, secrets, and recovery.
- [Tool integrations](docs/tooling.md) — themes, shell bindings, tmux, and upstream comparison.
- [Neovim configuration](nvim/README.md)
- [Terminal fonts](docs/terminal-fonts.md)
- [Tool recommendations](docs/recommendations.md)
- [Devkit](https://github.com/clang-engineer/devkit) — general tool reference.

The previous symlink-based bootstrap is preserved at the `pre-chezmoi` tag.
