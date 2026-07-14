-- register :Docs / :DocsGrep
local M = {}

local picker = require("user.docs.picker")

function M.register()
  vim.api.nvim_create_user_command("Docs", function()
    picker.open()
  end, { desc = "browse docs across the knowledge roots" })

  vim.api.nvim_create_user_command("DocsGrep", function()
    picker.grep()
  end, { desc = "full-text grep across the knowledge roots" })
end

return M
