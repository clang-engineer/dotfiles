-- quicklinks.nvim entry point
-- Usage: require("user.quicklinks").setup({ dir = "~/notes" })
--        require("user.quicklinks").setup()  -- use the VAULT_DIR environment variable
local M = {}

function M.setup(opts)
  require("user.quicklinks.config").setup(opts)
  require("user.quicklinks.commands").register()
end

return M
