-- 파일 picker / grep — 현재 Snacks 의존
local M = {}

local float = require("toolbox.float")

function M.pick_files(dir)
  Snacks.picker.files({
    cwd = dir,
    confirm = function(picker, item)
      picker:close()
      if item then
        float.open(dir .. "/" .. item.file)
      end
    end,
  })
end

function M.grep(dir)
  Snacks.picker.grep({ cwd = dir })
end

return M
