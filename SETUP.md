# Setup Guide

## Prerequisites

- macOS
- Install Homebrew:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- Install chezmoi: `brew install chezmoi`
- Clone this repo: `git clone <repo> ~/dotfiles`

## 1. Link chezmoi (machine-local, once)

Create `~/.config/chezmoi/chezmoi.toml` so chezmoi uses this repo as its source:

```sh
mkdir -p ~/.config/chezmoi
echo 'sourceDir = "~/dotfiles"' > ~/.config/chezmoi/chezmoi.toml
```

> `~` is expanded by chezmoi, so there's nothing to change per machine. Templates
> derive the repo path via `{{ .chezmoi.sourceDir | dir }}`, so no extra setting
> like `dotfilesDir` is needed.
>
> `.chezmoiroot` scopes the source root under `chezmoi/`, so docs, packages, and
> scripts are automatically excluded from chezmoi's targets.

## 2. Apply

```sh
chezmoi diff     # preview what will change
chezmoi apply    # link, copy, install, and generate in one pass
```

> **Skipping the slow parts.** `chezmoi apply` also runs the one-time installs
> (`run_once_*`: oh-my-zsh, zsh plugins, jenv) automatically. To place the configs
> only and defer those, run `chezmoi apply --exclude=scripts`, then a plain
> `chezmoi apply` later when you want them. Step 3 (`brew bundle`) is the heaviest —
> skip it and `brew install` packages as you need them. Steps 6–7 are optional; run
> them anytime.

What `chezmoi apply` runs, in order — file placement (source→target, managed vs
symlink) is documented in the [README](README.md#how-it-works) table as the source
of truth. This section lists only the scripts that run:

### Scripts (run\_)

| Script | Action |
|---|---|
| `run_once_after_10-install-shell-tools.sh` | oh-my-zsh, zsh plugins, TPM, jenv |
| `run_after_20-generate-claude-settings.sh` | generate `claude/settings.json` from `~/.secrets` env |
| `run_after_30-secrets-overlay.sh` | overlay the secrets repo when `SECRETS_DIR` is set |

> Edit configs afterwards with `chezmoi edit --apply ~/.zshrc` (edit source + apply
> immediately). nvim/hammerspoon/claude are symlinks, so edit them directly as usual.

## 3. Install packages

```sh
brew bundle --file packages/Brewfile
```

## 4. Machine-local secrets (`~/.secrets`)

Tokens and machine paths go in `~/.secrets` (never committed). The shell sources
it automatically.

```sh
cp scripts/.secrets.example ~/.secrets && chmod 600 ~/.secrets
$EDITOR ~/.secrets   # GITHUB_TOKEN, workspace paths, (optional) SECRETS_REPO, etc.
```

On Windows: `scripts/.secrets.ps1.example` → `~/.secrets.ps1`. Both files are in
`.gitignore` so they're never committed, and `.zshrc` / `.bashrc` / PowerShell
`$PROFILE` source them automatically.

## 5. Git identity

`dot_gitconfig` holds only shared settings plus `[include] ~/.gitconfig.local`.
Put your own identity in `~/.gitconfig.local`:

```sh
cp scripts/.gitconfig.local.example ~/.gitconfig.local
# edit and fill in [user] name/email
```

## 6. Sync Neovim plugins

```sh
nvim --headless "+Lazy sync" +qa
```

## 7. Optional (scripts/)

Run only what you need.

### SSH key generation & multiple GitHub accounts

```sh
./scripts/generate-key.sh [LABEL] [EMAIL]
```

Generates a key at `~/.ssh/id_rsa_{LABEL}` and registers it with ssh-agent. LABEL is
a free-form identifier (`github_myuser`, `gcp_myuser`, …). For GitHub, add the public
key at https://github.com/settings/keys.

Add host aliases under `~/.ssh/config.d/` (`~/.ssh/config` does `Include config.d/*`).
The public repo tracks only `00-global`; real private hosts are overlaid by the
`secrets` repo:

```ssh
Host github.com-myuser
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_github_myuser
```

Then clone/set remotes via the alias:

```sh
git clone git@github.com-myuser:username/repo.git
git remote set-url origin git@github.com-myuser:username/repo.git
ssh -T git@github.com-myuser   # verify the connection
```

### Git includeIf (per-workspace account separation)

```sh
./scripts/add-workspace-user.sh [WORKSPACE_PATH] [GIT_NAME] [GIT_EMAIL]
```

Makes Git repos under a given directory use a different name/email. Use it to
separate work and personal accounts.

### Java version management

```sh
./scripts/setup-java-versions.sh
```

Creates `/Library/Java/JavaVirtualMachines/` symlinks for Homebrew openjdk
(8, 11, 17, 21) and registers them with jenv. Requires sudo.

### Neovim Java LSP

Generate `.nvim.lua` from a Neovim command at the project root:

```vim
:JvmEnvInit 21 17
```

## 8. Security

Only public config is version-controlled; keys, tokens, and private hosts exist
machine-locally only.

- **SSH** (`private_dot_ssh/` → `~/.ssh/`): chezmoi manages only `config` +
  `config.d/00-global` and `template.example`. Real keys, known_hosts, and private
  hosts (`config.d/[1-9]*`) are never committed (`.gitignore` + `secrets` overlay).
  `private_` guarantees `~/.ssh` is 0700, and chezmoi never generates keys.
- **Git** (`dot_gitconfig` → `~/.gitconfig`): only shared settings are managed;
  identity lives in `~/.gitconfig.local` (outside the repo) in your home directory.
- **`~/.secrets` / `~/.secrets.ps1`**: sensitive env vars like `GITHUB_TOKEN` and
  `ANTHROPIC_API_KEY` go here only (gitignored).
- **hammerspoon**: never hardcode tokens in Lua — use `hs.settings.get("token_name")`
  or `os.getenv()`.
- **Paths**: prefer `$HOME` / `$(brew --prefix ...)` over absolute paths to reduce
  exposure when moving between machines.

### Pre-release checklist

1. `git status --ignored` — confirm nothing that must stay private is staged.
2. `ls -l ~/.ssh` — confirm permissions are `drwx------` / `-rw-------`. If not:

   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_* ~/.ssh/known_hosts* 2>/dev/null || true
   chmod 644 ~/.ssh/*.pub 2>/dev/null || true
   ```

3. Review that newly added scripts don't `echo` or log secret data.
4. When adding a file under a sensitive path, check whether `.gitignore` needs updating.
