-- Detect CP949/EUC-KR Korean files and convert to UTF-8 internally (avoids win32yank UTF-8 panic)
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
