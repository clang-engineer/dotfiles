# harlequin-config

A Go configuration generator that turns a database connection catalog into native
Harlequin profiles. It does not select connections, save launch choices, launch
database clients, or generate Rainfrog/Neovim configuration.

## Setup

The managed generator supports macOS/Linux only. Windows excludes its build hook
and shell wrapper.

`chezmoi apply` builds `~/.local/libexec/harlequin-config` and installs the
`harlequin-config` wrapper. For a manual build, run
`go build -o ~/.local/libexec/harlequin-config .` from this directory.

By default, put connection TOML files in `~/.config/db/connections/`.
For an existing catalog elsewhere, register it once:

```sh
harlequin-config init --source /path/to/connections
```

This validates the catalog and saves its absolute path in
`~/.config/db/config.toml`, preserving unrelated settings and removing obsolete
`tool` and `connection` settings. It does not copy or modify the original catalog.
All `~/.config` paths below honor `XDG_CONFIG_HOME`. Generation ignores obsolete
launch settings and never persists a last choice.

```sh
harlequin-config           # generate persistent Harlequin profiles
harlequin-config init zsh  # print generator and Harlequin profile completion
```

Help and completion do not regenerate files or connect to a database.
The former `db` executable, `sync`, `--select`, previews, and default/launch
commands are not supported. Select a connection with native `harlequin -P`
completion instead.

To configure Harlequin keymaps, set `harlequin_keymaps = "vscode"` or
`harlequin_keymaps = ["vscode", "vim"]` in `~/.config/db/config.toml`.
The generator writes the nonempty, trimmed names to each Harlequin profile's
native `keymap_name` list, preserving order. When omitted, Harlequin uses its
native default. The former `DB_HARLEQUIN_KEYMAPS` environment override is not used.

## Catalog

Each filename is a project ID; connection IDs must be unique across files.
Project and connection IDs use lowercase letters, digits, and hyphens. Every
connection becomes a Harlequin profile; `label` and `tools` are not needed.

```toml
# connections/local.toml
[local-postgres]
driver = "postgres"
host = "localhost"
port = 5432
database = "example"
username = "example"
password = ""
params = { sslmode = "disable" }
```

Supported drivers: `postgres`, `vertica`, and `h2`.
H2 uses `url = "jdbc:h2:..."` instead of host/port/database; put H2 parameters in
the URL. Harlequin needs the corresponding installed adapter. Credentials belong
in private files, never in this repository. Source files should have mode 0600.

Vertica profiles use the `harlequin-odbc-vertica` plug-in (`odbc-vertica`),
which fixes Vertica catalog metadata that the generic `odbc` adapter cannot
retrieve. Install it into Harlequin's Python environment. Separately, install
the native Vertica ODBC driver and register it with unixODBC as `Vertica`.
DataGrip's JDBC driver and `vsql` do not replace this ODBC driver.

### macOS: Vertica ODBC connection errors

