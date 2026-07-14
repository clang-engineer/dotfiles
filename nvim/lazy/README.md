# 💤 LazyVim

Neovim config based on [LazyVim](https://github.com/LazyVim/LazyVim). For the starter template, see the [official docs](https://lazyvim.github.io/installation).

## Load structure — what gets loaded "automatically"

The perennially confusing part. **There are only 3 kinds of auto-load triggers; everything else has to be `require`d by hand to come alive.**

| What loads automatically | Owner | Mechanism |
| --- | --- | --- |
| The **entire `lua/plugins/` folder** | lazy.nvim | `lazy.lua`'s `{ import = "plugins" }` scans the folder |
| The **three filenames** `lua/config/{options,keymaps,autocmds}.lua` | LazyVim | The lifecycle requires these exact names |
| `init.lua` | Neovim | The one entry point read at startup (only this filename is mandatory) |

> **The only folder scanned wholesale is `lua/plugins/`.** `config/` is not a folder scan — only the three fixed filenames are auto-required (dropping in a new `config/foo.lua` won't be called). Everything else under `lua/` runs only if something `require`s it.

The three `config/{options,keymaps,autocmds}.lua` files are **optional override hooks, not requirements**. The LazyVim loader requires them only if they exist (via `_load` in `lazyvim/config/init.lua`), so if they're missing there's no error — just the LazyVim defaults. The only truly mandatory file is `init.lua` (Neovim); `config/lazy.lua` is merely the bootstrap that `init.lua` points to with `require("config.lazy")` — its name and location are free to choose.

### The actual load chain

```
init.lua                              ← [Neovim] entry point
 ├─ require("config.lazy")            ← direct require
 │   └─ lazy.setup():
 │        ├─ { import = "plugins" }   → auto-scans lua/plugins/* folder   [lazy.nvim]
 │        └─ load LazyVim → lifecycle auto-requires:
 │             ├─ config/options.lua  (immediately, before UI)
 │             ├─ config/keymaps.lua  (VeryLazy)
 │             └─ config/autocmds.lua (VeryLazy)
 └─ require("user.docs").setup()      ← direct require
```

There are only three top-level `lua/` entries — `config/` (LazyVim rules), `plugins/` (lazy.nvim specs), and `user/` (all the code I wrote). Grouping my personal modules under `user/` avoids global namespace collisions (especially generic names like `db`) and cleanly separates framework code from mine at a glance.

Modules that LazyVim and lazy.nvim know nothing about, living **purely off the require chain**:

| Module | Who loads it |
| --- | --- |
| `config/options/*.lua` | required directly by `config/options.lua` |
| `config/autocmds/*.lua` | required directly by `config/autocmds.lua` |
| `user/db/` (init + connections) | `init` in `plugins/dadbod.lua` calls `require("user.db")` |
| `user/docs/` | `init.lua` calls `require("user.docs").setup()` |

Adding a file to `user/db/connections/` gets picked up automatically not because of a LazyVim folder scan, but because **`user/db/init.lua` runs a runtime glob itself**.

### Pitfalls

- When you create a new subfile in `config/options/`, you have to add a `require` line to `options.lua` by hand. Forget it and it's silently ignored, with no error.
- The identically named folders under `config/` (`options/`, `autocmds/`) are a personal split, not a LazyVim rule. The rule only goes as far as the `options.lua` and `autocmds.lua` files.

For the deeper principles (runtimepath, mandatory vs convention), see the blog post [Neovim Plugin Authoring Conventions](https://clang-engineer.github.io/posts/neovim/2026-06-12-neovim-plugin-conventions/).
