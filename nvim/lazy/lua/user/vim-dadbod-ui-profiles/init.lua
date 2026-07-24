-- DB connection info loader.
-- Add a new profile: create vim-dadbod-ui-profiles/connections/<profile>.lua and it's auto-included in .all().
-- Disable: rename the file to .lua.disabled or delete it.
--
-- To see only a subset per project (using exrc):
--   1) Add `vim.o.exrc = true` to an init file like ~/.config/nvim (once).
--   2) Create .nvim.lua at the project root and override:
--        vim.g.dbs = require("user.vim-dadbod-ui-profiles").pick("profile-a", "profile-b")
--   3) On first run, register trust for that .nvim.lua with the :trust command.

-- Keep profile helpers in the same namespace so `user.vim-dadbod-ui-profiles` can be used
-- as one setup unit.
local profiles = require("user.vim-dadbod-ui-profiles.profiles")

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
    vim.list_extend(result, require("user.vim-dadbod-ui-profiles.connections." .. name))
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

function M.manage_profiles()
  profiles.manage_profiles()
end

function M.editor(profile)
  if profile == nil then
    profiles.manage_profiles()
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
  local command_prefix = options.command_prefix or "DBUI"

  vim.g.dbs = M.connections(default_profile)
  profiles.setup({
    command_prefix = command_prefix,
    picker_layout = options.picker_layout,
    prefix_by_profile = options.prefix_by_profile,
    icon_style = options.icon_style,
    profile_labels = options.profile_labels,
    icons = options.icons,
  })
end

return M
