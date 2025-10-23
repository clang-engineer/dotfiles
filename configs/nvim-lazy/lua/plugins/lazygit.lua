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
}
