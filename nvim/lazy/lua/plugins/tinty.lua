return {
  {
    "tinted-theming/tinted-nvim",
    version = "1.0.0",
    priority = 1000,
    lazy = false,
    opts = {
      default_scheme = "base16-dracula",
      apply_scheme_on_startup = false,
      selector = { enabled = true },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("tinted-nvim").load()
      end,
    },
  },
}
