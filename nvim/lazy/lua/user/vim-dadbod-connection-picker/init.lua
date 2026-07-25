-- DB connection info loader.
-- Add a new connection group: create vim-dadbod-connection-picker/connections/<group>.lua and it's auto-included in .all().
-- Disable: rename the file to .lua.disabled or delete it.
--
-- To see only a subset per project (using exrc):
--   1) Add `vim.o.exrc = true` to an init file like ~/.config/nvim (once).
--   2) Create .nvim.lua at the project root and override:
--        vim.g.dbs = require("user.vim-dadbod-connection-picker").pick("group-a", "group-b")
--   3) On first run, register trust for that .nvim.lua with the :trust command.

-- Keep connection helpers in the same namespace so `user.vim-dadbod-connection-picker` can be used
-- as one setup unit.
local profiles = require("user.vim-dadbod-connection-picker.profiles")

local M = {}

-- Keep backward-compatible API used by older settings.
function M.all()
  return profiles.connections("all")
end

function M.pick(...)
  local targets = { ... }
  if #targets == 0 then
    return {}
  end

  local result = {}
  for _, name in ipairs(targets) do
    vim.list_extend(result, require("user.vim-dadbod-connection-picker.connections." .. name))
  end
  return result
end

-- Returns profile-based DB connection list by filename.
-- `target="all"` or nil returns all connections.
function M.connections(target)
  return profiles.connections(target)
end

function M.pick_profile()
  profiles.pick_profile()
end

function M.finder()
  profiles.pick_profile()
end

function M.pick_group()
  profiles.pick_group()
end

function M.editor(profile)
  if profile == nil then
    vim.notify("Specify group name: :DBConnections edit <group>", vim.log.levels.WARN)
    return
  end
  profiles.edit_profile(profile)
end

function M.edit_profile(name)
  profiles.edit_profile(name)
end

function M.open_group(name)
  profiles.open(name)
end

function M.open_profile(name)
  profiles.open_profile(name)
end

-- Plugin-like entrypoint: initialize DBUI connection list + commands.
function M.setup(opts)
  local options = opts or {}
  local default_profile = options.default_profile or options.default_group or "all"

  vim.g.dbs = M.connections(default_profile)
  profiles.setup({
    icon_style = options.icon_style,
    profile_labels = options.profile_labels,
    icons = options.icons,
  })
end

return M
