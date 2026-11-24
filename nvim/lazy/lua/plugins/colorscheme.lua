-- colorscheme: 활성 테마 지정 + 후보 등록
-- catppuccin 등 LazyVim 기본 제공 테마는 원본 설정을 그대로 사용
local colorscheme = dofile(vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h") .. "/dotfiles/theme.lua")

return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = colorscheme },
  },
  { "scottmckendry/cyberdream.nvim", lazy = true },
  -- 추가 등록: LazyVim 기본엔 없어 상시 등록해두는 것
  { "ellisonleao/gruvbox.nvim", lazy = true },
}
