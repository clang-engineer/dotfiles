return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local config_home = vim.env.XDG_CONFIG_HOME
        if not config_home or config_home == "" then
          config_home = vim.fn.expand("~/.config")
        end
        local theme_dir = config_home .. "/tinted-theming/tinty/generated/nvim"
        if vim.fn.filereadable(theme_dir .. "/colors/tinted-theming.vim") == 1 then
          vim.opt.rtp:prepend(theme_dir)
          vim.cmd.colorscheme("tinted-theming")
        else
          vim.cmd.colorscheme("tokyonight")
        end
      end,
    },
  },
}
