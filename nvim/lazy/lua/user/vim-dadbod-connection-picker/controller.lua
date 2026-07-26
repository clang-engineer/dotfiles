local M = {}

local commands = require("user.vim-dadbod-connection-picker.commands")
local dbui = require("user.vim-dadbod-connection-picker.dbui")
local group_data = require("user.vim-dadbod-connection-picker.group_data")
local restore = require("user.vim-dadbod-connection-picker.restore")
local ui = require("user.vim-dadbod-connection-picker.ui")
local util = require("user.vim-dadbod-connection-picker.util")

local defaults = {
  group_labels = {},
  group_placeholders = {
    { name = "example", url = "postgresql://localhost:5432/db" },
  },
  icon_style = "ascii",
  backup_dir = nil,
  confirm_open = false,
  confirm_open_group = false,
  confirm_modify = false,
  confirm_delete = true,
  delete_to_trash = true,
  icons = {},
}
local command_name = "DBPicker"

local icon_styles = {
  ascii = {
    folder_expanded = "[-]",
    folder_collapsed = "[+]",
    open_group = ">",
    open_all = ">>",
  },
  emoji = {
    folder_expanded = "📂",
    folder_collapsed = "📁",
    open_group = "📂",
    open_all = "🚀",
  },
  nerd = {
    folder_expanded = "",
    folder_collapsed = "",
    open_group = "",
    open_all = "+",
  },
}

local group_icons = {}
local group_label_map = {}

function M.show_info(message)
  vim.notify(message, vim.log.levels.INFO)
end

function M.show_warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

function M.show_error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function normalize_icons(options)
  local style_name = options.icon_style or "ascii"
  local style = icon_styles[style_name] or icon_styles.ascii
  local merged = vim.tbl_extend("force", style, options.icons or {})
  return {
    folder_expanded = merged.folder_expanded or style.folder_expanded,
    folder_collapsed = merged.folder_collapsed or style.folder_collapsed,
    open_group = merged.open_group or style.open_group,
    open_all = merged.open_all or merged.open_group or style.open_group,
  }
end

function M.get_defaults()
  return defaults
end

function M.get_group_icons()
  return group_icons
end

function M.get_command_name()
  return command_name
end

function M.resolve_group_label(group)
  if type(group) ~= "string" or group == "" then
    return group
  end

  local mapped = group_label_map[group]
  if type(mapped) == "string" and mapped ~= "" then
    return mapped
  end
  return group
end

local function next_placeholder()
  local source = defaults.group_placeholders
  if type(source) ~= "table" or #source == 0 then
    return {
      name = "example",
      url = "postgresql://localhost:5432/db",
    }
  end

  local raw = source[1]
  return {
    name = raw.name or "example",
    url = raw.url or "postgresql://localhost:5432/db",
  }
end

function M.fill_connection_with_prompt(on_done)
  local next_conn = next_placeholder()
  vim.ui.input({
    prompt = "Connection name: ",
    default = next_conn.name,
  }, function(name)
    if name == nil then
      return
    end
    if name == "" then
      name = next_conn.name
    end

    vim.ui.input({
      prompt = "Connection URL: ",
      default = next_conn.url,
    }, function(url)
      if url == nil then
        return
      end
      if url == "" then
        url = next_conn.url
      end
      on_done({ name = name, url = url })
    end)
  end)
end

function M.prompt_first_connection()
  vim.ui.input({
    prompt = "Group name: ",
    default = "local",
  }, function(raw_group)
    if raw_group == nil then
      return
    end

    local group = group_data.normalize_group_name(raw_group)
    if not group or group == "all" then
      M.show_warn("Invalid group name.")
      return
    end

    M.fill_connection_with_prompt(function(conn)
      if
        not ui.confirm_action(
          "Create first connection?",
          string.format("Group: %s\nName: %s\nURL: %s", group, conn.name, ui.mask_url(conn.url)),
          defaults.confirm_modify
        )
      then
        return
      end

      group_data.write_group_file(group_data.group_file(group), { conn })
      M.show_info("Created first DB connection: " .. conn.name)
      vim.schedule(function()
        M.pick_group({})
      end)
    end)
  end)
end

function M.prompt_new_group_name(default_name)
  vim.ui.input({
    prompt = "New group name: ",
    default = default_name or "",
  }, function(raw_name)
    if raw_name == nil then
      return
    end
    local normalized = group_data.normalize_group_name(raw_name)
    if not normalized or normalized == "" then
      M.show_warn("Invalid group name.")
      return
    end

    if not ui.confirm_action("Create new group?", "Group: " .. normalized, defaults.confirm_modify) then
      return
    end
    M.create_group(normalized)
  end)
end

function M.open_file(path)
  local escaped = vim.fn.fnameescape(path)
  local cmd = vim.bo.modifiable == false and ("edit! " .. escaped) or ("edit " .. escaped)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    M.show_error("Failed to open file: " .. path .. "\n" .. tostring(err))
  end
end

