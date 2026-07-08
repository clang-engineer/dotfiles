-- file picker / grep — currently depends on Snacks
local M = {}

local float = require("user.util.float")

function M.pick_files(dir)
  Snacks.picker.files({
    cwd = dir,
    confirm = function(picker, item)
      picker:close()
      if item then
        float.open(dir .. "/" .. item.file, "toolbox_refocus")
      end
    end,
  })
end

function M.grep(dir)
  Snacks.picker.grep({ cwd = dir })
end

return M
