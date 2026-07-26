local M = {}

local backup_store = require("user.vim-dadbod-connection-picker.restore.store")
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

local function backup(path)
  local backup_path = backup_store.next_path(path)
  if not backup_path then
    return nil, "Failed to resolve backup path."
  end
  local ok, err = backup_store.copy(path, backup_path)
  if not ok then
    return nil, "Failed to backup group: " .. tostring(err)
  end
  backup_store.record(backup_path)
  return backup_path
end

local function delete_connection(item, on_success)
  local connections, path = group_data.load_group_connections(item.group)
  if not path then
    warn("No group file found: " .. item.group)
    return
  end
  connections = type(connections) == "table" and connections or {}
  local target = connections[item.connection_index]
  if not target then
    warn("No matching connection found in group: " .. item.group)
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
      config.get().confirm_delete,
      { confirm_label = "&Delete", cancel_label = "&Keep", default = 2 }
    )
  then
    return
  end

  local backup_path
  if config.get().delete_to_trash then
    local backup_err
    backup_path, backup_err = backup(path)
    if not backup_path then
      error(backup_err)
      return
    end
  end
  table.remove(connections, item.connection_index)
  local wrote_ok, write_err = pcall(group_data.write_group_file, path, connections)
  if not wrote_ok then
    if backup_path then
      local restored, restore_err = backup_store.copy(backup_path, path)
      if not restored then
        error(
          "Failed to restore backup after write failure: "
            .. tostring(restore_err)
            .. ". Backup exists: "
            .. tostring(backup_path)
        )
      else
        error("Failed to delete connection: " .. tostring(write_err))
      end
    else
      error("Failed to delete connection: " .. tostring(write_err))
    end
    return
  end
  if backup_path then
    info("Backed up group before delete: " .. backup_path)
  end
  info("Deleted connection from " .. item.group .. ": " .. tostring(target.name or "unnamed"))
  on_success()
end

local function delete_group(item, on_success)
  local path = group_data.group_file(item.group)
  if not path then
    warn("Unable to resolve group file for: " .. tostring(item.group))
    return
  end
  if vim.fn.filereadable(path) ~= 1 then
    warn("No group file found: " .. tostring(item.group))
    return
  end
  if
    not ui.confirm_action(
      "Delete group?",
      string.format("Group: %s\nPath: %s", item.group, path),
      config.get().confirm_delete,
      { confirm_label = "&Delete", cancel_label = "&Keep", default = 2 }
    )
  then
    return
  end
  if config.get().delete_to_trash then
    local backup_path, backup_err = backup(path)
    if not backup_path then
      error(backup_err)
      return
    end
    if vim.fn.delete(path) ~= 0 then
      error("Failed to delete group file: " .. path)
      return
    end
    info("Moved group to backup: " .. backup_path)
  else
    if vim.fn.delete(path) ~= 0 then
      error("Failed to delete group file: " .. path)
      return
    end
    info("Deleted group: " .. item.group)
  end
  on_success({ move_up = true })
end

function M.delete(item, on_success)
  if item.kind == "connection" then
    if type(item.connection_index) ~= "number" then
      warn("No stable connection row index. Move to a connection line and try again.")
      return
    end
    delete_connection(item, on_success)
  elseif item.kind == "group" then
    delete_group(item, on_success)
  else
    warn("Move to a group row to delete it.")
  end
end

return M
