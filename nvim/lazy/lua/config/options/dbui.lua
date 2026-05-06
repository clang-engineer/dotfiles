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

-- 쿼리 결과창(dbout) 가독성 개선:
--   1) fold 비활성화 (메인테이너 공식 권장: PR #203 댓글)
--   2) 콘텐츠 행 수에 맞춰 리사이즈, 화면 절반을 상한으로 (작은 결과는 좁게, 큰 결과는 절반에서 컷)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.opt_local.foldenable = false
    local lines = vim.api.nvim_buf_line_count(0)
    local cap = math.floor(vim.o.lines / 2)
    local height = math.max(8, math.min(lines + 1, cap))
    vim.cmd("resize " .. height)
  end,
})
