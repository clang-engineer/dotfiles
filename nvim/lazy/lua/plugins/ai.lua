-- ai.lua: AI 코딩 어시스턴트 플러그인 모음
return {
  -- claude-code.nvim: Claude AI 코드 어시스턴트
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("claude-code").setup()
    end,
  },

  -- codex.nvim: OpenAI Codex 플로팅 윈도우 (<leader>cc로 토글)
  {
    "johnseth97/codex.nvim",
    lazy = true,
    cmd = { "Codex", "CodexToggle" },
    keys = {
      {
        "<leader>cc",
        function()
          require("codex").toggle()
        end,
        desc = "Toggle Codex popup",
      },
    },
    opts = {
      keymaps = {
        toggle = nil,
        quit = "<C-q>",
      },
      border = "rounded",
      width = 0.8,
      height = 0.8,
      model = nil,
      autoinstall = true,
    },
  },
}
