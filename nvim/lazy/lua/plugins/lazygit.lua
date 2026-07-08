-- lazygit.nvim: use the git UI from within nvim,
-- requires separate installation,
-- mac: brew install lazygit
-- ubuntu: apt install lazygit
-- nvim v0.8.0
return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  -- snacks.nvim lazygit: on Windows the editPreset "nvim-remote" uses
  -- bash syntax ([), which errors in cmd.exe -> disable it
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
