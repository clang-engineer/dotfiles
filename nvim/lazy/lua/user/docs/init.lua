-- docs.nvim entry point — unified viewer/search over knowledge roots
-- Usage: require("user.docs").setup({
--          roots = {
--            { name = "notes", dir = "~/notes" },
--            { name = "wiki", dir = "~/wiki", grep_only = true },
--          },
--        })
local M = {}

function M.setup(opts)
  require("user.docs.config").setup(opts)
  require("user.docs.commands").register()
end

return M
