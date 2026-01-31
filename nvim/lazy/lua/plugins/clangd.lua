-- clangd LSP 설정: C/C++ 언어 서버에서 UTF-16 인코딩 사용 설정
return {
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
}
