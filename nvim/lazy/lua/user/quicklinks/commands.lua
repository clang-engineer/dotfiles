-- register :Quicklinks / :QuicklinksAdd
local M = {}

local config = require("user.quicklinks.config")
local picker = require("user.quicklinks.picker")
local store = require("user.quicklinks.store")

local function add_interactive(dir)
  vim.ui.input({ prompt = "Name: " }, function(name)
    if not name or name == "" then
      return
    end
    vim.ui.input({ prompt = "Path or URL: " }, function(target)
      if not target or target == "" then
        return
      end
      store.append(dir, name, target)
      vim.notify(
        string.format("Added: %s → %s", name, target),
        vim.log.levels.INFO,
        { title = "quicklinks" }
      )
    end)
  end)
end

function M.register()
  vim.api.nvim_create_user_command("Quicklinks", function()
    picker.open()
  end, { desc = "open the quicklinks picker" })

  vim.api.nvim_create_user_command("QuicklinksAdd", function()
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end
    add_interactive(dir)
  end, { desc = "add a quicklink entry (prompt)" })

  vim.api.nvim_create_user_command("QuicklinksEdit", function()
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end
    vim.cmd("edit " .. store.path(dir))
  end, { desc = "edit quicklinks.md directly" })
end

return M
