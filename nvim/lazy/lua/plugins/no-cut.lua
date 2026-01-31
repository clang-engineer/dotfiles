-- nvim-nocut: x, d, dd 등의 삭제 동작이 레지스터를 덮어쓰지 않도록 설정하는 플러그인
-- 붙여넣기 후 다시 붙여넣기 할 때 유용
return {
  "maarutan/nvim-nocut",
  config = function()
    require("no-cut").setup({
      d = true,
      x = true,
      dd = true,
      paste_without_copy = true,
      exceptions = { "Y" },
    })
  end,
}
