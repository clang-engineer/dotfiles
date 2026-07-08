# Neovim Configuration Guide

A single LazyVim-based configuration. Plugins and settings are modularized under `nvim/lazy/lua/`.

> The old Vimscript-based configuration has been split out into the top-level [`vim/`](../vim/README.md) (legacy, manually linked).

## Installation

### macOS / Linux

- `chezmoi apply` — symlinks `~/.config/nvim` to `nvim/lazy`.
- If you need to link manually:

  ```bash
  mkdir -p ~/.config
  ln -snf "$PWD/nvim/lazy" ~/.config/nvim
  ```

- Right after making changes, run `nvim --headless "+Lazy sync" +qa` to confirm the plugins are up to date.

### Windows

- `chezmoi apply` symlinks `%LOCALAPPDATA%\nvim` (`AppData/Local/nvim`) to `nvim/lazy` (⚠️ untested on Windows — symlinks require developer mode/administrator privileges).

## Recommended Workflow

- Declare the plugins you need in `nvim/lazy/init.lua`, and split their detailed configuration into `nvim/lazy/lua/plugins/`. Add per-feature documentation to the README in each module folder.

## Checklist

1. Remove the existing `~/.config/nvim` or `%LOCALAPPDATA%/nvim` link.
2. Create the new link.
3. Refresh plugin metadata with `nvim --headless "+Lazy! sync" +qa`.
4. Reopen `nvim` in tmux/IDE and check the state with `:checkhealth`.
5. For a project that needs Java or language-specific settings, create a `.nvim.lua` and refer to the Java Environment Setup section below.

## Troubleshooting

- If `:checkhealth` output shows missing dependencies such as LuaRocks, node, or python3, install them via Brew/Scoop and run it again.
- If an error occurs during plugin installation, run `rm -rf ~/.local/share/nvim` (or Windows `%LOCALAPPDATA%\nvim-data`) and re-run `nvim --headless "+Lazy sync" +qa`.

---

# Java Environment Setup

JDK environment variable injection is handled by the external plugin [clang-engineer/jvm-env.nvim](https://github.com/clang-engineer/jvm-env.nvim). Within dotfiles there is only the lazy spec (`lazy/lua/plugins/jvm-env.lua`); the plugin itself is fetched from GitHub.

## Structure

```
dotfiles/nvim/
└── lazy/lua/plugins/
    ├── jvm-env.lua                   # external plugin spec (options: jdtls/gradle major version)
    └── java.lua                      # wires nvim-jdtls to jvm-env env vars
```

## How It Works

1. lazy.nvim automatically calls `jvm-env.nvim`'s `setup(opts)` at startup (`lazy = false, priority = 100`)
2. Automatic OS detection (Windows/macOS/Linux)
3. Auto-discovers the JDK path and sets environment variables:
   - `JDTLS_JAVA_HOME` — for running jdtls (default: Java 21)
   - `GRADLE_JAVA_HOME` — for Gradle builds (default: Java 11)

## Usage

### Basic

No per-project setup required. Configured automatically when nvim starts.

### Per-Project Custom Versions

Create a `.nvim.lua` file:

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

Auto-generate `.nvim.lua` with a Neovim command from the project root:

```vim
:JvmEnvInit 21 17    " omit args to use the active config
```

`.nvim.lua` is loaded per-directory via the Neovim 0.9+ `exrc` rule. Since `vim.o.exrc = true` is already enabled in `lazy/lua/config/options/default.lua`, you only need to run `:trust` the first time you open nvim in that directory.

## Java Troubleshooting

### jdtls does not start

1. Check the Java paths:
```vim
:lua print(vim.env.JDTLS_JAVA_HOME)
:lua print(vim.env.GRADLE_JAVA_HOME)
```

2. Check jdtls status:
```vim
:LspInfo
```

### Project recognition errors such as "psd-RidEx does not exist"

**Delete the jdtls cache:**

```powershell
# Windows
rm -r -Force "$env:APPDATA\jdtls"
```

```bash
# macOS
rm -rf ~/Library/Caches/jdtls

# Linux
rm -rf ~/.cache/jdtls
```

Then restart nvim.

### Python-related errors

The jdtls wrapper requires Python:

```powershell
scoop install python
```

### QueryDSL Q-classes not recognized

The Q-classes were not generated, or jdtls cannot find the generated source path.

**1. Generate Q-classes:**

```powershell
# Windows
cd <project-root>
.\gradlew compileQuerydsl
# or
.\gradlew compileJava
```

```bash
# macOS/Linux
./gradlew compileQuerydsl
```

**2. Restart the LSP in nvim:**

```vim
:LspRestart
```

**3. If it still doesn't work:**

```powershell
# 1. delete the build folder and rebuild
.\gradlew clean build

# 2. clear the jdtls cache
rm -r -Force "$env:APPDATA\jdtls"

# 3. delete .classpath, .project (jdtls regenerates them)
rm .classpath, .project -ErrorAction SilentlyContinue
```

```bash
# macOS/Linux
./gradlew clean build
rm -rf ~/Library/Caches/jdtls  # macOS
rm -rf ~/.cache/jdtls          # Linux
rm -f .classpath .project
```

Then restart nvim.

**4. Check the generated source path (build.gradle):**

```groovy
sourceSets {
    main {
        java {
            srcDirs = ['src/main/java', 'build/generated/querydsl']
        }
    }
}
```

## Related Files

- [`clang-engineer/jvm-env.nvim`](https://github.com/clang-engineer/jvm-env.nvim) — external plugin for JDK detection/environment variable injection (source · README · vimdoc)
- `nvim/lazy/lua/plugins/jvm-env.lua` — lazy spec for the external plugin
- `nvim/lazy/lua/plugins/java.lua` — connects nvim-jdtls with jvm-env environment variables
- `:JvmEnvInit [jdtls] [gradle]` — command to generate `.nvim.lua` in the project root (provided by jvm-env.nvim). Details: `nvim/docs/java-lsp.md`
