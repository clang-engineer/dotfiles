-- vim-visual-multi: 여러 단어를 동시에 편집할 수 있는 플러그인
return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    keys = {
      { "<C-n>", mode = { "n", "v" } }, -- 단어 선택 후 Ctrl+n으로 다음 단어 선택
    },
  },
}
