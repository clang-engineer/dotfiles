-- colorscheme: 활성 테마 지정 + 후보 등록
-- catppuccin 등 LazyVim 기본 제공 테마는 원본 설정을 그대로 사용
local colorscheme = require("config.theme").setup()

return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = colorscheme },
  },
  { "scottmckendry/cyberdream.nvim", lazy = true, opts = { variant = "default", transparent = false } },
  -- 추가 등록: LazyVim 기본엔 없어 상시 등록해두는 것
  { "ellisonleao/gruvbox.nvim", lazy = true, opts = { contrast = "", transparent_mode = false } },
  -- Official Dracula port for Vim/Neovim: https://draculatheme.com/vim
  { "dracula/vim", name = "dracula", lazy = true },
  { "nordtheme/vim", name = "nord", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  {
    "sainnhe/everforest",
    lazy = true,
    config = function()
      vim.g.everforest_background = "medium"
      vim.g.everforest_transparent_background = 0
    end,
  },
  { "navarasu/onedark.nvim", lazy = true, opts = { style = "dark", transparent = false } },
}
