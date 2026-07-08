-- lsp.lua: collection of LSP-related settings
return {
  -- clangd: UTF-16 encoding setting for the C/C++ language server
  -- kotlin_language_server: workaround for fwcd v1.3.13 #600 (disables documentHighlight). Remove once v1.3.14 is released (fwcd/kotlin-language-server#671)
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

  -- conform.nvim: formatter settings (markdown formatter disabled)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = {},
      },
    },
  },
}
