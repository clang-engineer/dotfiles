-- quicklinks.nvim 진입점
-- 사용: require("user.quicklinks").setup({ dir = "~/notes" })
--       require("user.quicklinks").setup()  -- VAULT_DIR 환경변수 사용
local M = {}

function M.setup(opts)
  require("user.quicklinks.config").setup(opts)
  require("user.quicklinks.commands").register()
end

return M
