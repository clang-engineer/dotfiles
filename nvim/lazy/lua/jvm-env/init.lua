-- jvm-env.nvim 진입점
-- 사용:
--   require("jvm-env").setup()                              -- 기본 (jdtls=21, gradle=11)
--   require("jvm-env").setup({ jdtls = "21", gradle = "17" })
local M = {}

function M.setup(opts)
  local config = require("jvm-env.config")
  config.setup(opts)

  local env = require("jvm-env.env")
  env.apply_jdtls(config.get("jdtls"))
  env.apply_gradle(config.get("gradle"))
end

return M
