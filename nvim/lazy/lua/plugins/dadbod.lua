-- dadbod-ui 설정. 플러그인 본체는 lazyvim.plugins.extras.lang.sql가 제공.
-- 여기선 접속 목록(vim.g.dbs)과 결과창 가독성만 얹는다.
return {
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      vim.g.dbs = require("user.db").all()

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
    end,
  },
}
