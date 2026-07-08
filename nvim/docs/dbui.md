# vim-dadbod / dadbod-ui usage

## Overview

LazyVim's `lang.sql` extra is enabled, so these three plugins are installed automatically:

| Plugin | Role |
|--------|------|
| `tpope/vim-dadbod` | DB adapter (drives `postgres`, `mysql`, `sqlite`, `mongodb`, etc.) |
| `kristijanhusak/vim-dadbod-ui` | Sidebar UI (`:DBUIToggle`) |
| `kristijanhusak/vim-dadbod-completion` | SQL completion |

Connection definitions are managed in the `vim.g.dbs` table in `nvim/lazy/lua/config/options/dbui.lua`.

## Adapter limitations

vim-dadbod's built-in adapters: `postgres`, `mysql`, `sqlite`, `sqlserver`, `mongodb`, `redis`, `oracle`, `bigquery`, `clickhouse`, `duckdb`, and more.

**JDBC URLs are not supported.**

| Wrong URL | Result |
|-----------|--------|
| `jdbc:postgresql://...` | `E605: no adapter for jdbc` |
| `jdbc:h2:file:...` | `E605: no adapter for jdbc` |

→ Drop the JDBC prefix and use a scheme dadbod recognizes (`postgres://`, `postgresql://`, etc.).
**H2 has no adapter, so use the H2 Web Console or the IntelliJ Database tool instead of dadbod.**

## URL format

```lua
vim.g.dbs = {
  {
    name = "docker postgres",
    url = "postgres://myuser@localhost:5432/mydb",
  },
  {
    name = "remote postgres (SSH tunnel)",
    url = "postgresql://REMOTE_HOST:5432/mydb?connect_timeout=5",
  },
}
```

- `name` is the label shown in the sidebar.
- **Never hardcode the password in the URL** — keep it in `~/.pgpass` (the connection file is overlaid by the `secrets` repo).
- Add `?connect_timeout=5` to remote/VPN-dependent entries to fail fast (libpq's default timeout is very long, so nvim appears to hang).

## Auth setup (`.pgpass`)

dadbod invokes `psql` non-interactively, so the password prompt does not work. There are two setup options:

| Method | Multi-DB support | Recommended |
|--------|:---:|:---:|
| `$PGUSER` / `$PGPASSWORD` env vars | ❌ session-global, can't hold a different password per DB | No |
| `~/.pgpass` file | ✅ split per host:port:db | Yes |

### Setup procedure

`~/.pgpass` is owned by the private `secrets` repo. After `chezmoi apply` pulls secrets via
`.chezmoiexternal`, `run_after_30-secrets-overlay.sh` → `secrets/setup.sh` symlinks
`secrets/postgres/pgpass` to `~/.pgpass` and sets the source to permission 600.
Since the password lives in the repo, no hand-editing is needed on a new machine. Public users
without secrets access can create it by hand from `scripts/.pgpass.example`
(Windows: `%APPDATA%\postgresql\pgpass.conf`):

```
localhost:5432:mydb:myuser:CHANGE_ME
REMOTE_HOST:5432:mydb:myuser:CHANGE_ME
```

## Usage

| Command | Description |
|---------|-------------|
| `:DBUIToggle` | Toggle the sidebar |
| `:DBUI` | Open the sidebar |
| `:DBUIAddConnection` | Add a connection (session-only; add it to `dbui.lua` to persist) |
| `:DBUIFindBuffer` | Find the current SQL buffer in the sidebar |

In the sidebar, put the cursor on a DB entry and press `<CR>` to expand it and load schemas/tables.
`<CR>` on a table runs a predefined query (e.g. `SELECT * FROM ... LIMIT 200`).

### Writing/running your own queries

An expanded DB tree has a `New query` entry. Press `<CR>` on it to open an empty SQL scratch buffer bound to that DB.

| Action | Mapping |
|--------|---------|
| Run the whole query | `<leader>S` |
| Run only the selection | visual-select, then `<leader>S` |
| Save the query (adds to the Saved queries tree) | `<leader>W` |
| Maximize / equalize the result window | `<C-w>_` / `<C-w>=` |

To run an existing `.sql` file, connect it to the sidebar with `:DBUIFindBuffer`, or run it directly with `:%DB <url>`.

### Result window layout

The result window dadbod opens with `:split` (filetype `dbout`) keeps the horizontal split, but the autocmd in `dbui.lua` handles two things automatically:

- **Disables folding** (`setlocal nofoldenable`) — officially recommended by the vim-dadbod-ui maintainer (in the comment when PR #203 was rejected).
- **Resizes to half the screen height** (`resize lines/2`) — the default split is too narrow and clips result rows.

If it feels cramped, use `<C-w>_` (max height); `<C-w>=` to equalize back.

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `E605: no adapter for jdbc` | URL starts with `jdbc:postgresql://` → remove the `jdbc:` prefix |
| `fe_sendauth: no password supplied` | Missing host:port:db line in `.pgpass`, or its permission isn't 600 |
| nvim hangs for a while on connect | Add `?connect_timeout=5` to the URL |
| Remote DB connection timeout | Check VPN/firewall. Test directly with `psql -h <host> -U <user> -d <db>` to isolate whether it's a dbui-external problem |
| `.pgpass` not being read | On Unix, `chmod 600 ~/.pgpass` is required. On Windows, check the `%APPDATA%\postgresql\pgpass.conf` location |

## Adding another DB (mysql / oracle / mssql)

`.pgpass` is PostgreSQL-only. Other DBs use their own standard auth file:

| DB | Standard auth file / method |
|----|-----------------------------|
| MySQL | `~/.my.cnf` (`[client]` section) or `~/.mylogin.cnf` (mysql_config_editor) |
| Oracle | Oracle Wallet (`mkstore`) + `tnsnames.ora` |
| SQL Server | No standard file — `SQLCMDPASSWORD` env var or Windows auth (`-E`) |

Per-DB setup scripts are added under the same convention as `scripts/setup-<db>-auth.sh` when a DB is actually added.

## References

- vim-dadbod: <https://github.com/tpope/vim-dadbod>
- vim-dadbod-ui: <https://github.com/kristijanhusak/vim-dadbod-ui>
- libpq pgpass docs: <https://www.postgresql.org/docs/current/libpq-pgpass.html>
