# LazyVim Java LSP notes

## Goal
- Run jdtls on Java 21+
- Keep Gradle/build on the JDK the project requires (separate from jdtls)

## Recommended — use jvm-env

### Per-project `.nvim.lua` (one line)
```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

Generate it from the project root with `:JvmEnvInit 21 17` (omit the args to reuse the active config).

### Global auto-detection
The lazy spec in `nvim/lazy/lua/plugins/jvm-env.lua` (`lazy=false, priority=100`) calls
[`clang-engineer/jvm-env.nvim`](https://github.com/clang-engineer/jvm-env.nvim)'s `setup` on startup —
with defaults `jdtls=21`, `gradle=11` it auto-populates `vim.env.JDTLS_JAVA_HOME` / `vim.env.GRADLE_JAVA_HOME`.

### jdtls wiring
`nvim/lazy/lua/plugins/java.lua` reads those two env vars and wires them into jdtls `cmd` and `cmd_env`:
- appends `--java-executable $JDTLS_JAVA_HOME/bin/java` to `cmd`
- `cmd_env.JAVA_HOME = $GRADLE_JAVA_HOME` + `GRADLE_OPTS=-Dorg.gradle.java.home=...`
- if a Lombok jar is present, adds `--jvm-arg=-javaagent:...` automatically

## env template (export from the shell)
```bash
export JDTLS_JAVA_HOME="/path/to/jdk-21"
export GRADLE_JAVA_HOME="/path/to/jdk-17"
```
In this case the shell values are used as-is, without calling `jvm-env.setup`.

## Reference — manual setup without jvm-env (per-OS snippets)

The old way of populating the env vars directly inside `.nvim.lua`. jvm-env absorbs all of these branches.

### macOS
```lua
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21"))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 17"))
```

### Linux (paths vary by distro)
```lua
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system("readlink -f /usr/lib/jvm/java-21-openjdk"))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system("readlink -f /usr/lib/jvm/java-17-openjdk"))
```

### Windows (read from env)
```lua
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system(
  "powershell -NoProfile -Command \"[Environment]::GetEnvironmentVariable('JDTLS_JAVA_HOME','User')\""
))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system(
  "powershell -NoProfile -Command \"[Environment]::GetEnvironmentVariable('GRADLE_JAVA_HOME','User')\""
))
```
