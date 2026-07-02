-- :Toolbox / :ToolboxGrep 등록
local M = {}

local config = require("user.toolbox.config")
local picker = require("user.toolbox.picker")
local float = require("user.toolbox.float")

function M.register()
  vim.api.nvim_create_user_command("Toolbox", function(opts)
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end

    if opts.args ~= "" then
      -- 인자 = cheatsheet 이름 → 바로 열기
      local path = dir .. "/cheatsheets/" .. opts.args .. ".md"
      if vim.fn.filereadable(path) == 1 then
        float.open(path)
      else
        vim.notify("cheatsheet 없음: " .. opts.args, vim.log.levels.WARN, { title = "toolbox" })
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
    desc = "toolbox 검색 (인자 없으면 전체 피커, 인자는 cheatsheet 바로 열기)",
  })

  vim.api.nvim_create_user_command("ToolboxGrep", function()
    local dir = config.get_dir()
    if not dir then
      return config.warn_no_dir()
    end
    picker.grep(dir)
  end, { desc = "toolbox 전체 본문 grep 검색" })
end

return M
