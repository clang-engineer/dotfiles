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

  -- CopilotChat: 기본 모델이 gpt-4.1로 하드코딩돼 있는데 구독에서 못 찾는 경우가 있어
  -- Auto selector로 고정
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = { model = "auto" },
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
