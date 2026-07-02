-- CP949/EUC-KR 한글 파일을 감지해 내부 UTF-8로 변환 (win32yank UTF-8 패닉 방지)
vim.opt.fileencodings = { "ucs-bom", "utf-8", "cp949", "euc-kr", "latin1" }

-- set norelativenumber
vim.opt.relativenumber = false

-- set conceallevel
vim.opt.conceallevel = 0

-- allow per-project .nvim.lua
vim.opt.exrc = true
vim.opt.secure = true

-- set dianostic virtual text
-- vim.diagnostic.enable(false)
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { severity = vim.diagnostic.severity.ERROR },
  signs = { severity = { max = vim.diagnostic.severity.ERROR } },
  underline = { severity = vim.diagnostic.severity.ERROR },
  float = { severity = vim.diagnostic.severity.ERROR },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.diagnostic.enable(false, { bufnr = 0 })
  end,
})
