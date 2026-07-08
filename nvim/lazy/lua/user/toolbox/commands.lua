-- register :Toolbox / :ToolboxGrep
local M = {}

local config = require("user.toolbox.config")
local picker = require("user.toolbox.picker")
local float = require("user.util.float")

function M.register()
  vim.api.nvim_create_user_command("Toolbox", function(opts)
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end

    if opts.args ~= "" then
      -- arg = cheatsheet name → open directly
      local path = dir .. "/cheatsheets/" .. opts.args .. ".md"
      if vim.fn.filereadable(path) == 1 then
        float.open(path, "toolbox_refocus")
      else
        vim.notify("cheatsheet not found: " .. opts.args, vim.log.levels.WARN, { title = "toolbox" })
      end
    else
      picker.pick_files(dir)
    end
  end, {
    nargs = "?",
    complete = function(arglead)
      local dir = config.get_dir()
      if not dir then
        return {}
      end
      local names = {}
      for _, f in ipairs(vim.fn.globpath(dir .. "/cheatsheets", "*.md", false, true)) do
        local name = vim.fn.fnamemodify(f, ":t:r")
        if name ~= "README" and vim.startswith(name, arglead) then
          names[#names + 1] = name
        end
      end
      return names
    end,
    desc = "toolbox search (no arg = full picker, arg opens a cheatsheet directly)",
  })

  vim.api.nvim_create_user_command("ToolboxGrep", function()
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end
    picker.grep(dir)
  end, { desc = "toolbox full-text grep search" })
end

return M
