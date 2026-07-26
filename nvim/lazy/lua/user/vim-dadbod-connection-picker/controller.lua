local M = {}

local backup_store = require("user.vim-dadbod-connection-picker.restore.store")
local commands = require("user.vim-dadbod-connection-picker.commands")
local config = require("user.vim-dadbod-connection-picker.config")
local dbui = require("user.vim-dadbod-connection-picker.dbui")
local group_actions = require("user.vim-dadbod-connection-picker.groups.actions")
local group_data = require("user.vim-dadbod-connection-picker.groups.store")
local restore = require("user.vim-dadbod-connection-picker.restore")
local ui = require("user.vim-dadbod-connection-picker.ui")
local util = require("user.vim-dadbod-connection-picker.util")

function M.show_info(message)
  vim.notify(message, vim.log.levels.INFO)
end

function M.show_warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

local function apply_group_prefix(group, conn)
  if type(conn) ~= "table" or type(conn.name) ~= "string" or conn.url == nil then
    return conn
  end
  if conn.name == "" or conn.name:match("^%[[^%]]+%] ") then
    return conn
  end
  local label = config.group_label(group)
  if type(label) ~= "string" or label == "" then
    return conn
  end
  return vim.tbl_extend("force", conn, { name = string.format("[%s] %s", label, conn.name) })
end

function M.connections(target, opts)
  local groups = group_data.build_group_connections()
  local result = {}
  local prefix = opts and opts.prefix
  local function add(group, conn)
    result[#result + 1] = prefix and apply_group_prefix(group, conn) or conn
  end

  local selected = target
  if selected and selected ~= "all" then
    selected = group_data.normalize_group_name(selected)
    if not selected or type(groups[selected]) ~= "table" then
      return nil
    end
    for _, conn in ipairs(groups[selected]) do
      add(selected, conn)
    end
    return result
  end
  for _, group in ipairs(util.sorted_keys(groups)) do
    for _, conn in ipairs(groups[group] or {}) do
      add(group, conn)
    end
  end
  return result
end

function M.open_connection(group, conn)
  if type(conn) ~= "table" or type(conn.url) ~= "string" then
    return false
  end
  local name = conn.name and conn.name ~= "" and conn.name or group
  if
    not ui.confirm_action(
      "Open connection?",
      string.format("Group: %s\nName: %s", tostring(group), tostring(name)),
      config.get().confirm_open
    )
  then
    return false
  end
  M.open({ { name = conn.name, url = conn.url } })
  return true
end

function M.open(group, _, opts)
  local list = type(group) == "table" and group or M.connections(group, { prefix = opts and opts.prefix })
  if not list then
    M.show_warn("No connections found for group: " .. tostring(group))
    return
  end
  if vim.tbl_isempty(list) then
    M.show_warn("No DB connections found to open")
    return
  end
  dbui.open(list, M.show_warn)
end

function M.pick_group(opts)
  require("user.vim-dadbod-connection-picker.picker").pick_group(opts or {})
end

function M.restore_group(group, opts)
  return restore.restore_group(group, opts)
end

local function group_candidates()
  local groups = util.sorted_keys(group_data.build_group_connections())
  if not util.has_value(groups, "all") then
    groups[#groups + 1] = "all"
  end
  return groups
end

function M.setup(opts)
  config.setup(opts)
  config.set_backup_dir(backup_store.resolve_dir(config.get().backup_dir))
  ui.setup({
    get_defaults = config.get,
    show_warn = M.show_warn,
  })
  commands.setup({
    command_name = config.command_name(),
    open_group_picker = M.pick_group,
    open = M.open,
    edit_group = group_actions.edit,
    create_group = group_actions.create,
    restore_group = M.restore_group,
    show_info = M.show_info,
    show_warn = M.show_warn,
    group_candidates = group_candidates,
  })
end

return M
