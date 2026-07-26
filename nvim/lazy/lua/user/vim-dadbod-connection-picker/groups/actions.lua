local M = {}

local config = require("user.vim-dadbod-connection-picker.config")
local group_data = require("user.vim-dadbod-connection-picker.groups.store")
local ui = require("user.vim-dadbod-connection-picker.ui")

local function info(message)
  vim.notify(message, vim.log.levels.INFO)
end

local function warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

local function error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function placeholder()
  local source = config.get().group_placeholders
  if type(source) ~= "table" or type(source[1]) ~= "table" then
    return { name = "example", url = "postgresql://localhost:5432/db" }
  end
  return {
    name = source[1].name or "example",
    url = source[1].url or "postgresql://localhost:5432/db",
  }
end

local function prompt_connection(on_done)
  local next_conn = placeholder()
  vim.ui.input({ prompt = "Connection name: ", default = next_conn.name }, function(name)
    if name == nil then
      return
    end
    vim.ui.input({ prompt = "Connection URL: ", default = next_conn.url }, function(url)
      if url == nil then
        return
      end
      on_done({
        name = name == "" and next_conn.name or name,
        url = url == "" and next_conn.url or url,
      })
    end)
  end)
end

function M.prompt_first_connection(on_created)
  vim.ui.input({ prompt = "Group name: ", default = "local" }, function(raw_group)
    if raw_group == nil then
      return
    end
    local group = group_data.normalize_group_name(raw_group)
    if not group or group == "all" then
      warn("Invalid group name.")
      return
    end
    prompt_connection(function(conn)
      if
        not ui.confirm_action(
          "Create first connection?",
          string.format("Group: %s\nName: %s\nURL: %s", group, conn.name, ui.mask_url(conn.url)),
          config.get().confirm_modify
        )
      then
        return
      end
      group_data.write_group_file(group_data.group_file(group), { conn })
      info("Created first DB connection: " .. conn.name)
      vim.schedule(on_created)
    end)
  end)
end

function M.prompt_new_group(default_name)
  vim.ui.input({ prompt = "New group name: ", default = default_name or "" }, function(raw_name)
    if raw_name == nil then
      return
    end
    local group = group_data.normalize_group_name(raw_name)
    if not group or group == "" then
      warn("Invalid group name.")
      return
    end
    if not ui.confirm_action("Create new group?", "Group: " .. group, config.get().confirm_modify) then
      return
    end
    M.create(group)
  end)
end

function M.open_file(path)
  local escaped = vim.fn.fnameescape(path)
  local command = vim.bo.modifiable == false and ("edit! " .. escaped) or ("edit " .. escaped)
  local ok, err = pcall(vim.cmd, command)
  if not ok then
    error("Failed to open file: " .. path .. "\n" .. tostring(err))
  end
end

local function open_new_connection(path)
  vim.schedule(function()
    M.open_file(path)
    local line_count = #vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor_line = line_count > 1 and line_count - 1 or line_count
    pcall(vim.api.nvim_win_set_cursor, 0, { math.max(cursor_line, 1), 0 })
    info("Edit newly added connection on the current line if needed.")
  end)
end

function M.edit(group)
  local _, path = group_data.load_group_connections(group)
  if not path then
    warn("No group file found: " .. tostring(group))
    return
  end
  M.open_file(path)
end

function M.create(group)
  local normalized = group_data.normalize_group_name(group)
  if not normalized then
    warn("Invalid group name: " .. tostring(group))
    return
  end
  if normalized == "all" then
    warn("Group name cannot be `all`.")
    return
  end
  local path = group_data.group_file(normalized)
  if not path then
    warn("Unable to resolve group file path.")
    return
  end
  if group_data.group_file_exists(normalized) then
    warn("Group already exists: " .. normalized .. " (opening existing file)")
    M.open_file(path)
    return
  end
  group_data.write_group_file(path, config.get().group_placeholders)
  info("Created group file: " .. path)
  M.open_file(path)
end

function M.add_connection(group)
  local connections, path = group_data.load_group_connections(group)
  if not path then
    warn("No group file found: " .. group)
    return
  end
  if type(connections) ~= "table" then
    connections = {}
  end
  prompt_connection(function(conn)
    if
      not ui.confirm_action(
        "Add new connection?",
        string.format("Group: %s\nName: %s\nURL: %s", group, conn.name or "", ui.mask_url(conn.url)),
        config.get().confirm_modify
      )
    then
      return
    end
    table.insert(connections, conn)
    group_data.write_group_file(path, connections)
    info("Added connection to group: " .. group)
    open_new_connection(path)
  end)
end

function M.rename(old_group, on_success)
  local old_path = group_data.group_file(old_group)
  if not old_path then
    warn("Unable to resolve group path: " .. tostring(old_group))
    return
  end
  vim.ui.input({ prompt = "Rename group: ", default = old_group }, function(raw_name)
    if raw_name == nil then
      return
    end
    local group = group_data.normalize_group_name(raw_name)
    if not group or group == "" then
      warn("Invalid group name.")
      return
    end
    if group == old_group then
      info("Rename cancelled.")
      return
    end
    if group_data.group_file_exists(group) then
      warn("Group already exists: " .. group)
      return
    end
    if
      not ui.confirm_action(
        "Rename group?",
        string.format("From: %s\nTo: %s", old_group, group),
        config.get().confirm_modify
      )
    then
      return
    end
    local ok, err = vim.loop.fs_rename(old_path, group_data.group_file(group))
    if not ok then
      error("Failed to rename group: " .. tostring(err))
      return
    end
    info("Renamed group: " .. old_group .. " -> " .. group)
    on_success({ move_up = true })
  end)
end

return M
