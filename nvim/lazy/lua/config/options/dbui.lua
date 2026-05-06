vim.g.dbs = {
  {
    name = "Docker postgres",
    url = "postgres://snuheras@localhost:5432/eras",
  },
  {
    name = "순천향 Ridex postgres meta",
    url = "postgresql://rex@172.22.101.134:5432/psd_sch?connect_timeout=5",
  },
}

-- 쿼리 결과창(dbout)을 화면 절반 높이로 키운다
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.cmd("resize " .. math.floor(vim.o.lines / 2))
  end,
})
