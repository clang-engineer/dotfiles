-- markdwon을 미리 보여주는 플러그인
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      enabled = false,
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    config = function()
      vim.g.mkdp_auto_close = 0
    end,
  },
}
