-- DB connection info loader.
-- Add a new group: create db/connections/<group>.lua and it's auto-included in .all().
-- Disable: rename the file to .lua.disabled or delete it.
--
-- To see only a subset per project (using exrc):
--   1) Add `vim.o.exrc = true` to an init file like ~/.config/nvim (once).
--   2) Create .nvim.lua at the project root and override:
--        vim.g.dbs = require("user.db").pick("group-a", "group-b")
--   3) On first run, register trust for that .nvim.lua with the :trust command.

local M = {}

function M.all()
  local result = {}
  local files = vim.api.nvim_get_runtime_file("lua/user/db/connections/*.lua", true)
  table.sort(files)
  for _, path in ipairs(files) do
    local mod = path:gsub("\\", "/"):match("lua/(.+)%.lua$"):gsub("/", ".")
    vim.list_extend(result, require(mod))
  end
  return result
end

function M.pick(...)
  local result = {}
  for _, name in ipairs({ ... }) do
    vim.list_extend(result, require("user.db.connections." .. name))
  end
  return result
end

return M
