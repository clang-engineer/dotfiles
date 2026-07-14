-- docs.nvim entry point — unified viewer/search over knowledge roots
-- Usage: require("user.docs").setup()  -- roots from VAULT_DIR / DEVKIT_DIR / BLOG_DIR
--        require("user.docs").setup({ roots = { { dir = "~/notes" } } })
local M = {}

function M.setup(opts)
  require("user.docs.config").setup(opts)
  require("user.docs.commands").register()
end

return M