local function open_file_for_edit(path)
  vim.schedule(function()
    M.open_file(path)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local line_count = #lines
    local cursor_line = line_count > 1 and (line_count - 1) or line_count
    if cursor_line < 1 then
      cursor_line = 1
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { cursor_line, 0 })
    M.show_info("Edit newly added connection on the current line if needed.")
  end)
end

local function apply_group_prefix(group, conn)
  if type(conn) ~= "table" or type(conn.name) ~= "string" or conn.url == nil then
    return conn
  end
  if conn.name == "" or conn.name:match("^%[[^%]]+%] ") then
    return conn
  end

  local label = M.resolve_group_label(group)
  if type(label) ~= "string" or label == "" then
    return conn
  end
  return vim.tbl_extend("force", conn, { name = string.format("[%s] %s", label, conn.name) })
end

function M.connections(target, opts)
  local groups = group_data.build_group_connections()
  local result = {}
  local force_prefix = opts and opts.prefix

  local function add(group, conn)
    table.insert(result, force_prefix and apply_group_prefix(group, conn) or conn)
  end

  local selected_group = target
  if selected_group and selected_group ~= "all" then
    selected_group = group_data.normalize_group_name(selected_group)
    if not selected_group or type(groups[selected_group]) ~= "table" then
      return nil
    end
    for _, conn in ipairs(groups[selected_group]) do
      add(selected_group, conn)
    end
    return result
  end

  for _, name in ipairs(util.sorted_keys(groups)) do
    for _, conn in ipairs(groups[name] or {}) do
      add(name, conn)
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
      defaults.confirm_open
    )
  then
    return false
  end
  M.open({ { name = conn.name, url = conn.url } }, name)
  return true
end

function M.add_connection(group)
  local connections, path = group_data.load_group_connections(group)
  if not path then
    M.show_warn("No group file found: " .. group)
    return
  end
  if type(connections) ~= "table" then
    connections = {}
  end

  M.fill_connection_with_prompt(function(conn)
    if
      not ui.confirm_action(
        "Add new connection?",
        string.format("Group: %s\nName: %s\nURL: %s", group, conn.name or "", ui.mask_url(conn.url)),
        defaults.confirm_modify
      )
    then
      return
    end

    table.insert(connections, conn)
    group_data.write_group_file(path, connections)
    M.show_info("Added connection to group: " .. group)
    open_file_for_edit(path)
  end)
end

function M.rename_group(old_group, on_success)
  local old_path = group_data.group_file(old_group)
  if not old_path then
    M.show_warn("Unable to resolve group path: " .. tostring(old_group))
    return
  end

  vim.ui.input({ prompt = "Rename group: ", default = old_group }, function(raw_name)
    if raw_name == nil then
      return
    end
    local normalized = group_data.normalize_group_name(raw_name)
    if not normalized or normalized == "" then
      M.show_warn("Invalid group name.")
      return
    end
    if normalized == old_group then
      M.show_info("Rename cancelled.")
      return
    end
    if group_data.group_file_exists(normalized) then
      M.show_warn("Group already exists: " .. normalized)
      return
    end
    if
      not ui.confirm_action(
        "Rename group?",
        string.format("From: %s\nTo: %s", old_group, normalized),
        defaults.confirm_modify
      )
    then
      return
    end

    local ok, err = vim.loop.fs_rename(old_path, group_data.group_file(normalized))
    if not ok then
      M.show_error("Failed to rename group: " .. tostring(err))
      return
    end
    M.show_info("Renamed group: " .. old_group .. " -> " .. normalized)
    on_success({ move_up = true })
  end)
end

local function backup_group_file(path)
  local backup_path = restore.next_backup_path(path)
  if not backup_path then
    return nil, "Failed to resolve backup path."
  end
  local ok, err = restore.copy_file(path, backup_path)
  if not ok then
    return nil, "Failed to backup group: " .. tostring(err)
  end
  restore.record_backup_path(backup_path)
  return backup_path
end

local function delete_connection(item, on_success)
  local connections, path = group_data.load_group_connections(item.group)
  if not path then
    M.show_warn("No group file found: " .. item.group)
    return
  end
  if type(connections) ~= "table" then
    connections = {}
  end

  local target = connections[item.connection_index]
  if not target then
    M.show_warn("No matching connection found in group: " .. item.group)
    return
  end
  if
    not ui.confirm_action(
      "Delete connection?",
      string.format(
        "Group: %s\nName: %s\nURL: %s",
        item.group,
        tostring(target.name or ""),
        ui.mask_url(target.url or "")
      ),
      defaults.confirm_delete,
      { confirm_label = "&Delete", cancel_label = "&Keep", default = 2 }
    )
  then
    return
  end

  local backup_path
  if defaults.delete_to_trash then
    local err
    backup_path, err = backup_group_file(path)
    if not backup_path then
      M.show_error(err)
      return
    end
  end

  table.remove(connections, item.connection_index)
  local wrote_ok, write_err = pcall(group_data.write_group_file, path, connections)
  if not wrote_ok then
    if backup_path then
      local restore_ok, restore_err = restore.copy_file(backup_path, path)
      if not restore_ok then
        M.show_error(
          "Failed to restore backup after write failure: "
            .. tostring(restore_err)
            .. ". Backup exists: "
            .. tostring(backup_path)
        )
      else
        M.show_error("Failed to delete connection: " .. tostring(write_err))
      end
    else
      M.show_error("Failed to delete connection: " .. tostring(write_err))
    end
    return
  end

  if backup_path then
    M.show_info("Backed up group before delete: " .. backup_path)
  end
  M.show_info("Deleted connection from " .. item.group .. ": " .. tostring(target.name or "unnamed"))
  on_success()
