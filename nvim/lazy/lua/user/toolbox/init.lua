-- toolbox.nvim entry point
-- Usage: require("user.toolbox").setup({ dir = "~/notes" })
--        require("user.toolbox").setup()  -- use the TOOLBOX_DIR environment variable
local M = {}

function M.setup(opts)
  require("user.toolbox.config").setup(opts)
  require("user.toolbox.commands").register()
end

return M
