# Dotfiles Recommendations

Reviewed on 2026-08-25. This is a review of useful additions, not an installation
plan. Adopt tools only when the corresponding workflow is needed.

## Current pattern

The configuration already has a strong, deliberately small foundation:

- chezmoi manages copied files, machine-local generated files, OS branches, and
  package installation; large live-edited trees such as Neovim and Hammerspoon
  are symlinked.
- Zsh uses native initialization instead of a framework, with fzf, zoxide,
  Starship, autosuggestions, and syntax highlighting.
- tmux uses Oh My Tmux, sesh, vim-tmux-navigator, resurrect, and continuum.
- LazyVim already covers LSP, formatting, debugging, Git, SQL, Markdown, JVM and
  web development, Copilot, navigation, and editing helpers.
- Git uses lazygit and Delta; macOS window management uses AeroSpace and
  Hammerspoon; agent workflows use OpenCode, Claude, Codex, and CopilotChat.

The best additions are therefore tools that fill a missing layer. More pickers,
shell frameworks, editor explorers, Git UIs, or AI frontends would mostly create
overlap.

## Terminal navigation and fuzzy selection

The terminal workflow is easier to reason about when each tool has a distinct
role instead of treating fzf as a general-purpose file finder.

- **fzf** is the low-level fuzzy picker. Its shell integration currently provides
  `Ctrl-R` for history, `Ctrl-T` for inserting a selected path into the command
  line, and `Alt-C` for choosing a directory and changing into it. Custom helpers
  such as `gco` also use fzf as a generic selector.
- **zoxide** is the preferred fast directory jumper for known or frequently used
  locations. This overlaps with fzf's `Alt-C`, so `Alt-C` is mainly useful when a
  directory must be discovered from a list rather than recalled by name.
- **Neovim/LazyVim pickers** are best when the search is part of an editing task.
  In particular, grep/search actions such as `<leader>sg` find text inside the
  project and lead directly into editing. Opening Neovim only to discover a file
  or path is unnecessary when no editing context is needed.
- **Atuin**, if adopted, should own `Ctrl-R` and structured shell-history search.
  fzf remains installed as a generic selection primitive rather than being
  removed.
- **Yazi**, if adopted, should cover visual filesystem exploration, preview,
  file operations, and shell-directory handoff. It complements rather than
  replaces fzf: Yazi is a file manager, while fzf selects an item from a list.

A likely end state is therefore:

| Need | Preferred tool |
|---|---|
| Shell history | Atuin (`Ctrl-R`) |
| Jump to a familiar directory | zoxide (`z`, `zi`) |
| Browse/manage the filesystem | Yazi |
| Search while editing | LazyVim/Snacks pickers |
| Select from arbitrary CLI output | fzf |
| Select a Git branch with `gco` | fzf |

`Ctrl-T` and `Alt-C` can remain available even if they are rarely used. They are
cheap fallback bindings, and keeping them does not require fzf to be a primary
user-facing workflow. The more important distinction is that fzf remains
infrastructure: commands such as `fd | fzf`, `rg ... | fzf`, `git branch | fzf`,
or `ps ... | fzf` can reuse the same picker whenever an ad-hoc selection is
useful.

## Recommended first

### 1. ShellCheck, shfmt, and PSScriptAnalyzer

This repository contains POSIX shell, Bash, and PowerShell setup scripts but has
no matching static-analysis and formatting toolchain.

- ShellCheck catches quoting, portability, and shell-semantic errors.
- shfmt provides deterministic formatting for shell files.
- PSScriptAnalyzer provides PowerShell analysis and formatting.

These have the highest value because they verify the code that bootstraps a new
machine. They complement Stylua and clang-format rather than duplicate them.

### 2. prek

`prek` is a fast, single-binary runner compatible with pre-commit configuration.
It can run ShellCheck, shfmt, PSScriptAnalyzer, and typo checks without adding a
custom validation script. It also fits the existing uv and mise-based toolchain.

