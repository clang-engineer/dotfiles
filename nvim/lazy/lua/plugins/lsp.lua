-- lsp.lua: LSP 관련 설정 모음
return {
  -- clangd: C/C++ 언어 서버 UTF-16 인코딩 설정
  -- kotlin_language_server: fwcd v1.3.13 #600 우회 (documentHighlight 끔). v1.3.14 릴리스되면 제거 (fwcd/kotlin-language-server#671)
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        clangd = function(_, opts)
          opts.capabilities.offsetEncoding = { "utf-16" }
        end,
        kotlin_language_server = function(_, opts)
          opts.on_attach = function(client, _)
            client.server_capabilities.documentHighlightProvider = false
          end
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
