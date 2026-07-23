# Dotfiles Project Instructions

A collection of macOS/Windows development environment configs, managed with
[chezmoi](https://chezmoi.io). **`README.md` is the source of truth for structure,
placement rules (managed vs symlink), and secrets principles**; `SETUP.md` is the
setup walkthrough. Do not restate them here.

## Build And Verification Commands

```sh
chezmoi diff                                # preview before applying
chezmoi apply                               # link, copy, install, generate
chezmoi status                              # pending changes (R = run script)
brew bundle check --file packages/Brewfile  # check for missing packages
brew bundle check --file packages/Brewfile.cask
nvim --headless "+Lazy sync" +qa            # sync plugins
```

## Coding Conventions

- Shell scripts: 2-space indent; use POSIX syntax for `#!/bin/sh` and Bash only when declared
- Lua: stylua (indent 2, column 120)
- Filenames: lowercase + hyphen (`my-script.sh`)
- Commits: `feat(scope):`, `fix(scope):`, `chore:` format
- **Prefer chezmoi-native over scripts**: reach for built-in features (`create_`,
  `symlink_`, `.chezmoiexternal`, init prompts, templates) before adding a `run_`
  shell script. Minimize script dependencies so `chezmoi apply` stays declarative.

## Security

- Never commit `.env`, `.secrets`, credentials, or real keys. Private values live in
  `~/.secrets` and the private `secrets` repository.
- Never hardcode tokens in code. In Hammerspoon, use `hs.settings.get()` or `os.getenv()`.
- Follow the pre-publish checklist in `SETUP.md` section 8 before every commit.
