-- colorscheme: theme settings (tokyonight, gruvbox, catppuccin)
-- catppuccin includes integration settings for various plugins
return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight" },
  },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  -- 요즘 평판 오르는 신흥 (:colorscheme 으로 비교용)
  { "vague-theme/vague.nvim", lazy = true }, -- 저대비 뮤트 파스텔
  { "scottmckendry/cyberdream.nvim", lazy = true }, -- 비비드 네온 사이버펑크
  { "nyoom-engineering/oxocarbon.nvim", lazy = true }, -- IBM Carbon 미니멀 모노톤
  { "comfysage/evergarden", lazy = true }, -- 저채도 그린
  { "ribru17/bamboo.nvim", lazy = true }, -- 그린 계열
  { "craftzdog/solarized-osaka.nvim", lazy = true }, -- solarized 다크 변주
  -- de-facto 상위권 (신흥과 비교 기준선)
  { "rose-pine/neovim", name = "rose-pine", lazy = true }, -- 뮤트 파스텔, Soho vibes
  { "rebelot/kanagawa.nvim", lazy = true }, -- 우키요에 다크
  { "sainnhe/everforest", lazy = true }, -- 저채도 포레스트 그린
  { "EdenEast/nightfox.nvim", lazy = true }, -- 팔레트 세트
  { "navarasu/onedark.nvim", lazy = true }, -- Atom OneDark
  { "sainnhe/gruvbox-material", lazy = true }, -- gruvbox 저대비 개선판
  { "shaunsingh/nord.nvim", lazy = true }, -- 북유럽 블루
  { "Mofiqul/dracula.nvim", lazy = true }, -- 보라 대비
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        fzf = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        snacks = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    specs = {
      {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ""):find("catppuccin") then
            opts.highlights = require("catppuccin.groups.integrations.bufferline").get_theme()
          end
        end,
      },
    },
  },
}
