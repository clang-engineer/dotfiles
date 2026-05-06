vim.g.dbs = {
  {
    name = "Docker postgres",
    url = "postgres://myuser@localhost:5432/mydb",
  },
  {
    name = "remote postgres (SSH tunnel)",
    url = "postgresql://myuser@REDACTED_IP:5432/mydb?connect_timeout=5",
  },
}

-- 쿼리 결과창(dbout)을 화면 절반 높이로 키운다
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.cmd("resize " .. math.floor(vim.o.lines / 2))
  end,
})
