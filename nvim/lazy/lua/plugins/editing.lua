-- editing.lua: 편집 관련 플러그인 모음
return {
  -- vim-tmux-navigator: tmux와 nvim 간 창 이동
  {
    "christoomey/vim-tmux-navigator",
  },

  -- vim-visual-multi: 여러 단어를 동시에 편집
  {
    "mg979/vim-visual-multi",
    branch = "master",
    keys = {
      { "<C-n>", mode = { "n", "v" } }, -- 단어 선택 후 Ctrl+n으로 다음 단어 선택
    },
  },

  -- nvim-nocut: x, d, dd 등의 삭제 동작이 레지스터를 덮어쓰지 않도록 설정
  {
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
  },
}
