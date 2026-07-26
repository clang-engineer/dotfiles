-- DB connection info loader.
-- Add a new connection group: create vim-dadbod-connection-picker/connections/<group>.lua and it's auto-included in .all().
-- Disable: rename the file to .lua.disabled or delete it.
--
-- To see only a subset per project (using exrc):
--   1) Add `vim.o.exrc = true` to an init file like ~/.config/nvim (once).
--   2) Create .nvim.lua at the project root and override:
--        vim.g.dbs = require("user.vim-dadbod-connection-picker").pick("group-a", "group-b")
--   3) On first run, register trust for that .nvim.lua with the :trust command.

local connection_groups = require("user.vim-dadbod-connection-picker.controller")
local command_name = "DBPicker"

local M = {}

function M.all()
  return connection_groups.connections("all")
end

function M.pick(...)
  local targets = { ... }
  if #targets == 0 then
    return {}
  end

  local result = {}
  for _, name in ipairs(targets) do
    local group_conns = connection_groups.connections(name)
    if type(group_conns) == "table" then
      vim.list_extend(result, group_conns)
    end
  end
  return result
end

-- Returns group-based DB connection list by group name.
-- `target="all"` or nil returns all connections.
function M.connections(target)
  return connection_groups.connections(target)
end

function M.pick_group()
  connection_groups.pick_group()
end

function M.finder()
  connection_groups.pick_group()
end

function M.editor(group)
  if group == nil then
    vim.notify("Specify group name: :" .. command_name .. " edit <group>", vim.log.levels.WARN)
    return
  end
  connection_groups.edit_group(group)
end

function M.open_group(name)
  connection_groups.open(name)
end

function M.edit_group(name)
  connection_groups.edit_group(name)
end

function M.create_group(name)
  connection_groups.create_group(name)
end

function M.manage_groups()
  connection_groups.manage_groups()
end

-- Plugin-like entrypoint: initialize DBUI connection list + commands.
function M.setup(opts)
  local options = opts or {}
  local default_group = options.default_group or "all"
  command_name = options.command_name or command_name

  vim.g.dbs = M.connections(default_group)
  connection_groups.setup({
    command_name = command_name,
    icon_style = options.icon_style,
    group_labels = options.group_labels,
    group_placeholders = options.group_placeholders,
    icons = options.icons,
    backup_dir = options.backup_dir,
    confirm_open = options.confirm_open,
    confirm_open_group = options.confirm_open_group,
    confirm_modify = options.confirm_modify,
    confirm_delete = options.confirm_delete,
    delete_to_trash = options.delete_to_trash,
  })
end

return M
