# Setup Guide

## Prerequisites

- macOS or Linux: install Homebrew, then chezmoi:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  ```

- `brew install chezmoi`
- Windows: enable Developer Mode for symlink creation, then run
  `winget install Git.Git twpayne.chezmoi`
- Clone this repo: `git clone <repo> ~/dotfiles`

## 1. Link chezmoi (machine-local, once)

Generate `~/.config/chezmoi/chezmoi.toml` so chezmoi uses this repo as its source:

```sh
chezmoi init --source ~/dotfiles
```

> This runs `.chezmoi.toml.tmpl`, which **prompts once for your git name/email**
> (stored as `.gitName` / `.gitEmail`, used by `create_dot_gitconfig.local.tmpl`)
> and derives `sourceDir` from where you cloned via `{{ .chezmoi.sourceDir | dir }}`
> — so there's nothing to hardcode per machine.
>
> `.chezmoiroot` scopes the source root under `chezmoi/` (so `.chezmoi.sourceDir`
> is `<repo>/chezmoi` and `dir` strips it back to the repo root); docs, packages,
> and scripts are automatically excluded from chezmoi's targets.

## 2. Apply

```sh
chezmoi diff     # preview what will change
chezmoi apply    # link, copy, install, and generate in one pass
```

> **Skipping the slow parts.** `chezmoi apply` also installs packages, TPM plugins,
> and mise runtimes automatically. To place the configs
> only and defer those, run `chezmoi apply --exclude=scripts`, then a plain
> `chezmoi apply` later when you want them. Package and runtime installation is the
> slowest part. Steps 6–7 are optional; run them anytime.

What `chezmoi apply` runs, in order — file placement (source→target, managed vs
symlink) is documented in the [README](README.md#how-it-works) table as the source
of truth. This section lists only the scripts that run:

### Scripts (run\_)

| Script | Action |
|---|---|
| `run_once_before_00-migrate-claude-home.sh` | migrate the legacy Claude symlink (macOS/Linux) |
| `run_onchange_after_05-brew-bundle.sh` | install Homebrew formulae and macOS-only casks |
| `run_onchange_after_10-install-shell-tools.sh` | install TPM plugins and mise runtimes (macOS/Linux) |
| `run_onchange_after_15-windows-install.ps1` | install Scoop packages and mise runtimes |

> Edit managed configs with `chezmoi edit --apply <target>` (edit source + apply
> immediately). Only nvim and hammerspoon are whole-directory symlinks; Claude's
> `keybindings.json`, `statusline.sh`, and public commands are managed files.

## 3. Packages and runtimes

`chezmoi apply` installs package manifests and the Node/Java versions declared in
`~/.config/mise/config.toml`. mise also installs Ruby on macOS/Linux; Windows uses
Scoop Ruby because mise's Ruby backend is Unix-only. Linux skips the macOS cask
manifest. The Windows PowerShell installer is only the bootstrap mechanism; installed
CLI tools are available from PowerShell, Git Bash, cmd, and IDE terminals through PATH.

## 4. Machine-local secrets (`~/.secrets`)

Bootstrap tokens live in `~/.secrets` (never committed). `chezmoi apply` creates it
once from a scaffold (`create_private_` → mode 0600, written only if missing and never
overwritten), so anything you fill in survives later applies:

```sh
$EDITOR ~/.secrets   # add GITHUB_TOKEN, API keys, etc. as you need them
```

The shell (`.zshrc` / `.bashrc`) sources it automatically — open a new shell to load
edits. On Windows, the PowerShell 7 all-hosts profile sources `~/.secrets.ps1`, which
you create by hand (chezmoi scaffolds only the Unix `~/.secrets`). The same profile is
loaded whenever `pwsh` runs in Windows Terminal, VS Code, JetBrains, or another host;
terminal appearance remains configured by each host.

Machine paths (`WORKSPACE_DIR`, `VAULT_DIR`, …) and any synced credentials are **not**
in the public scaffold — they live in the private `secrets` repo. If you have access,
clone it and run its `./setup.sh`: it appends a managed block to `~/.secrets` that
sources its `env`, overlays real SSH hosts, nvim DB connections, and `~/.pgpass`, and
generates `~/.claude/settings.json` (its own claude overlay owns the settings template
and private agent rules/commands). That repo's README documents the exact clone command.

## 5. Git identity

`dot_gitconfig` holds only shared settings plus `[include] ~/.gitconfig.local`.
`~/.gitconfig.local` is created by `create_dot_gitconfig.local.tmpl` from the
name/email you entered at `chezmoi init` (step 1), and chezmoi never overwrites
it afterwards. Change them later by editing `~/.gitconfig.local` directly. If you
skipped the prompts, the `[user]` fields are
left empty and git asks on your first commit.

To add a workspace-scoped identity (a different name/email for repos under a
given directory), run `scripts/add-workspace-user.sh` — it appends an
`[includeIf "gitdir:..."]` block to the same file.

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
mise ls java
mise install
```

mise installs the Temurin versions declared in `~/.config/mise/config.toml` and makes
Java 21 the default. Use `mise use java@temurin-17` in a project to create a
project-local override.

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
