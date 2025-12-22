-- claude-code.nvim: Claude AI 코드 어시스턴트를 Neovim에서 사용하기 위한 플러그인
return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup()
  end,
}
