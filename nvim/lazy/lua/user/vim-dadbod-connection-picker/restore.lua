local M = {}

local BACKUP_HISTORY_LIMIT = 20

local restore_state = {
  busy = false,
  journal = nil,
  redo = nil,
}

local defaults_provider = function()
  return {}
end
local group_data = nil
local open_file_fn = nil
local confirm_action_fn = nil

local show_info_fn = function(message)
  vim.notify(message, vim.log.levels.INFO)
end
local show_warn_fn = function(message)
  vim.notify(message, vim.log.levels.WARN)
end
local show_error_fn = function(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function defaults()
  local current = defaults_provider()
  if type(current) ~= "table" then
    return {}
  end
  return current
end

local function normalize_backup_dir(path)
  local fallback = vim.fn.stdpath("data") .. "/vim-dadbod-connection-picker/connections-backup"
  if type(path) ~= "string" or vim.trim(path) == "" then
    return fallback
  end
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

local function ensure_directory(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  local mkdir_ok = vim.fn.mkdir(path, "p")
  if mkdir_ok ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    return false
  end
  return true
end

function M.normalize_backup_path(path)
  if type(path) ~= "string" then
    return nil
  end
  local normalized = vim.fn.fnamemodify(vim.trim(path), ":p")
  if normalized == "" then
    return nil
  end
  return normalized:gsub("/+$", "")
end

function M.resolve_backup_dir(raw_dir)
  local preferred = normalize_backup_dir(raw_dir)
  if ensure_directory(preferred) then
    return M.normalize_backup_path(preferred)
  end

  local fallback = normalize_backup_dir(nil)
  if ensure_directory(fallback) then
    return M.normalize_backup_path(fallback)
  end

  return nil
end

local function restore_journal()
  local journal = restore_state.journal
  if type(journal) ~= "table" then
    journal = {}
    restore_state.journal = journal
  end
  return journal
end

local function restore_redo()
  local redo = restore_state.redo
  if type(redo) ~= "table" then
    redo = {}
    restore_state.redo = redo
  end
  return redo
end

local function clear_busy()
  restore_state.busy = false
end

function M.restore_redo_clear()
  restore_state.redo = {}
end

function M.restore_redo_push(entry)
  local raw_entry = entry or {}
  local undo_path = M.normalize_backup_path(raw_entry.undo_path)
  local redo_path = M.normalize_backup_path(raw_entry.redo_path)
  if not undo_path and not redo_path then
    return
  end

  local entry_group = raw_entry.group
  if type(entry_group) == "string" and group_data then
    entry_group = group_data.normalize_group_name(entry_group)
  end

  local next_stack = {
    {
      undo_path = undo_path,
      redo_path = redo_path,
      group = entry_group,
    },
  }

  local existing = restore_redo()
  for _, item in ipairs(existing) do
    if type(item) == "table" then
      local item_undo = M.normalize_backup_path(item.undo_path)
      local item_redo = M.normalize_backup_path(item.redo_path)
      if item_undo ~= undo_path or item_redo ~= redo_path then
        next_stack[#next_stack + 1] = item
      end
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #next_stack) do
    existing[i] = next_stack[i]
  end
  for i = #next_stack + 1, #existing do
    existing[i] = nil
  end
end

function M.restore_redo_pop()
  local redo = restore_redo()
  local top = redo[1]
  if not top then
    return nil
  end
  table.remove(redo, 1)
  return top
end

function M.record_backup_path(backup_path, opts)
  opts = opts or {}
  local normalized = M.normalize_backup_path(backup_path)
  if not normalized then
    return
  end

  local journal = restore_journal()
  local deduped = {}
  table.insert(deduped, normalized)

  for _, path in ipairs(journal) do
    local normalized_path = M.normalize_backup_path(path)
    if normalized_path and normalized_path ~= normalized then
      deduped[#deduped + 1] = normalized_path
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #deduped) do
    journal[i] = deduped[i]
  end
  for i = #deduped + 1, #journal do
    journal[i] = nil
  end

  if opts.clear_redo ~= false then
    M.restore_redo_clear()
  end
end

function M.consume_backup_entry(backup_path)
  local normalized = M.normalize_backup_path(backup_path)
  if not normalized then
    return
  end

  local journal = restore_journal()
  local next_journal = {}
  for _, path in ipairs(journal) do
    local normalized_path = M.normalize_backup_path(path)
    if normalized_path ~= normalized then
      next_journal[#next_journal + 1] = normalized_path
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #next_journal) do
    journal[i] = next_journal[i]
  end
  for i = #next_journal + 1, #journal do
    journal[i] = nil
  end
end

function M.backup_group_from_path(path)
  if type(path) ~= "string" then
    return nil
  end
  local base = vim.fn.fnamemodify(path, ":t")
  if base == "" then
    return nil
  end

  local without_suffix = base:gsub("%.bak$", "")
  while without_suffix:match("%.%d+$") do
    without_suffix = without_suffix:gsub("%.%d+$", "")
  end
  without_suffix = without_suffix:gsub("%.lua$", "")
  return without_suffix ~= "" and without_suffix or nil
end

function M.is_existing_backup_path(path)
  local normalized = M.normalize_backup_path(path)
  return type(normalized) == "string" and vim.fn.filereadable(normalized) == 1
end

function M.latest_backup_from_journal(target_group)
  local journal = restore_journal()
  for _, path in ipairs(journal) do
    local group = M.backup_group_from_path(path)
    if not group then
      -- skip malformed backup filenames
    elseif target_group and group ~= target_group then
      -- skip different group
    elseif M.is_existing_backup_path(path) then
      return path, group
    end
  end
  return nil, nil
end

function M.next_backup_path(path)
  local configured = defaults()
  local backup_dir = M.resolve_backup_dir(configured.backup_dir)
  if not backup_dir then
    return nil
  end
  if type(path) ~= "string" then
    return nil
  end

  local filename = vim.fn.fnamemodify(path, ":t")
  if filename == "" then
    return nil
  end

  local timestamp = os.date("%Y%m%d%H%M%S")
  local next_index = 1
  local candidate = string.format("%s/%s.%s.bak", backup_dir, filename, timestamp)
  while vim.fn.filereadable(candidate) == 1 do
    next_index = next_index + 1
    candidate = string.format("%s/%s.%s.%d.bak", backup_dir, filename, timestamp, next_index)
  end

  return candidate
end

function M.copy_file(source, destination)
  if type(source) ~= "string" or type(destination) ~= "string" then
    return false, "invalid path"
  end
  local destination_dir = vim.fn.fnamemodify(destination, ":h")
  if not ensure_directory(destination_dir) then
    return false, "failed to create destination directory: " .. destination_dir
  end

  if vim.loop.fs_copyfile then
    local ok, err = vim.loop.fs_copyfile(source, destination)
    if ok then
      return true
    end
    return false, tostring(err)
  end

  local read_ok, lines_or_err = pcall(vim.fn.readfile, source)
  if not read_ok or type(lines_or_err) ~= "table" then
    return false, tostring(lines_or_err or "read failed")
  end

  local write_ok, write_err = pcall(vim.fn.writefile, lines_or_err, destination)
  if not write_ok then
    return false, tostring(write_err)
  end
  return true
end

function M.latest_any_group_backup(target_group)
  local dirs = {}
  local seen = {}

  local function add_path(path)
    if type(path) ~= "string" then
      return
    end
    if seen[path] then
      return
    end
    seen[path] = true
    dirs[#dirs + 1] = path
  end

  local configured_backup_dir = M.resolve_backup_dir(defaults().backup_dir)
  if configured_backup_dir then
    add_path(configured_backup_dir)
  end

  if group_data then
    add_path(group_data.connections_dir())
    for _, dir in ipairs(group_data.connection_file_dirs()) do
      add_path(dir)
    end
  end

  local candidates = {}
  for _, dir in ipairs(dirs) do
    local pattern = dir .. "/*.lua.*.bak"
    local backup_matches = vim.fn.glob(pattern, false, true)
    for _, backup in ipairs(backup_matches) do
      local stat = vim.loop.fs_stat(backup)
      if stat and stat.mtime and stat.mtime.sec then
        local group = M.backup_group_from_path(backup)
        local is_eligible = true
        if not group then
          is_eligible = false
        elseif target_group and group ~= target_group then
          is_eligible = false
        end
        if is_eligible then
          candidates[#candidates + 1] = {
            path = backup,
            group = group,
            mtime = stat.mtime.sec,
          }
        end
      end
    end
  end

  table.sort(candidates, function(lhs, rhs)
    return lhs.mtime > rhs.mtime
  end)

  if #candidates == 0 then
    return nil, nil, "No backup history found."
  end

  return candidates[1].path, candidates[1].group, nil
end

local function confirm_or_skip(message, detail, should_confirm, opts)
  if should_confirm == false then
    return true
  end
  if confirm_action_fn then
    return confirm_action_fn(message, detail, should_confirm, opts)
  end

  local use_confirm = should_confirm
  if use_confirm == nil then
    use_confirm = defaults().confirm_open
  end
  if not use_confirm then
    return true
  end

  local detail_lines = {}
  if detail then
    if type(detail) == "table" then
      detail_lines = detail
    else
      detail_lines = { detail }
    end
  end

  local prompt = message .. "\n"
  for _, line in ipairs(detail_lines) do
    if type(line) == "string" and vim.trim(line) ~= "" then
      prompt = prompt .. line .. "\n"
    end
  end

  local default_choice = (opts and opts.default) == 2 and 2 or 1
  local choice = vim.fn.confirm(vim.trim(prompt), "&Proceed\n&Cancel", default_choice)
  return choice == 1
end

function M.setup(opts)
  opts = opts or {}
  defaults_provider = opts.get_defaults or defaults_provider
  group_data = opts.group_data
  open_file_fn = opts.open_file
  confirm_action_fn = opts.confirm_action
  show_info_fn = opts.show_info or show_info_fn
  show_warn_fn = opts.show_warn or show_warn_fn
  show_error_fn = opts.show_error or show_error_fn
end

function M.restore_group(group, opts)
  opts = opts or {}
  local mode = opts.mode or "manual"
  local config = defaults()

  if restore_state.busy then
    return
  end
  restore_state.busy = true

  if mode == "undo" then
    -- keep redo stack for undo/redo traversal
  else
    M.restore_redo_clear()
  end

  local requested_group = nil
  if group and group ~= "" then
    if not group_data then
      clear_busy()
      show_error_fn("Missing group_data dependency in restore module.")
      return
    end
    requested_group = group_data.normalize_group_name(group)
    if not requested_group then
      clear_busy()
      show_warn_fn("Invalid group name: " .. tostring(group))
      return
    end
  end

  local backup_path
  local backup_group
  local err
  local entry
  local undo_backup_path

  if mode == "undo" then
    backup_path, backup_group, err = M.latest_backup_from_journal(requested_group)
    if not backup_path then
      backup_path, backup_group, err = M.latest_any_group_backup(requested_group)
    end
  elseif mode == "redo" then
    entry = M.restore_redo_pop()
    if not entry then
      clear_busy()
      show_warn_fn("No redo history.")
      return
    end
    backup_path = entry.redo_path
    backup_group = entry.group or M.backup_group_from_path(backup_path)
    undo_backup_path = entry.undo_path
  else
    backup_path, backup_group, err = M.latest_backup_from_journal(requested_group)
    if not backup_path then
      backup_path, backup_group, err = M.latest_any_group_backup(requested_group)
    end
  end

  if not backup_path then
    clear_busy()
    local msg = "No restore history."
    if requested_group then
      msg = "No restore history for group: " .. requested_group
    end
    show_warn_fn(err or msg)
    return
  end

  if not M.is_existing_backup_path(backup_path) then
    clear_busy()
    show_warn_fn("Selected backup no longer exists: " .. tostring(backup_path))
    return
  end

  if not backup_group then
    clear_busy()
    show_warn_fn("Failed to identify group from latest backup.")
    return
  end
  if not group_data then
    clear_busy()
    show_error_fn("Missing group_data dependency in restore module.")
    return
  end

  local restore_group = group_data.normalize_group_name(backup_group)
  if not restore_group then
    clear_busy()
    show_warn_fn("Failed to identify group from latest backup.")
    return
  end

  local restore_path = group_data.group_file(restore_group)
  if not restore_path then
    clear_busy()
    show_warn_fn("Unable to resolve restore target group: " .. tostring(restore_group))
    return
  end

  restore_path = M.normalize_backup_path(restore_path)
  if type(restore_path) ~= "string" or restore_path == "" then
    clear_busy()
    show_error_fn("Unable to resolve restore target path.")
    return
  end

  local redo_snapshot
  if mode == "undo" and vim.fn.filereadable(restore_path) == 1 then
    redo_snapshot = M.next_backup_path(restore_path)
    if not redo_snapshot then
      clear_busy()
      show_error_fn("Failed to resolve redo snapshot path.")
      return
    end

    local snapshot_ok, snapshot_err = M.copy_file(restore_path, redo_snapshot)
    if not snapshot_ok then
      clear_busy()
      show_error_fn("Failed to snapshot current file for redo: " .. tostring(snapshot_err))
      return
    end
  end

  local title = "Restore latest backup?"
  if mode == "undo" then
    title = "Undo (restore previous backup)?"
  elseif mode == "redo" then
    title = "Redo (restore latest undone state)?"
  end

  if
    not confirm_or_skip(
      title,
      string.format("Group: %s\nTarget: %s\nBackup: %s", restore_group, restore_path, backup_path),
      (config and config.confirm_modify),
      {
        confirm_label = "&Proceed",
        cancel_label = "&Cancel",
        default = 1,
      }
    )
  then
    if redo_snapshot then
      vim.fn.delete(redo_snapshot)
    end
    clear_busy()
    return
  end

  local safe_backup
  if vim.fn.filereadable(restore_path) == 1 then
    safe_backup = M.next_backup_path(restore_path)
    if not safe_backup then
      safe_backup = restore_path .. ".dbcp.before"
    end

    local ok, backup_err = vim.loop.fs_rename(restore_path, safe_backup)
    if not ok then
      if redo_snapshot then
        vim.fn.delete(redo_snapshot)
      end
      clear_busy()
      show_error_fn("Failed to backup current group file before restore: " .. tostring(backup_err))
      return
    end
  end

  local ok, restore_err = M.copy_file(backup_path, restore_path)
  if not ok then
    if safe_backup then
      local rollback_ok, rollback_err = vim.loop.fs_rename(safe_backup, restore_path)
      if not rollback_ok then
        show_error_fn(
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
    clear_busy()
    show_error_fn("Failed to restore group from backup: " .. tostring(restore_err))
    return
  end

  if safe_backup then
    vim.fn.delete(safe_backup)
  end

  if mode == "undo" and redo_snapshot == nil and vim.fn.filereadable(restore_path) == 1 then
    redo_snapshot = M.next_backup_path(restore_path)
    if redo_snapshot then
      local snapshot_ok, snapshot_err = M.copy_file(restore_path, redo_snapshot)
      if not snapshot_ok then
        show_warn_fn("Failed to snapshot restored state for redo: " .. tostring(snapshot_err))
        redo_snapshot = nil
      end
    end
  end

  if mode == "undo" then
    M.consume_backup_entry(backup_path)
    M.restore_redo_push({
      undo_path = backup_path,
      redo_path = redo_snapshot,
      group = restore_group,
    })
  elseif mode == "redo" then
    if undo_backup_path then
      M.record_backup_path(undo_backup_path, { clear_redo = false })
    end
  end

  clear_busy()
  if mode == "undo" then
    show_info_fn("Undid restore for: " .. restore_group)
  elseif mode == "redo" then
    show_info_fn("Redid restore for: " .. restore_group)
  else
    show_info_fn("Restored group from backup: " .. restore_group)
  end

  if type(opts.on_success) == "function" then
    opts.on_success()
    return
  end

  local open_file = opts.open_file or open_file_fn
  if type(open_file) == "function" then
    open_file(restore_path)
  end
end

return M
