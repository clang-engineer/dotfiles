# Dotfiles — Claude Code project instructions

A collection of macOS/Windows development environment configs, managed with
[chezmoi](https://chezmoi.io). **`README.md` is the source of truth for structure,
placement rules (managed vs symlink), and secrets principles**; `SETUP.md` is the
setup walkthrough — don't restate them here.

## Build & verification commands
```sh
chezmoi diff                                # preview before applying
chezmoi apply                               # link, copy, install, generate
chezmoi status                              # pending changes (R = run script)
brew bundle check --file packages/Brewfile  # check for missing packages
nvim --headless "+Lazy sync" +qa            # sync plugins
```

## Coding conventions
- Shell scripts: 2-space indent, POSIX-compatible
- Lua: stylua (indent 2, column 120)
- Filenames: lowercase + hyphen (`my-script.sh`)
- Commits: `feat(scope):`, `fix(scope):`, `chore:` format
- **Prefer chezmoi-native over scripts**: reach for built-in features (`create_`,
  `symlink_`, `.chezmoiexternal`, init prompts, templates) before adding a `run_`
  shell script. Minimize script dependencies so `chezmoi apply` stays declarative.

## Security (must hold before every commit)
- Never commit `.env`, `.secrets`, `credentials`, or real keys. Private values live in
  `~/.secrets` + the private `secrets` repo.
- Never hardcode tokens in code (hammerspoon: use `hs.settings.get()` / `os.getenv()`).
- Full principles & pre-publish checklist: `SETUP.md` §8.
