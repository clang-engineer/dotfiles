-- codex.nvim: OpenAI Codex를 Neovim에서 사용하기 위한 플러그인
-- 플로팅 윈도우로 AI 코딩 어시스턴트 제공 (<leader>cc로 토글)
return {
  "johnseth97/codex.nvim",
  lazy = true,
  cmd = { "Codex", "CodexToggle" }, -- Optional: Load only on command execution
  keys = {
    {
      "<leader>cc", -- Change this to your preferred keybinding
      function()
        require("codex").toggle()
      end,
      desc = "Toggle Codex popup",
    },
  },
  opts = {
    keymaps = {
      toggle = nil, -- Keybind to toggle Codex window (Disabled by default, watch out for conflicts)
      quit = "<C-q>", -- Keybind to close the Codex window (default: Ctrl + q)
    }, -- Disable internal default keymap (<leader>cc -> :CodexToggle)
    border = "rounded", -- Options: 'single', 'double', or 'rounded'
    width = 0.8, -- Width of the floating window (0.0 to 1.0)
    height = 0.8, -- Height of the floating window (0.0 to 1.0)
    model = nil, -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
    autoinstall = true, -- Automatically install the Codex CLI if not found
  },
}
