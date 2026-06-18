-- :Quicklinks / :QuicklinksAdd 등록
local M = {}

local config = require("quicklinks.config")
local picker = require("quicklinks.picker")
local store = require("quicklinks.store")

local function add_interactive(dir)
  vim.ui.input({ prompt = "이름: " }, function(name)
    if not name or name == "" then
      return
    end
    vim.ui.input({ prompt = "경로 또는 URL: " }, function(target)
      if not target or target == "" then
        return
      end
      store.append(dir, name, target)
      vim.notify(
        string.format("추가됨: %s → %s", name, target),
        vim.log.levels.INFO,
        { title = "quicklinks" }
      )
    end)
  end)
end

function M.register()
  vim.api.nvim_create_user_command("Quicklinks", function()
    picker.open()
  end, { desc = "quicklinks 픽커 열기" })

  vim.api.nvim_create_user_command("QuicklinksAdd", function()
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end
    add_interactive(dir)
  end, { desc = "quicklink 항목 추가 (프롬프트)" })

  vim.api.nvim_create_user_command("QuicklinksEdit", function()
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end
    vim.cmd("edit " .. store.path(dir))
  end, { desc = "quicklinks.md 직접 편집" })
end

return M
