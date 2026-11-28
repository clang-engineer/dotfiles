# Native tmux themes

Tinty applies the official palette and lazily installs the selected native theme and its dependencies. Repositories are cached under `${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/native-repos`. No network update is performed for an installed theme during apply.

Run `~/.config/tinted-theming/tinty/hooks/tmux/sync.sh` to update installed repositories, or add `--all` to install/update all registered repositories. Dirty repositories are not updated. Pinned revisions are checked during apply. Missing dependencies or failed installation fall back to the official Tinted palette and OMT layout. Existing Chezmoi-managed clones are not deleted automatically.
