# vim-dadbod-connection-picker

A small helper plugin for `vim-dadbod-ui` that organizes connection files into
connection groups and provides a grouped picker to search, open, and edit DB
connections.

## Why this plugin

This plugin is intentionally kept minimal: it does not replace DB adapters or UI
behavior, it only improves the “pick a connection group / pick a connection”
workflow used by `vim-dadbod-ui`.

## Current features (stable)

- Load DB connections from profile files under `connections/`.
- Show connections in a grouped picker (`:DBConnections`).
- Press Enter on a profile row to expand/collapse it.
- Press Enter on an `Open all (...)` row or a connection row to open the connection.
## Known limitations (by design for stable release)
- No custom picker keymaps are registered (`h/l/o/<C-y>` are not bound).
- Connection list actions are intentionally kept to picker confirm (`<CR>`).

## Setup

```lua
require("user.vim-dadbod-connection-picker").setup({
  icon_style = "emoji",           -- "ascii" | "emoji" | "nerd"
  profile_labels = {},
})
```

## Profile file format

Create `connections/<profile>.lua`:

```lua
return {
  { name = "local", url = "postgresql://..." },
  { name = "stg", url = "postgresql://..." },
}
```

Files can be omitted from tracking via `connections/.gitignore` (symlinked secrets are expected in
private environments).

## Commands

- `:DBConnections` : open grouped connection picker
- `:DBConnections edit <group>` : open group file directly

## Requirements / Dependencies

- `kristijanhusak/vim-dadbod-ui`
- `tpope/vim-dadbod` (required by `vim-dadbod-ui`)
- `folke/snacks.nvim`

`vim-dadbod-ui` provides the DB drawer and connection runner; this plugin is just
the connection-group picker workflow on top of it.

## Notes

- Picker layout is fixed to floating dropdown style. (`dropdown` preset)
- `picker_layout` option is intentionally not exposed in this build.

- This plugin is designed to be vendored from your dotfiles and used with your existing
  `vim-dadbod-ui` + `folke/snacks.nvim` setup.
