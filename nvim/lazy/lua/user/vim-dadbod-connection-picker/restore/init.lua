local M = {}

local backup_store = require("user.vim-dadbod-connection-picker.restore.store")
local config = require("user.vim-dadbod-connection-picker.config")
local group_actions = require("user.vim-dadbod-connection-picker.groups.actions")
local group_data = require("user.vim-dadbod-connection-picker.groups.store")
local ui = require("user.vim-dadbod-connection-picker.ui")

local busy = false

local function info(message)
  vim.notify(message, vim.log.levels.INFO)
end

local function warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

local function error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function clear_busy()
  busy = false
end

local function selected_backup(mode, requested_group)
  if mode == "redo" then
    local entry = backup_store.pop_redo()
    if not entry then
      return nil, nil, nil, nil, "No redo history."
    end
    return entry.redo_path, entry.group or backup_store.group_from_path(entry.redo_path), entry.undo_path
  end

  local path, group, err = backup_store.latest_from_journal(requested_group)
  if not path then
    path, group, err = backup_store.latest(requested_group)
  end
  return path, group, nil, err
end

local function restore_title(mode)
  if mode == "undo" then
    return "Undo (restore previous backup)?"
  end
  if mode == "redo" then
    return "Redo (restore latest undone state)?"
  end
  return "Restore latest backup?"
end

local function snapshot_for_redo(mode, restore_path)
  if mode ~= "undo" or vim.fn.filereadable(restore_path) ~= 1 then
    return nil, nil
  end
  local path = backup_store.next_path(restore_path)
  if not path then
    return nil, "Failed to resolve redo snapshot path."
  end
  local ok, err = backup_store.copy(restore_path, path)
  if not ok then
    return nil, "Failed to snapshot current file for redo: " .. tostring(err)
  end
  return path, nil
end

local function move_current_aside(restore_path, redo_snapshot)
  if vim.fn.filereadable(restore_path) ~= 1 then
    return nil, nil
  end
  local safe_backup = backup_store.next_path(restore_path) or (restore_path .. ".dbcp.before")
  local ok, err = vim.loop.fs_rename(restore_path, safe_backup)
  if ok then
    return safe_backup, nil
  end
  if redo_snapshot then
    vim.fn.delete(redo_snapshot)
  end
  return nil, "Failed to backup current group file before restore: " .. tostring(err)
end

local function copy_with_rollback(backup_path, restore_path, safe_backup, redo_snapshot)
  local ok, restore_err = backup_store.copy(backup_path, restore_path)
  if ok then
    if safe_backup then
      vim.fn.delete(safe_backup)
    end
    return true
  end

  if safe_backup then
    local rollback_ok, rollback_err = vim.loop.fs_rename(safe_backup, restore_path)
    if not rollback_ok then
      error(
        "Failed to restore current file after restore failure: "
          .. tostring(rollback_err)
          .. ". Backup at "
          .. tostring(safe_backup)
      )
    end
  end
  if redo_snapshot then
    vim.fn.delete(redo_snapshot)
  end
  error("Failed to restore group from backup: " .. tostring(restore_err))
  return false
end

function M.restore_group(group, opts)
  opts = opts or {}
  local mode = opts.mode or "manual"
  if busy then
    return
  end
  busy = true

  if mode ~= "undo" then
    backup_store.clear_redo()
  end

  local requested_group
  if group and group ~= "" then
    requested_group = group_data.normalize_group_name(group)
    if not requested_group then
      clear_busy()
      warn("Invalid group name: " .. tostring(group))
      return
    end
  end

  local backup_path, backup_group, undo_backup_path, selection_err, redo_err = selected_backup(mode, requested_group)
  if redo_err then
    clear_busy()
    warn(redo_err)
    return
  end
  if not backup_path then
    clear_busy()
    local message = requested_group and ("No restore history for group: " .. requested_group) or "No restore history."
    warn(selection_err or message)
    return
  end
  if not backup_store.exists(backup_path) then
    clear_busy()
    warn("Selected backup no longer exists: " .. tostring(backup_path))
    return
  end
  if not backup_group then
    clear_busy()
    warn("Failed to identify group from latest backup.")
    return
  end

  local restore_group = group_data.normalize_group_name(backup_group)
  if not restore_group then
    clear_busy()
    warn("Failed to identify group from latest backup.")
    return
  end
  local restore_path = group_data.group_file(restore_group)
  if not restore_path then
    clear_busy()
    warn("Unable to resolve restore target group: " .. tostring(restore_group))
    return
  end
  restore_path = backup_store.normalize_path(restore_path)
  if type(restore_path) ~= "string" or restore_path == "" then
    clear_busy()
    error("Unable to resolve restore target path.")
    return
  end

  local redo_snapshot, snapshot_err = snapshot_for_redo(mode, restore_path)
  if snapshot_err then
    clear_busy()
    error(snapshot_err)
    return
  end
  if
    not ui.confirm_action(
      restore_title(mode),
      string.format("Group: %s\nTarget: %s\nBackup: %s", restore_group, restore_path, backup_path),
      config.get().confirm_modify,
      { confirm_label = "&Proceed", cancel_label = "&Cancel", default = 1 }
    )
  then
    if redo_snapshot then
      vim.fn.delete(redo_snapshot)
    end
    clear_busy()
    return
  end

  local safe_backup, move_err = move_current_aside(restore_path, redo_snapshot)
  if move_err then
    clear_busy()
    error(move_err)
    return
  end
  if not copy_with_rollback(backup_path, restore_path, safe_backup, redo_snapshot) then
    clear_busy()
    return
  end

  if mode == "undo" and redo_snapshot == nil and vim.fn.filereadable(restore_path) == 1 then
    redo_snapshot = backup_store.next_path(restore_path)
    if redo_snapshot then
      local ok, err = backup_store.copy(restore_path, redo_snapshot)
      if not ok then
        warn("Failed to snapshot restored state for redo: " .. tostring(err))
        redo_snapshot = nil
      end
    end
  end
  if mode == "undo" then
    backup_store.consume(backup_path)
    backup_store.push_redo({ undo_path = backup_path, redo_path = redo_snapshot, group = restore_group })
  elseif mode == "redo" and undo_backup_path then
    backup_store.record(undo_backup_path, { clear_redo = false })
  end

  clear_busy()
  if mode == "undo" then
    info("Undid restore for: " .. restore_group)
  elseif mode == "redo" then
    info("Redid restore for: " .. restore_group)
  else
    info("Restored group from backup: " .. restore_group)
  end
  if type(opts.on_success) == "function" then
    opts.on_success()
    return
  end
  local open_file = opts.open_file or group_actions.open_file
  if type(open_file) == "function" then
    open_file(restore_path)
  end
end

return M
