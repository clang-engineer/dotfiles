-- toolbox.nvim 진입점
-- 사용: require("user.toolbox").setup({ dir = "~/notes" })
--       require("user.toolbox").setup()  -- TOOLBOX_DIR 환경변수 사용
local M = {}

function M.setup(opts)
  require("user.toolbox.config").setup(opts)
  require("user.toolbox.commands").register()
end

return M
