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


## 1. Initialize chezmoi (machine-local, once)

For a fresh machine, clone, initialize and apply in one command:

```sh
chezmoi init --apply https://github.com/clang-engineer/dotfiles.git
```

To preview before applying, omit `--apply` and continue to step 2. The default checkout is under `~/.local/share/chezmoi` on Unix.

For a custom checkout location, use the manual alternative:

```sh
git clone https://github.com/clang-engineer/dotfiles.git ~/dotfiles
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

Skip this step if you already used `init --apply` successfully.

```sh
chezmoi diff     # preview what will change
chezmoi apply    # link, copy, install, and generate in one pass
```

> **Skipping the slow parts.** `chezmoi apply` also installs packages, TPM plugins,
> and mise runtimes automatically. To place the configs
> only and defer those, run `chezmoi apply --exclude=scripts`, then a plain
> `chezmoi apply` later when you want them. Package and runtime installation is the
> slowest part. Steps 7–8 are optional; run them anytime.

What `chezmoi apply` runs, in order — file placement (source→target, managed vs
symlink) is documented in the [managed files](#how-it-works) table as the source
of truth. This section lists only the scripts that run:

### Scripts (run\_)

| Script | Action |
|---|---|
| `run_once_before_00-migrate-claude-home.sh` | migrate the legacy Claude symlink (macOS/Linux) |
| `run_onchange_after_05-brew-bundle.sh` | install Homebrew formulae and macOS-only casks |
| `run_onchange_after_10-install-shell-tools.sh` | install TPM plugins and mise runtimes (macOS/Linux) |
| `run_onchange_after_11-build-harlequin-config.sh` | build the database configuration generator and retire owned legacy `db` installations (macOS/Linux) |
| `run_onchange_after_12-install-npm-global.sh` | install global npm CLIs (macOS/Linux) |
| `run_onchange_after_15-windows-install.ps1` | install Scoop packages and mise runtimes (Windows) |

> Required dependency or install failures stop the apply instead of being recorded
> as successful. Fix the reported problem and retry `chezmoi apply`; successful
> unchanged scripts do not rerun. TPM installs also track changes to the tmux config.

> Edit managed configs with `chezmoi edit --apply <target>` (edit source + apply
> immediately). Only nvim and hammerspoon are whole-directory symlinks; Claude's
> `keybindings.json` and `statusline.sh` are managed files.

## 3. Packages and runtimes

`chezmoi apply` installs package manifests and the Node/Java versions declared in
`~/.config/mise/config.toml`. mise also installs Ruby on macOS/Linux; Windows uses
Scoop Ruby because mise's Ruby backend is Unix-only. Linux skips the macOS cask
manifest and JankyBorders. The DB launcher is currently macOS/Linux-only; Windows
skips its build hook and wrapper. The Windows PowerShell installer is only the
bootstrap mechanism; installed CLI tools are available from PowerShell, Git Bash,
cmd, and IDE terminals through PATH.

Windows installs `bat` and `eza` for the shared `cat`/`ls` aliases. The PowerShell
profile initializes the already-installed Starship prompt after local secrets,
only when input and output are attached to a terminal.

The Scoop manifest keeps only `mingw` for C/C++: its
[package definition](https://github.com/ScoopInstaller/Main/blob/master/bucket/mingw.json)
provides GCC/G++, GDB, and make, while the separate
[`gcc` package](https://github.com/ScoopInstaller/Main/blob/master/bucket/gcc.json)
overlaps the compiler and adds another toolchain `bin` directory to PATH.
The installer does not uninstall packages removed from the manifest; existing
Windows machines with both toolchains still need manual cleanup after checking
which compiler their projects use.

On macOS/Linux, the `tldr` command comes from Homebrew's `tlrc` formula (the old
`tldr` formula is unavailable). If an older checkout fails with “No available
formula with the name tldr”, update the checkout and rerun `chezmoi apply`.

The Brewfile declares `tldr` as a conflict, so Homebrew Bundle unlinks the legacy
formula before installing `tlrc`; it does not uninstall it or overwrite files.
If a previous attempt already installed `tlrc` but failed to link it, the
`--no-upgrade` run skips that install-time conflict handling. Repair the links
once, then retry the apply:

```sh
brew unlink tldr
brew link tlrc
tldr --version
chezmoi apply
```

### Fish interactive shell

The Brewfile installs fish. Apply the managed configuration, then run `fish` to
try it before changing the account login shell. `exit` returns to the previous
shell. Existing zsh configuration is retained as a fallback.

```sh
chezmoi diff --recursive --exclude=scripts ~/.config/fish
chezmoi apply --recursive --exclude=scripts ~/.config/fish
fish
```

The configuration initializes mise, fzf, Atuin (Ctrl+R), zoxide, and Starship using
their fish integrations, preserves tmux auto-attach, and
provides native Harlequin profile completion on Tab. The standard `fzf --fish`
integration provides fzf completion on Shift+Tab for all commands.
Fish has built-in suggestions and syntax highlighting; it does not load zsh
plugins. Shell histories are separate; Atuin retains its own shared history.

Run `tinty sync` once to download schemes. In Fish, type `tinty apply ` and press
Tab to complete a scheme ID. With `tinty`, `fzf`, and `jq` installed, Shift+Tab
opens a ranked Base16 picker for `tinty apply` and `tinty info`; elsewhere it
retains standard fzf completion. Enter applies the selected command. After
`chezmoi apply`, start a new Fish session to load updated completion and bindings.

`~/.secrets` remains a zsh-compatible file. Fish loads it in a clean zsh subprocess
and imports exported environment variables, including those from the private
companion. It never evaluates that file as fish code. Functions and aliases in
that file are not imported.

To select fish as the login shell (macOS/Linux), run these commands from zsh/bash:

```sh
fish_path="$(command -v fish)"
grep -qxF "$fish_path" /etc/shells ||
  printf '%s\n' "$fish_path" | sudo tee -a /etc/shells
