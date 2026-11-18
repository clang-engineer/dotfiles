# db

A Go launcher that selects a database target and adapts its connection catalog to
Harlequin, Rainfrog, and Neovim configuration formats. Requires `fzf` for selection
and the selected database client (including its driver/adapter).

## Setup

The managed launcher currently supports macOS/Linux only. Windows excludes both
its build hook and shell wrapper.

`chezmoi apply` builds `~/.local/libexec/db` and installs the `db` wrapper.
For a manual build, run `go build -o ~/.local/libexec/db .` from this directory.

By default, put connection TOML files in `~/.config/db/connections/`.
For an existing catalog elsewhere, register it once:

```sh
db init --source /path/to/connections
```

This validates the catalog and saves its absolute path in
`~/.config/db/config.toml`, preserving existing defaults. It does not copy or
modify the original catalog. No environment variable is required.
All `~/.config` paths below honor `XDG_CONFIG_HOME`. Set `tool = "harlequin"`
in `~/.config/db/config.toml` to make interactive launches skip the tool picker;
Harlequin is the default when it is omitted. Each interactive selection is saved
as the next `db` launch target.

```sh
db sync           # generate persistent client configurations
db                # sync, then launch the last selected database
db --select       # sync, then select and save a Harlequin project → connection
db init zsh       # print db command and Harlequin profile completion
```

Help, completion, and fzf previews do not regenerate files or connect to a database.

## Catalog

Each filename is the project ID; connection IDs must be unique across files.
Project and connection IDs use lowercase letters, digits, and hyphens.

```toml
# connections/local.toml
[local-postgres]
label = "Local PostgreSQL"
driver = "postgres"
host = "localhost"
port = 5432
database = "example"
username = "example"
password = ""
tools = ["harlequin", "rainfrog", "nvim"]
params = { sslmode = "disable" }
```

Supported drivers: `postgres`, `vertica` (Harlequin/Neovim), `h2` (Harlequin).
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

The managed `db` wrapper reads this file if present; an existing `VERTICAINI`
environment variable takes precedence. This Mac's verified paths are
`/Library/Vertica/ODBC/messages/` and
`/opt/homebrew/lib/libodbcinst.2.dylib`. Do not copy them to a different Mac
without checking its installation. `odbcinst -q -d` alone only verifies
registration, not this encoding mismatch; a successful `db` launch reaches
the Harlequin Data Catalog.

## Use clients directly

`db sync` writes persistent files, not launcher-only temporary profiles:

| Output under `~/.config/db/` | Purpose |
| --- | --- |
| `harlequin.toml` | All Harlequin profiles (ID hyphens become underscores) |
| `rainfrog_config.toml` | All Rainfrog profiles; passwords remain in the platform keychain |
| `nvim/<project>.lua` | Neovim connection lists |

```sh
harlequin --config-path "${XDG_CONFIG_HOME:-$HOME/.config}/db/harlequin.toml" -P local_postgres
RAINFROG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/db" rainfrog
```

The managed zsh configuration points `HARLEQUIN_CONFIG_PATH` at the generated
Harlequin file when it exists, preserving an already-set value. This lets
`harlequin -P local_postgres` run directly. Outside the managed shell, export
`HARLEQUIN_CONFIG_PATH` yourself or link the file into a native config location.
Persist `RAINFROG_CONFIG` separately if you use Rainfrog directly.
Existing native client configs are not automatically overwritten or linked.
Point your Neovim connection loader at the generated `nvim/` directory.
After editing source files, run `db sync` before launching clients directly.

### Zsh profile completion

The managed zsh configuration already evaluates `db init zsh`. For another zsh
setup, load it after `compinit`:

```sh
eval "$(db init zsh)"
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

Run `db sync` after changing the source catalog. The next completion reads the
updated files without reloading zsh; completion itself never syncs the catalog.
After installing a new `db` binary or changing shell setup, reload the completion
registration with `eval "$(db init zsh)"` or open a new shell.

Generated files are private (0600), replaced atomically per file, and may contain
credentials. Validation/rendering completes before writing. Writes across multiple
files are not a single transaction. The launcher gives Rainfrog a separate temporary
selected/default profile and removes it on normal exit; persistent profiles stay
unchanged. Rainfrog authentication continues to use its platform keychain.

## Migration from generate.py

Register the directory containing your connection TOML files, then run `db sync`.
The private companion now keeps these directly in `databases/*.toml`;
its `setup.sh` registers that directory and connects Neovim to the new outputs.
`index.toml` and Python/StyLua are no longer required by this launcher.
Existing file symlinks for generated Harlequin/Rainfrog configs are replaced with
local generated files without modifying their former targets. Change direct-client
and Neovim integrations that still reference the old `databases/generated/` tree.
The private companion's updated bootstrap no longer depends on Python or
`databases/generated/`. Other installations must likewise update old bootstrap
scripts before removing their previous generator and generated files.

## Code layout

```text
main.go                 # executable entry point: exit status and error reporting
internal/
  app/                 # CLI orchestration, config, selection, client adapters, sync
  catalog/             # connection model, TOML source validation, URL encoding
  storage/             # TOML serialization and private atomic file writes
```

Dependencies flow from `main.go` → `app` → `catalog` / `storage`.
Neither catalog nor storage depends on app or on each other. Only `app.Run` is
exposed by the application package. App is intentionally grouped into a few files
(`app.go`, `client.go`, `config.go`, `sync.go`) instead of one file per helper.
Catalog and storage have their own public-API tests, while app tests cover
integration and launcher behavior.

Catalog maps are passed explicitly; no global mutable connection state is used.
The chezmoi build hook recursively hashes every Go file, including new packages.

## Verification

```sh
go test ./...
go vet ./...
go build ./...
```
