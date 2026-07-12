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

  -- ── 비교 후보 (:colorscheme 으로 취향껏, 정하면 아래 전부 삭제) ──
  -- 태그: [정착] de-facto 상위권 / [신흥] 평판 오르는 (그룹 내 정착 → 신흥 순)
  -- 고대비·비비드: 쨍하고 화려
  { "Mofiqul/dracula.nvim", lazy = true }, -- 보라 비비드, 생태계 큼 [정착]
  { "scottmckendry/cyberdream.nvim", lazy = true }, -- 네온 사이버펑크 [신흥]

  -- 고대비·미니멀: 쨍하지만 절제된
  { "nyoom-engineering/oxocarbon.nvim", lazy = true }, -- IBM Carbon 모노톤 [신흥]

  -- 중간: 대비·채도 균형
  { "EdenEast/nightfox.nvim", lazy = true }, -- 팔레트 세트, carbonfox는 고대비 [정착]
  { "navarasu/onedark.nvim", lazy = true }, -- Atom OneDark [정착]
  { "rebelot/kanagawa.nvim", lazy = true }, -- 우키요에 다크 [정착]
  { "craftzdog/solarized-osaka.nvim", lazy = true }, -- solarized 다크 변주 [신흥]

  -- 은은·저대비: 뮤트/파스텔 (요즘 대세 결)
  { "rose-pine/neovim", name = "rose-pine", lazy = true }, -- 뮤트 파스텔, Soho [정착]
  { "sainnhe/everforest", lazy = true }, -- 저채도 포레스트 그린 [정착]
  { "sainnhe/gruvbox-material", lazy = true }, -- gruvbox 저대비 개선판 [정착]
  { "shaunsingh/nord.nvim", lazy = true }, -- 북유럽 블루, 저대비 [정착]
  { "vague-theme/vague.nvim", lazy = true }, -- 저대비 뮤트 파스텔 [신흥]
  { "comfysage/evergarden", lazy = true }, -- 저채도 그린 [신흥]
  { "ribru17/bamboo.nvim", lazy = true }, -- 뮤트 그린 [신흥]
}
