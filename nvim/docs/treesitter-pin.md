# nvim-treesitter pin (Neovim 0.11 vs main branch)

`nvim-treesitter` in `lazy-lock.json` tracks the **`main` branch (the rewrite)**, not
`master`. The `main` branch uses **Neovim 0.12+ APIs** (`vim.list.unique`, etc.), so on
**0.11.x** an install/update **silently fails** — the old parsers stay in place and no
longer match the new queries (`..<`, `tab`, …), which surfaces as query errors in
pickers / noice (`Invalid node type "..."`).

## How LazyVim guards it

LazyVim commit-pins `nvim-treesitter` to a safe commit when `vim.fn.has("nvim-0.12") == 0`:

```
"nvim-treesitter": { "branch": "main", "commit": "7caec274fd19c12b55902a5b795100d21531391f" }
```

The trap: running `:Lazy update` **overwrites this pin** in the lockfile with a newer
`main` commit, which then breaks on 0.11. This actually broke the kotlin/vim parsers on
2026-05-08; recovery was a plugin rollback + forced recompile:

```lua
require('nvim-treesitter').install({ 'kotlin', 'vim' }, { force = true }):wait()
```

## Rules

- On **0.11.x**, keep `nvim-treesitter` at LazyVim's 0.11 pin. If the lockfile points at a
  newer `main` commit than the one above, that's the suspect.
- A treesitter query error is **not** fixable with `:TSUpdate`. First check `nvim --version`
  and the `nvim-treesitter` commit in `lazy-lock.json`.
- Moving to a 0.12 nightly is the real fix, but this machine stays on 0.11.5 stable.
