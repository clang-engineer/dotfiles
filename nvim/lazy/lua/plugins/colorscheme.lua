-- colorscheme: 활성 테마 지정 + 후보 등록
-- catppuccin 등 LazyVim 기본 제공 테마는 원본 설정을 그대로 사용
return {
  -- ── 실설정 ──
  -- 원본 활성: tokyonight (LazyVim 기본 제공, catppuccin도 원본 그대로 함께 로드됨)
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight" },
  },
  -- 추가 등록: LazyVim 기본엔 없어 상시 등록해두는 것
  { "ellisonleao/gruvbox.nvim", lazy = true },

  -- ── 비교 후보 (:colorscheme 으로 골라 보고, 정하면 아래 두 그룹 삭제) ──
  -- 신흥: 요즘 평판 오르는
  { "vague-theme/vague.nvim", lazy = true }, -- 저대비 뮤트 파스텔
  { "scottmckendry/cyberdream.nvim", lazy = true }, -- 비비드 네온 사이버펑크
  { "nyoom-engineering/oxocarbon.nvim", lazy = true }, -- IBM Carbon 미니멀 모노톤
  { "comfysage/evergarden", lazy = true }, -- 저채도 그린
  { "ribru17/bamboo.nvim", lazy = true }, -- 그린 계열
  { "craftzdog/solarized-osaka.nvim", lazy = true }, -- solarized 다크 변주

  -- de-facto 상위권: 정착한 기준선
  { "rose-pine/neovim", name = "rose-pine", lazy = true }, -- 뮤트 파스텔, Soho vibes
  { "rebelot/kanagawa.nvim", lazy = true }, -- 우키요에 다크
  { "sainnhe/everforest", lazy = true }, -- 저채도 포레스트 그린
  { "EdenEast/nightfox.nvim", lazy = true }, -- 팔레트 세트
  { "navarasu/onedark.nvim", lazy = true }, -- Atom OneDark
  { "sainnhe/gruvbox-material", lazy = true }, -- gruvbox 저대비 개선판
  { "shaunsingh/nord.nvim", lazy = true }, -- 북유럽 블루
  { "Mofiqul/dracula.nvim", lazy = true }, -- 보라 대비
}
