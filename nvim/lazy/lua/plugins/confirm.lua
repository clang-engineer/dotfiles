-- conform.nvim: 포맷터 설정
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- 다른 filetype 설정은 그대로 두고
      markdown = {}, -- markdown에서는 포맷터 비우기
    },
  },
}
