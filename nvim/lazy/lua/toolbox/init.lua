-- toolbox.nvim 진입점
-- 사용: require("toolbox").setup({ dir = "~/notes" })
--       require("toolbox").setup()  -- TOOLBOX_DIR 환경변수 사용
local M = {}

function M.setup(opts)
  require("toolbox.config").setup(opts)
  require("toolbox.commands").register()
end

return M