The native driver is available through the [Rocket Customer Community download
portal](https://my.rocketsoftware.com/RocketCommunity/RCLogin) after login:
**Download → SELECT A PRODUCT: Vertica → macOS ODBC**.

This machine used an Apple Silicon Homebrew unixODBC and a vendor `.pkg`, but
driver locations and installation methods vary by machine. The `.pkg` put
`libverticaodbc.dylib` in `/Library/Vertica/ODBC/lib/` and registered it in
`/etc/odbcinst.ini`. Homebrew unixODBC reads its own driver registry instead;
check the active path and driver name:

```sh
odbcinst -j
odbcinst -q -d
odbcinst -q -d -n Vertica
```

**`Can't open lib 'Vertica' : file not found`** means unixODBC cannot resolve
`DRIVER={Vertica}`. If the library is installed but `odbcinst -q -d` does not
list `[Vertica]`, add this stanza to the active `odbcinst.ini` reported by
`odbcinst -j`, using the *actual* library path on that machine (do not copy
the vendor's `[ODBC Drivers]` section):

```ini
[Vertica]
Driver = /path/to/libverticaodbc.dylib
```

**`('H000', '[H000] [ (50404) (SQLDriverConnect)')`** occurred here after
registration because the vendor's `vertica.ini` targeted iODBC (`UTF-32` and
`libiodbcinst.dylib`), while Harlequin's `pyodbc` used Homebrew unixODBC.
For that combination, create a **machine-local**, untracked `vertica.ini`
in `${XDG_CONFIG_HOME:-$HOME/.config}/db/`, using the installed driver's
messages directory and the *actual* unixODBC installer library path:

```ini
[Driver]
ErrorMessagesPath=/path/to/vertica/messages/
ODBCInstLib=/path/to/libodbcinst.2.dylib
DriverManagerEncoding=UTF-16
```

The managed Bash, Zsh, and Fish configurations export this file as `VERTICAINI` if present;
an existing environment value takes precedence. This Mac's verified paths are
`/Library/Vertica/ODBC/messages/` and
`/opt/homebrew/lib/libodbcinst.2.dylib`. Do not copy them to a different Mac
without checking its installation. `odbcinst -q -d` alone only verifies
registration, not this encoding mismatch; a successful native `harlequin` launch
reaches the Harlequin Data Catalog.

## Use Harlequin directly

`harlequin-config` writes only `~/.config/db/harlequin.toml`. It contains every
connection as a native Harlequin profile, with ID hyphens converted to underscores
(for example, `local-postgres` becomes `local_postgres`).

```sh
harlequin --config-path "${XDG_CONFIG_HOME:-$HOME/.config}/db/harlequin.toml" -P local_postgres
```

The managed Bash, Zsh, and Fish configurations point `HARLEQUIN_CONFIG_PATH` at the generated
Harlequin file when it exists, preserving an already-set value. This lets
`harlequin -P local_postgres` run directly. Outside the managed shell, export
`HARLEQUIN_CONFIG_PATH` yourself or link the file into a native config location.
Existing native Harlequin configs are not automatically overwritten or linked.
After editing source files, run `harlequin-config` before launching Harlequin.

### Fish profile completion

Chezmoi installs fish completions for `harlequin` and `harlequin-config`.
After generating profiles, type `harlequin -P` and press Tab to search them
with fzf, with or without a space after `-P`. Enter inserts the selected name;
a second Enter launches Harlequin.
Esc cancels without changing the command line. `--profile` and an explicit
`--config-path` are supported too. Other completion positions keep fish's
normal completion UI; without fzf, profile completion also uses that UI.
The picker inherits the shared fzf color theme through `FZF_DEFAULT_OPTS_FILE`,
but clears `FZF_DEFAULT_OPTS` to isolate global actions and output options.
Single selection and Enter/Esc/Ctrl+C handling use fzf's native defaults.

The picker uses the same names-only generator endpoint as zsh completion.
It does not generate configuration or connect to a database, and requires no
fish plug-in manager or zsh plug-ins.


### Zsh profile completion

The managed zsh configuration already evaluates `harlequin-config init zsh`. For another zsh
setup, load it after `compinit`:

```sh
eval "$(harlequin-config init zsh)"
```

In the managed shell, type `harlequin -P ` and press Tab to open an fzf picker.
Type to search, use arrow keys to select a profile, and press Enter to insert its
name. A second Enter executes the command; Esc cancels the picker without
changing the command line. `--profile` uses the same picker.

`fzf-tab` is installed through `packages/Brewfile` and loaded after fzf's shell
integration, before autosuggestions and syntax highlighting. It is enabled only
for Harlequin; other commands retain their existing completion UI. Atuin's
Ctrl+R history search and fzf's Ctrl+T file selection are unchanged. No tmux
plugin or tmux session is required.

Without `fzf-tab`, Tab lists the candidates using the regular zsh completion UI.
Press Tab again to enter the selection menu; arrow-key selection requires
`zstyle ':completion:*' menu select`, which the managed shell already enables.

Completion supports `-P`, `--profile`, and explicit `--config-path` values. It reads
profile names from Harlequin's current-directory, platform-config, and home config
files, plus the file selected by `--config-path` or `HARLEQUIN_CONFIG_PATH` (CLI
takes precedence). `pyproject.toml` uses `[tool.harlequin.profiles]`. Duplicate
names appear once; `None` is Harlequin's built-in option to bypass the default
profile. Credentials are not included in the candidates.

Run `harlequin-config` after changing the source catalog. The next completion reads
updated files without reloading zsh; completion itself never generates configs.
After installing a new binary or changing shell setup, reload the completion
registration with `eval "$(harlequin-config init zsh)"` or open a new shell.

The generated file is private (0600), replaced atomically, and may contain
credentials. Validation/rendering completes before writing. An existing symlink
at `harlequin.toml` is replaced without modifying its former target.

## Migration from generate.py

Register the directory containing your connection TOML files, then run
`harlequin-config`. The private companion keeps these directly in
`databases/*.toml`; its `setup.sh` registers that directory. `index.toml` and
Python/StyLua are no longer required by this generator. Connection `label` and
`tools` fields can be removed; any remaining values are ignored, so former
Rainfrog-only or Neovim-only connections also become Harlequin profiles.

Generation retires regular `rainfrog_config.toml` and `nvim/*.lua` files under
`~/.config/db/` only when the first line is exactly the appropriate comment:
`# Generated by harlequin-config. Do not edit.` or
`# Generated by db sync. Do not edit.` for TOML, with `--` instead of `#` for Lua.
The marker must end with a newline. Manual files, file symlinks (including dangling
ones), directory symlinks, and their targets are preserved. No Rainfrog or Neovim
configuration is generated; maintain any configurations still needed for those
clients separately.

Update direct-client and Neovim integrations that still reference the old
`databases/generated/` tree. The private companion's bootstrap no longer links
Neovim connection lists or depends on Python or `databases/generated/`. Other
installations must likewise update old bootstrap scripts before removing their
previous generator and generated files.

## Code layout

```text
main.go                 # executable entry point: exit status and error reporting
internal/
  app/                 # generator CLI, config, Harlequin rendering, output writes
  catalog/             # connection model, TOML source validation, URL encoding
  storage/             # TOML serialization and private atomic file writes
```

Dependencies flow from `main.go` → `app` → `catalog` / `storage`.
Neither catalog nor storage depends on app or on each other. Only `app.Run` is
exposed by the application package. App is intentionally grouped into a few files
(`app.go`, `client.go`, `config.go`, `sync.go`) instead of one file per helper.
Catalog and storage have their own public-API tests, while app tests cover
integration, generation, configuration, and native profile completion behavior.

Catalog maps are passed explicitly; no global mutable connection state is used.
The chezmoi build hook recursively hashes every Go file, including new packages.

## Verification

```sh
go test ./...
go vet ./...
go build ./...
```