chsh -s "$fish_path"
```

Open a new terminal afterward. A terminal app with an explicit shell command
needs that setting changed too. Existing tmux servers can retain their old shell;
update new panes without terminating sessions:

```sh
tmux set-option -g default-shell "$(command -v fish)"
```

Existing panes keep running their current shell. On macOS, restore the login shell
with `chsh -s /bin/zsh` if needed.


## 4. Machine-local secrets (`~/.secrets`)

Bootstrap tokens live in `~/.secrets` (never committed). `chezmoi apply` creates it
once from a scaffold (`create_private_` → mode 0600, written only if missing and never
overwritten), so anything you fill in survives later applies:

```sh
$EDITOR ~/.secrets   # add GITHUB_TOKEN, API keys, etc. as you need them
```

The shells (`config.fish` / `.zshrc` / `.bashrc`) load it automatically — open a new
shell to load edits. On Windows, the PowerShell 7 all-hosts profile sources `~/.secrets.ps1`, which
you create by hand (chezmoi scaffolds only the Unix `~/.secrets`). The same profile is
loaded whenever `pwsh` runs in Windows Terminal, VS Code, JetBrains, or another host;
terminal appearance remains configured by each host.

Machine paths (`WORKSPACE_DIR`, `VAULT_DIR`, …) and any synced credentials are **not**
in the public scaffold — they live in the private `secrets` repo. If you have access,
clone it and run its `./setup.sh`: it appends a managed block to `~/.secrets` that
sources its `env`, overlays real SSH hosts, generates Harlequin profiles, and
generates `~/.claude/settings.json` (its own claude overlay owns the settings template
and private agent rules/skills). That repo's README documents the exact clone command.

## 5. Git identity

`dot_gitconfig.tmpl` renders only shared settings plus an absolute `[include]`
path to the machine-local `~/.gitconfig.local`. `~/.gitconfig.local` is created
by `create_dot_gitconfig.local.tmpl` from the name/email you entered at
`chezmoi init` (step 1), and chezmoi never overwrites it afterwards. Change them
later by editing `~/.gitconfig.local` directly. If you skipped the prompts, the
`[user]` fields are left empty and git asks on your first commit.

To add a workspace-scoped identity (a different name/email for repos under a
given directory), run `scripts/add-workspace-user.sh` — it appends an
`[includeIf "gitdir:..."]` block to the same file.

Keep GitHub authentication and commit identity separate:

```text
SSH Host alias + IdentityFile
→ remote fetch/push account

