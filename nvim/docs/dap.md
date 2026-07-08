# Neovim DAP (Debug Adapter Protocol) usage

## Keymaps

DAP is lazy-loaded, so `:Dap*` commands are only active once a Java/Kotlin file is open.
If they don't show up, call `:lua require("dap").continue()` directly.

The core `<leader>d*` keymaps come from LazyVim's `dap.core` extra (`<leader>db` toggle breakpoint,
`<leader>dc` continue, `<leader>di/do/dO` step, `<leader>du` DAP UI, etc.) — see the
[LazyVim dap.core keymaps](https://www.lazyvim.org/extras/dap/core) for the full list.

The rest of this doc covers only the setup that is specific to this config.

## Java debugging (jdtls launch)

### Setup

LazyVim's `lang.java` extra enables DAP automatically (no extra config needed).

### Usage

1. Open a Java file
2. Set a breakpoint (`<leader>db`)
3. `:lua require("dap").continue()` or `<leader>dc`
4. Pick a launch config from the list

jdtls runs the JVM in debug mode itself, so no separate Gradle run is needed.

> Java DAP also uses `console = "integratedTerminal"` (`java.lua`'s `dap.config_overrides`).
> The program output stays in nvim's built-in terminal, so it's still readable after the session ends.

## Java/Kotlin debugging (Gradle attach)

The traditional approach: start the JVM in debug mode manually, then attach.

### Step 1: run Gradle in debug mode

```bash
# debug a test
./gradlew test --debug-jvm

# debug Spring Boot
./gradlew bootRun --debug-jvm
```

It's ready once you see `Listening for transport dt_socket at address: 5005`.

### Step 2: attach from nvim

1. Set a breakpoint (`<leader>db`)
2. `:lua require("dap").continue()` or `<leader>dc`
3. Pick "Attach to debugging session" from the list

### Step 3: open the UI

```
:lua require("dapui").toggle()
```

or `<leader>du`

### Attach to an already-running JVM

Add the following to the JVM options to allow a debug attach on port 5005:

```
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

Change `suspend=y` to make the JVM wait until a debugger connects.

## Kotlin DAP setup

See `kotlin-dap.lua`. Uses kotlin-debug-adapter.

- **launch**: run the current file's `main()` directly (for a single file)
- **attach**: connect to a JVM started with Gradle `--debug-jvm` (Spring Boot, etc.)
- **console**: `integratedTerminal` — program output shows in nvim's built-in terminal buffer, readable after the session ends
- **dapui auto-close disabled**: dapui does not close automatically on debug failure/exit. Close it manually with `<leader>du` or `:lua require("dapui").toggle()`

## Recommended workflow

| Situation | Approach |
|-----------|----------|
| Java unit test | jdtls launch (easiest) |
| Spring Boot | jdtls launch or Gradle attach |
| Kotlin | Gradle attach (`--debug-jvm`) |
| Remote JVM | attach (specify the port) |
