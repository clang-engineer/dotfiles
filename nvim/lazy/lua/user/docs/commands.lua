-- register :Docs / :DocsGrep
local M = {}

local config = require("user.docs.config")
local picker = require("user.docs.picker")

function M.register()
  vim.api.nvim_create_user_command("Docs", function(cmd)
    picker.open(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return config.root_names(false)
    end,
    desc = "browse docs across the knowledge roots (optionally one root by name)",
  })

  vim.api.nvim_create_user_command("DocsGrep", function(cmd)
    picker.grep(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return config.root_names(true)
    end,
    desc = "full-text grep across the knowledge roots (optionally one root by name)",
  })
end

return M