end

local function delete_group(item, on_success)
  local path = group_data.group_file(item.group)
  if not path then
    M.show_warn("Unable to resolve group file for: " .. tostring(item.group))
    return
  end
  if vim.fn.filereadable(path) ~= 1 then
    M.show_warn("No group file found: " .. tostring(item.group))
    return
  end
  if
    not ui.confirm_action(
      "Delete group?",
      string.format("Group: %s\nPath: %s", item.group, path),
      defaults.confirm_delete,
      { confirm_label = "&Delete", cancel_label = "&Keep", default = 2 }
    )
  then
    return
  end

  if defaults.delete_to_trash then
    local backup_path, err = backup_group_file(path)
    if not backup_path then
      M.show_error(err)
      return
    end
    if vim.fn.delete(path) ~= 0 then
      M.show_error("Failed to delete group file: " .. path)
      return
    end
    M.show_info("Moved group to backup: " .. backup_path)
  else
    if vim.fn.delete(path) ~= 0 then
      M.show_error("Failed to delete group file: " .. path)
      return
    end
    M.show_info("Deleted group: " .. item.group)
  end
  on_success({ move_up = true })
end

function M.delete_item(item, on_success)
  if item.kind == "connection" then
    if type(item.connection_index) ~= "number" then
      M.show_warn("No stable connection row index. Move to a connection line and try again.")
      return
    end
    delete_connection(item, on_success)
    return
  end
  if item.kind ~= "group" then
    M.show_warn("Move to a group row to delete it.")
    return
  end
  delete_group(item, on_success)
end

function M.pick_group(opts)
  require("user.vim-dadbod-connection-picker.picker").pick_group(opts or {})
end

function M.manage_groups()
  require("user.vim-dadbod-connection-picker.picker").manage_groups()
end

function M.open(group, label_override, opts)
  local list
  local label
  if type(group) == "table" then
    list = group
    label = label_override or "selected"
  else
    list = M.connections(group, { prefix = opts and opts.prefix })
    if not list then
      M.show_warn("No connections found for group: " .. tostring(group))
      return
    end
    label = group == "all" and "all" or (group or "all")
  end

  if not list or vim.tbl_isempty(list) then
    M.show_warn("No DB connections found to open")
    return
  end
  M.current_group = label
  dbui.open(list, M.show_warn)
end

function M.edit_group(group)
  local _, path = group_data.load_group_connections(group)
  if not path then
    M.show_warn("No group file found: " .. tostring(group))
    return
  end
  M.open_file(path)
end

function M.create_group(group)
  local normalized = group_data.normalize_group_name(group)
  if not normalized then
    M.show_warn("Invalid group name: " .. tostring(group))
    return
  end
  if normalized == "all" then
    M.show_warn("Group name cannot be `all`.")
    return
  end

  local path = group_data.group_file(normalized)
  if not path then
    M.show_warn("Unable to resolve group file path.")
    return
  end
  if group_data.group_file_exists(normalized) then
    M.show_warn("Group already exists: " .. normalized .. " (opening existing file)")
    M.open_file(path)
    return
  end

  group_data.write_group_file(path, defaults.group_placeholders)
  M.show_info("Created group file: " .. path)
  M.open_file(path)
end

function M.restore_group(group, opts)
  return restore.restore_group(group, opts)
end

function M.group_candidates()
  local groups = util.sorted_keys(group_data.build_group_connections())
  if not util.has_value(groups, "all") then
    table.insert(groups, "all")
  end
  return groups
end

function M.setup(opts)
  local options = vim.tbl_extend("force", defaults, opts or {})
  options.backup_dir = restore.resolve_backup_dir(options.backup_dir)
  defaults = options
  command_name = options.command_name or command_name
  group_icons = normalize_icons(options)
  group_label_map = options.group_labels or {}

  ui.setup({
    get_defaults = M.get_defaults,
    show_warn = M.show_warn,
  })
  restore.setup({
    get_defaults = M.get_defaults,
    group_data = group_data,
    show_info = M.show_info,
    show_warn = M.show_warn,
    show_error = M.show_error,
    confirm_action = ui.confirm_action,
    open_file = M.open_file,
  })
  commands.setup({
    command_name = command_name,
    open_group_picker = M.pick_group,
    open = M.open,
    edit_group = M.edit_group,
    create_group = M.create_group,
    restore_group = M.restore_group,
    show_info = M.show_info,
    show_warn = M.show_warn,
    group_candidates = M.group_candidates,
  })
end

return M
