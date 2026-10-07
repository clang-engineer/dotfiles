# db

A Go launcher that selects a database target and adapts its connection catalog to
Harlequin, Rainfrog, and Neovim configuration formats. Requires `fzf` for selection
and the selected database client (including its driver/adapter).

## Setup

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
All `~/.config` paths below honor `XDG_CONFIG_HOME`.

```sh
db sync           # generate persistent client configurations
db                # sync, then launch saved default or select interactively
db --select       # sync, then select tool → project → connection
db --set-default  # select and save default tool/connection
db init zsh       # print zsh completion
```

Help, completion, and fzf previews do not regenerate files.

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

To avoid specifying the path for direct execution, link the Harlequin file into
its native config location, or persist `RAINFROG_CONFIG` in your shell configuration.
These are optional client integrations, not required source-path settings for `db`.
Existing native client configs are not automatically overwritten or linked.
Point your Neovim connection loader at the generated `nvim/` directory.
After editing source files, run `db sync` before launching clients directly.

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

## Verification

```sh
go test ./...
go vet ./...
go build ./...
```
