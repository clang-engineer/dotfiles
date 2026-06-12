-- dadbod-vertica.lua: Vertica adapter for vim-dadbod.
return {
  {
    "clang-engineer/dadbod-vertica.nvim",
    dependencies = { "tpope/vim-dadbod" },
    -- Eager load: keeps the vertica adapter on rtp before vim-dadbod-ui's
    -- cmd handler dispatches its init. Cmd-lazy raced with dbui in
    -- interactive sessions even though headless worked.
    lazy = false,
    -- Skip PATH lookup — ~/bin isn't on default macOS PATH and we'd rather
    -- not own a shell rc tweak just for one binary.
    opts = { vsql = vim.fn.expand("~/bin/vsql") },
  },
}
