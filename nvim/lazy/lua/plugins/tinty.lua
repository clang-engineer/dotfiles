return {
  {
    "tinted-theming/tinted-nvim",
    version = "^1.0.0",
    priority = 1000,
    lazy = false,
    opts = {
      default_scheme = "base16-dracula",
      selector = {
        enabled = true,
        mode = "file",
        watch = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local tinted = require("tinted-nvim")
        tinted.load(tinted.get_scheme() or "base16-dracula")
      end,
    },
  },
}
