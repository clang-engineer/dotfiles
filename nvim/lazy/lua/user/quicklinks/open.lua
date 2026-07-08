-- dispatch behavior by selected item type
-- URL → vim.ui.open (browser)
-- *.md → floating window
-- other local files/directories → vim.ui.open (external app)
local M = {}

local float = require("user.util.float")
local config = require("user.quicklinks.config")

local function is_url(target)
  return target:match("^https?://") ~= nil
end

local function resolve(target, dir)
  local path = vim.fs.normalize(target)
  -- relative paths are resolved against the toolbox dir
  if not path:match("^/") then
    path = (dir or "") .. "/" .. path
  end
  return path
end

function M.dispatch(target)
  if is_url(target) then
    vim.ui.open(target)
    return
  end

  local path = resolve(target, config.get_dir())
  local is_md = path:match("%.md$") ~= nil
  local readable = vim.fn.filereadable(path) == 1
  local is_dir = vim.fn.isdirectory(path) == 1

  if is_md and readable then
    float.open(path, "quicklinks_refocus")
  elseif readable or is_dir then
    vim.ui.open(path)
  else
    vim.notify(
      "quicklinks: path not found: " .. target,
      vim.log.levels.WARN,
      { title = "quicklinks" }
    )
  end
end

return M
