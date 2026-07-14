-- open a selected file: *.md in a floating viewer, other text files in a buffer
local M = {}

local float = require("user.util.float")

function M.dispatch(path)
  if path:match("%.md$") then
    float.open(path)
  else
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
end

return M
