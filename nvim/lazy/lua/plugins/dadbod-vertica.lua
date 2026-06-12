-- dadbod-vertica.lua: Vertica adapter for vim-dadbod.
return {
  {
    "clang-engineer/dadbod-vertica.nvim",
    dependencies = { "tpope/vim-dadbod" },
    -- LazyVim loads vim-dadbod-ui via cmd=DBUI*; this plugin's plugin/ file
    -- registers ui table helpers + monkey-patches the schema tree, so it
    -- has to source before any DBUI command runs.
    cmd = { "DB", "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
  },
}
