return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        if #vim.api.nvim_get_runtime_file("colors/tinted-theming.vim", false) > 0 then
          vim.cmd.colorscheme("tinted-theming")
        else
          vim.cmd.colorscheme("tokyonight")
        end
      end,
    },
  },
}
