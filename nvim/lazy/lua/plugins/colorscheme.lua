-- colorscheme: 활성 테마 지정 + 후보 등록
-- catppuccin 등 LazyVim 기본 제공 테마는 원본 설정을 그대로 사용
return {
  -- 활성: cyberdream (고대비 네온 사이버펑크)
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "cyberdream" },
  },
  { "scottmckendry/cyberdream.nvim", lazy = true },
  -- 추가 등록: LazyVim 기본엔 없어 상시 등록해두는 것
  { "ellisonleao/gruvbox.nvim", lazy = true },
}
