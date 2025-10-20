return {
  "maarutan/nvim-nocut",
  config = function()
    require("no-cut").setup({
      d = true,
      x = true,
      dd = true,
      paste_without_copy = true,
      exceptions = { "Y" },
    })
  end,
}
