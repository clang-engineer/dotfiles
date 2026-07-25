# vim-dadbod-connection-picker

A small helper plugin for `vim-dadbod-ui` that organizes connection files into
connection groups and provides a grouped picker to search, open, and edit DB
connections.

## Why this plugin

This plugin is intentionally kept minimal: it does not replace DB adapters or UI
behavior, it only improves the “pick a connection group / pick a connection”
workflow used by `vim-dadbod-ui`.

## Current features (stable)

- Load DB connections from group files under `connections/`.
- Show connections in a grouped picker (`:DBConnections`).
- Press Enter on a group row to expand/collapse it.
- Press Enter on an `Open all (...)` row or a connection row to open the connection.
## Interaction
- Search and action hints are shown inside the picker.
- Shortcuts:
  - `/` filter
  - `<CR>` open
  - `a` add connection to selected group
- `n` add group
- `e` edit selected group file
- `r` rename selected group file
- `d` delete selected row (group or connection)
- `u` restore selected group from latest backup when available

## Setup

```lua
require("user.vim-dadbod-connection-picker").setup({
  icon_style = "ascii",           -- "ascii" | "emoji" | "nerd"
  confirm_open = false,           -- set true to confirm before opening a connection/group
  confirm_open_group = false,     -- set true to confirm before opening all connections in a group
  confirm_modify = false,         -- set true to confirm before adding/renaming
  confirm_delete = true,          -- set false to skip confirm for delete (group/connection)
  group_labels = {},
  group_placeholders = {
    { name = "example", url = "postgresql://localhost:5432/db" },
  },
})
```

## Group file format

Create `connections/<group>.lua`:

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
- `:DBConnections add <group>` : create a new group file and open it
- `:DBConnections new <group>` : alias of `add`
- `:DBConnections edit <group>` : open group file directly
- `:DBConnections <group>` : open all connections in a single group
- `:DBConnections all` : open all configured connection groups
- `:DBConnections restore <group>` : restore selected group from latest backup file
- `:DBConnections help` or `:DBConnections ?` : show usage

Keymap in picker:
- `a` on a selected group row: add a connection entry with prompted name/url to that group.
- `n` in picker: add a new group (and open its file immediately).
- `r` in picker: rename the selected group file.
- `d` in picker: delete the selected group file or connection row.

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