Git includeIf + workspace config
→ commit author name/email
```

Verify both after restoring a machine:

```sh
ssh -G github.com | grep -E '^(hostname|user|identityfile|identitiesonly) '
ssh -T git@github.com
git var GIT_AUTHOR_IDENT
```

## 6. Verify the restored environment

Run these checks after `chezmoi apply` and the private secrets bootstrap:

```sh
chezmoi status
brew bundle check --file packages/Brewfile
brew bundle check --file packages/Brewfile.cask
mise doctor
nvim --version
ssh -T git@github.com
git var GIT_AUTHOR_IDENT
```

If `chezmoi status` shows Pi settings drift, review it before applying blindly:
`~/.pi/agent/settings.json` may contain machine-local state such as device ID,
default provider, or default model.

## 7. Sync Neovim plugins

```sh
nvim --headless "+Lazy sync" +qa
```

## 8. Optional (scripts/)

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

## 9. Security

Only public config is version-controlled; keys, tokens, and private hosts exist
machine-locally only.

- **SSH** (`private_dot_ssh/` → `~/.ssh/`): chezmoi manages only `config` +
  `config.d/00-global` and `template.example`. Real keys, known_hosts, and private
  hosts (`config.d/[1-9]*`) are never committed (`.gitignore` + `secrets` overlay).
  `private_` guarantees `~/.ssh` is 0700, and chezmoi never generates keys.
- **Git** (`dot_gitconfig.tmpl` → `~/.gitconfig`): only shared settings are managed;
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

## Managed files and repository layout

### How it works

The chezmoi source lives in `chezmoi/` (a home-mirror tree). `chezmoi apply`
turns it into your home directory:

| chezmoi source | becomes | kind |
|---|---|---|
| `dot_zshrc.tmpl`, `dot_bashrc.tmpl`, `dot_gitconfig.tmpl`, `dot_tmux.conf`, … | `~/.zshrc`, `~/.bashrc`, `~/.gitconfig`, … | **managed file** (copy/render) |
| `dot_config/fish/` | `~/.config/fish/` | managed fish startup, functions, and completions |
| `private_dot_ssh/` | `~/.ssh/` (0700) | managed files; keys stay per-machine |
| `dot_config/symlink_nvim.tmpl` | `~/.config/nvim` → `nvim/lazy` | **symlink** |
| `symlink_dot_hammerspoon.tmpl` | `~/.hammerspoon` → `hammerspoon/` | symlink |
| `symlink_dot_sops.yaml.tmpl` | `~/.sops.yaml` → `sops/.sops.yaml` | symlink; public age recipient rules, private identity stays outside Git |
| `dot_claude/` | selected files in `~/.claude/` | managed files |
| `run_once_*` / `run_onchange_*` | packages, TPM plugins, and mise runtimes | scripts |

**Managed vs symlink:** big, live-edited config directories (`nvim/`,
`hammerspoon/`) stay as their own folders and are symlinked. Claude's runtime
directory stays local while chezmoi manages only its public config files. Everything
else is a managed file; edit with `chezmoi edit --apply ~/.zshrc`.

### Layout

| Folder | What |
|---|---|
| `chezmoi/` | chezmoi source — managed dotfiles, OS-branched via `.chezmoiignore.tmpl` |
| `chezmoi/dot_local/bin/executable_repos` | `~/.local/bin/repos` — sync configured Git repositories or repositories directly under a chosen directory |
| `nvim/` | Neovim — `lazy/` LazyVim → `~/.config/nvim` |
| `hammerspoon/` | macOS automation — symlinked to `~/.hammerspoon` |
| `packages/` | package manifests — Brewfile (macOS/Linux), casks (macOS), Scoop (Windows) |
| `scripts/` | tooling: key generation, workspace identity, and Windows installers |
| `tools/harlequin-config/` | [Go Harlequin configuration generator](../tools/harlequin-config/README.md) — use native `harlequin -P` profile completion |
| `vim/` | legacy Vim config snapshots (not linked; kept for reference) |

### SOPS public recipient

`sops/.sops.yaml` contains the public age recipient used for new SOPS files.
`chezmoi apply ~/.sops.yaml` links it into the home directory; SOPS discovers
it automatically from projects under `$HOME`. Keep age private keys outside Git.

### Cross-platform

`chezmoi/.chezmoiignore.tmpl` branches by OS. Linux skips macOS-only AeroSpace,
Hammerspoon, and casks. Windows uses AppData for Neovim, installs shared CLI tools
with Scoop, and manages Git Bash startup files alongside a PowerShell 7 all-hosts
profile. The Harlequin config generator is macOS/Linux-only; its build hook and wrapper are
excluded on Windows. Terminal appearance remains host-specific. **Windows is
scaffolded and must still be verified on a real machine after the migration.**

### Git identity and GitHub accounts

GitHub authentication and commit identity are separate concerns:

```text
SSH Host alias + IdentityFile
→ which GitHub account is used for fetch/push

Git includeIf + workspace config
→ which user.name / user.email is written into commits
```

The shared `~/.gitconfig` is rendered from `dot_gitconfig.tmpl` and includes the
machine-local `~/.gitconfig.local`. Default identity is created once during
`chezmoi init`; workspace-specific identity can be added with
`scripts/add-workspace-user.sh`. SSH host aliases live under `~/.ssh/config.d/`,
while private keys and real host entries stay outside this public repo.

### Secrets

Nothing private lives in this repo. `chezmoi apply` installs only the public config.
Personal agent instructions and skills belong to the private companion; its
`setup.sh` links shared instructions and supplemental docs into Pi's agent directory.
Pi settings and package declarations remain managed here.
See [agent configuration](tooling.md#agent-configuration) for OMP details.

The private `secrets` companion (real SSH hosts and Harlequin connection sources) owns
its own bootstrap — clone it and run its `./setup.sh`; see that repo's README for the
command. Public clones simply skip it. See [setup.md](setup.md#9-security).

> Comments inside the config files are in Korean, but the configs themselves are
> language-agnostic — the setup works the same regardless.
