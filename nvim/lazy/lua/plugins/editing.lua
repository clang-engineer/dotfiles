-- editing.lua: collection of editing-related plugins
return {
  -- vim-visual-multi: edit multiple words at once
  {
    "mg979/vim-visual-multi",
    branch = "master",
    keys = {
      { "<C-n>", mode = { "n", "v" } }, -- select a word, then Ctrl+n to select the next one
    },
  },

  -- nvim-nocut: keep delete operations (x, d, dd, etc.) from overwriting the register
  {
    "maarutan/nvim-nocut",
    config = function()
      require("no-cut").setup()
    end,
  },
}
