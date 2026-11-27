return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local data_dir = vim.fn.fnamemodify(vim.fn.stdpath("data"), ":h") .. "/tinted-theming/tinty"
        local current = data_dir .. "/current_scheme"
        local scheme = vim.fn.filereadable(current) == 1 and vim.fn.readfile(current, "", 1)[1] or "base16-dracula"
        vim.opt.rtp:prepend(data_dir .. "/repos/tinted-vim")
        vim.cmd.colorscheme(scheme)
      end,
    },
  },
}
