# vim-dadbod-ui-profiles

DB connection profile picker for `vim-dadbod-ui` with grouped profile list from Lua files.

## Current features (stable)

- Load DB connections from profile files under `connections/`.
- Show profiles in a grouped picker (`:DBUIProfile`).
- Press Enter on a profile row to expand/collapse it.
- Press Enter on an `Open all (...)` row or a connection row to open the connection.
- Open a connection file from the manager with `:DBUIProfile manage`.

## Known limitations (by design for stable release)

- `manage` mode only provides open behavior (no add/edit/delete shortcuts in this minimal release).
- No custom picker keymaps are registered (`h/l/o/<C-y>` are not bound).
- Connection list actions are intentionally kept to picker confirm (`<CR>`).

## Setup

```lua
require("user.vim-dadbod-ui-profiles").setup({
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

- `:DBUIProfile` : open grouped profile picker
- `:DBUIProfile manage` : open manager list
- `:DBUIProfile edit <profile>` : open profile file directly

## Notes

- Picker layout is fixed to floating dropdown style. (`dropdown` preset)
- `picker_layout` option is intentionally not exposed in this build.

- This plugin is designed to be vendored from your dotfiles and used with your existing
  `vim-dadbod-ui` + `folke/snacks.nvim` setup.
