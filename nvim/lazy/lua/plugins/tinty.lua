-- Opt in with TINTY_NVIM=1 before opening Neovim.
return {
  {
    "tinted-theming/tinted-nvim",
    version = "1.*",
    enabled = vim.env.TINTY_NVIM == "1",
    lazy = false,
    priority = 1000,
    opts = {
      default_scheme = "base16-dracula",
      selector = {
        enabled = true,
        mode = "file",
        path = (vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share"))
          .. "/tinted-theming/tinty/current_scheme",
        watch = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      if vim.env.TINTY_NVIM == "1" then
        opts.colorscheme = function()
          local scheme = vim.trim(vim.fn.system("tinty current"))
          if vim.v.shell_error == 0 and scheme:match("^base%d+%-") then
            require("tinted-nvim").load(scheme)
          else
            require("tinted-nvim").load("base16-dracula")
          end
        end
      end
    end,
  },
}
