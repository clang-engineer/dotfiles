-- lazygit.nvim: git UI를 nvim에서 사용,
-- 별도 사전 설치 필요,
-- mac: brew install lazygit
-- ubuntu: apt install lazygit
-- nvim v0.8.0
return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  -- snacks.nvim lazygit: Windows에서 editPreset "nvim-remote"가
  -- bash 문법([)을 사용하여 cmd.exe에서 에러 발생 → 비활성화
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = {
        configure = true,
        config = {
          os = {
            editPreset = "",
            editCommand = "nvim",
            editCommandTemplate = '{{editor}} -- "{{filename}}"',
            shell = "bash",
            shellArg = "-c",
          },
        },
      },
    },
  },
}
