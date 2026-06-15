-- lsp.lua: LSP 관련 설정 모음
return {
  -- clangd: C/C++ 언어 서버 UTF-16 인코딩 설정
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        clangd = function(_, opts)
          opts.capabilities.offsetEncoding = { "utf-16" }
        end,
      },
    },
  },

  -- conform.nvim: 포맷터 설정 (markdown 포맷터 비활성화)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = {},
      },
    },
  },
}
