-- quicklinks.nvim 진입점
-- 사용: require("quicklinks").setup({ dir = "~/notes" })
--       require("quicklinks").setup()  -- TOOLBOX_DIR 환경변수 사용
local M = {}

function M.setup(opts)
  require("quicklinks.config").setup(opts)
  require("quicklinks.commands").register()
end

return M
