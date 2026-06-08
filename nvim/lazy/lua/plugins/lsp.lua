-- lsp.lua: LSP 관련 설정 모음
return {
  -- clangd: C/C++ 언어 서버 UTF-16 인코딩 설정
  -- kotlin_language_server: 커뮤니티 fork 빌드 사용 (fwcd 원본 v1.3.13 documentHighlight 버그 우회)
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        clangd = function(_, opts)
          opts.capabilities.offsetEncoding = { "utf-16" }
        end,
        kotlin_language_server = function(_, opts)
          opts.cmd = { os.getenv("HOME") .. "/.local/share/kotlin-language-server/server/bin/kotlin-language-server" }
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