Add checks incrementally. A hook system that runs too many slow checks will be
bypassed instead of helping.

### 3. Atuin

Atuin adds structured shell history search by directory, exit status, duration,
and host, with optional encrypted synchronization. It is a meaningful upgrade
over plain history search for a cross-platform environment.

The current Zsh and PowerShell configurations already assign `Ctrl-R` to fzf.
Atuin should replace only that history binding; fzf should remain for files,
directories, and generic fuzzy selection. Review history filters before enabling
sync because command arguments can contain secrets.

### 4. Yazi

Yazi fills the terminal file-management gap and reuses tools already installed:
fd, ripgrep, fzf, zoxide, jq, and Nerd Fonts. It complements the Neovim explorer
by handling bulk filesystem work and shell-directory handoff outside the editor.
Homebrew and Scoop packages are available.

### 5. watchexec

watchexec is a cross-platform primitive for rerunning tests, formatters,
generators, or development servers when files change. It avoids accumulating
language-specific watchers such as separate Node and Rust watch tools.

## Workflow-dependent

### Neotest

Enable LazyVim's `test.core` extra only if running tests inside Neovim would be
used regularly. The current setup has DAP and Trouble but no integrated test
runner. Install adapters only for languages actively in use.

### LazyVim chezmoi extra

LazyVim's `util.chezmoi` extra adds template highlighting, a source picker, and
`ChezmoiEdit`. Its default assumes `~/.local/share/chezmoi`, while this repository
uses a custom source directory such as `~/dotfiles`; the source path must be
overridden.

### Mergiraf

Mergiraf is a syntax-aware Git merge driver. It complements Delta's diff display
and lazygit's UI by reducing structural merge conflicts. Add it if complex
rebases or conflict resolution are frequent.

### JankyBorders (macOS)

JankyBorders adds focused-window borders and integrates cleanly with AeroSpace.
It does not compete with AeroSpace layout management or Hammerspoon automation.
Prefer it over a full SketchyBar setup unless a desktop status bar is genuinely
needed.

### lazydocker

OrbStack already provides the container runtime and GUI. lazydocker is worthwhile
only when Docker or Compose is used often enough to benefit from a keyboard-driven
terminal UI similar to lazygit.

### typos and hyperfine

- `typos` is useful for config and documentation checks, especially through
  prek. Keep a small allow-list for Korean text, product names, and identifiers.
- `hyperfine` is useful for reproducible command and build benchmarks, but is not
  a daily necessity.

## Do not add without a concrete need

- Zellij: replaces the established tmux, Oh My Tmux, and sesh workflow.
- broot, nnn, or ranger: choose one terminal file manager; Yazi is the best fit.
- direnv: mise already covers project activation and environment management.
- just or Task: mise tasks can provide shared task entry points if needed.
- More Neovim pickers, explorers, or Git UIs: Snacks, Trouble, grug-far, and
  lazygit already cover these workflows.
- More AI wrappers: OpenCode, Claude, Codex, and CopilotChat already overlap.
- Large Hammerspoon Spoon collections or SketchyBar: higher maintenance than the
  focused automation currently used.

## Existing gaps to fix before adding plugins

- AstroNvim remains tracked but is close to a stock starter, while LazyVim is the
  actively customized editor. Decide whether AstroNvim is still a useful fallback.
- `kotlin-debug-adapter` and `~/bin/vsql` are referenced by LazyVim but are not
  provisioned by the public package manifests.
- OpenCode and Codex have managed configuration or wrappers but are not declared
  in the Brew or Scoop manifests.
- PowerShell conditionally configures `bat` and `eza`, but Scoop does not install
  them.
- Windows support is still documented as scaffolded and has not been verified on
  a real machine after the chezmoi migration.

## Suggested order

1. Add ShellCheck, shfmt, and PSScriptAnalyzer.
2. Add prek and enable only the relevant checks.
3. Try Atuin, explicitly replacing only fzf history search.
4. Try Yazi.
5. Add watchexec.
6. Add workflow-dependent tools only after a concrete need appears.
