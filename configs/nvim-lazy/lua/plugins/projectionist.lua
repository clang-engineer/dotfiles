--[[
vim-projectionist: 프로젝트 파일 간 탐색을 쉽게 해주는 플러그인

사용법:
1. 프로젝트 루트에 .projections.json 파일 생성
2. 파일 간 관계 정의

예제 .projections.json:
{
  "src/*.ts": {
    "alternate": "tests/{}.test.ts",
    "type": "source"
  },
  "tests/*.test.ts": {
    "alternate": "src/{}.ts",
    "type": "test"
  },
  "src/components/*.tsx": {
    "alternate": "src/components/{}.test.tsx",
    "type": "component"
  }
}

주요 명령어:
- :A  - Alternate 파일로 이동 (source ↔ test)
- :AV - Alternate 파일을 vsplit으로 열기
- :AS - Alternate 파일을 split으로 열기
- :AT - Alternate 파일을 새 탭으로 열기

키맵:
- <leader>a  - :A
- <leader>av - :AV
- <leader>as - :AS
- <leader>at - :AT
--]]

return {
  "tpope/vim-projectionist",
  event = "VeryLazy",
  config = function()
    -- which-key 그룹 설정
    local wk = require("which-key")
    wk.add({
      { "<leader>a", group = "alternate" },
    })

    -- 키맵 설정
    vim.keymap.set("n", "<leader>a", "<cmd>A<cr>", { desc = "Go to alternate file" })
    vim.keymap.set("n", "<leader>av", "<cmd>AV<cr>", { desc = "Alternate (vsplit)" })
    vim.keymap.set("n", "<leader>as", "<cmd>AS<cr>", { desc = "Alternate (split)" })
    vim.keymap.set("n", "<leader>at", "<cmd>AT<cr>", { desc = "Alternate (tab)" })
  end,
}
