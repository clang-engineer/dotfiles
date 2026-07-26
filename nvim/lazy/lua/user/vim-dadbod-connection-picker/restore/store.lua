local M = {}

local config = require("user.vim-dadbod-connection-picker.config")
local group_data = require("user.vim-dadbod-connection-picker.groups.store")

local HISTORY_LIMIT = 20
local journal = {}
local redo = {}

local function ensure_directory(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  local ok = vim.fn.mkdir(path, "p")
  return ok == 1 or vim.fn.isdirectory(path) == 1
end

function M.normalize_path(path)
  if type(path) ~= "string" then
    return nil
  end
  local normalized = vim.fn.fnamemodify(vim.trim(path), ":p")
  return normalized ~= "" and normalized:gsub("/+$", "") or nil
end

function M.resolve_dir(raw_dir)
  local fallback = vim.fn.stdpath("data") .. "/vim-dadbod-connection-picker/connections-backup"
  local preferred = fallback
  if type(raw_dir) == "string" and vim.trim(raw_dir) ~= "" then
    preferred = vim.fn.fnamemodify(vim.fn.expand(raw_dir), ":p")
  end
  if ensure_directory(preferred) then
    return M.normalize_path(preferred)
  end
  if ensure_directory(fallback) then
    return M.normalize_path(fallback)
  end
  return nil
end

function M.clear_redo()
  redo = {}
end

function M.push_redo(entry)
  local raw = entry or {}
  local undo_path = M.normalize_path(raw.undo_path)
  local redo_path = M.normalize_path(raw.redo_path)
  if not undo_path and not redo_path then
    return
  end

  local group = raw.group
  if type(group) == "string" then
    group = group_data.normalize_group_name(group)
  end
  local next_stack = { { undo_path = undo_path, redo_path = redo_path, group = group } }
  for _, item in ipairs(redo) do
    if type(item) == "table" then
      local item_undo = M.normalize_path(item.undo_path)
      local item_redo = M.normalize_path(item.redo_path)
      if item_undo ~= undo_path or item_redo ~= redo_path then
        next_stack[#next_stack + 1] = item
      end
    end
  end
  redo = {}
  for index = 1, math.min(HISTORY_LIMIT, #next_stack) do
    redo[index] = next_stack[index]
  end
end

function M.pop_redo()
  if not redo[1] then
    return nil
  end
  return table.remove(redo, 1)
end

function M.record(path, opts)
  local normalized = M.normalize_path(path)
  if not normalized then
    return
  end
  local next_journal = { normalized }
  for _, existing in ipairs(journal) do
    local normalized_existing = M.normalize_path(existing)
    if normalized_existing and normalized_existing ~= normalized then
      next_journal[#next_journal + 1] = normalized_existing
    end
  end
  journal = {}
  for index = 1, math.min(HISTORY_LIMIT, #next_journal) do
    journal[index] = next_journal[index]
  end
  if not opts or opts.clear_redo ~= false then
    M.clear_redo()
  end
end

function M.consume(path)
  local normalized = M.normalize_path(path)
  if not normalized then
    return
  end
  local next_journal = {}
  for _, existing in ipairs(journal) do
    local normalized_existing = M.normalize_path(existing)
    if normalized_existing ~= normalized then
      next_journal[#next_journal + 1] = normalized_existing
    end
  end
  journal = next_journal
end

function M.group_from_path(path)
  if type(path) ~= "string" then
    return nil
  end
  local name = vim.fn.fnamemodify(path, ":t")
  if name == "" then
    return nil
  end
  name = name:gsub("%.bak$", "")
  while name:match("%.%d+$") do
    name = name:gsub("%.%d+$", "")
  end
  name = name:gsub("%.lua$", "")
  return name ~= "" and name or nil
end

function M.exists(path)
  local normalized = M.normalize_path(path)
  return type(normalized) == "string" and vim.fn.filereadable(normalized) == 1
end

function M.latest_from_journal(target_group)
  for _, path in ipairs(journal) do
    local group = M.group_from_path(path)
    if group and (not target_group or group == target_group) and M.exists(path) then
      return path, group
    end
  end
  return nil, nil
end

function M.next_path(path)
  local backup_dir = M.resolve_dir(config.get().backup_dir)
  if not backup_dir or type(path) ~= "string" then
    return nil
  end
  local filename = vim.fn.fnamemodify(path, ":t")
  if filename == "" then
    return nil
  end

  local timestamp = os.date("%Y%m%d%H%M%S")
  local index = 1
  local candidate = string.format("%s/%s.%s.bak", backup_dir, filename, timestamp)
  while vim.fn.filereadable(candidate) == 1 do
    index = index + 1
    candidate = string.format("%s/%s.%s.%d.bak", backup_dir, filename, timestamp, index)
  end
  return candidate
end

function M.copy(source, destination)
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
  local read_ok, lines = pcall(vim.fn.readfile, source)
  if not read_ok or type(lines) ~= "table" then
    return false, tostring(lines or "read failed")
  end
  local write_ok, err = pcall(vim.fn.writefile, lines, destination)
  return write_ok, write_ok and nil or tostring(err)
end

function M.latest(target_group)
  local dirs = {}
  local seen = {}
  local function add(path)
    if type(path) == "string" and not seen[path] then
      seen[path] = true
      dirs[#dirs + 1] = path
    end
  end

  add(M.resolve_dir(config.get().backup_dir))
  add(group_data.connections_dir())
  for _, dir in ipairs(group_data.connection_file_dirs()) do
    add(dir)
  end

  local candidates = {}
  for _, dir in ipairs(dirs) do
    for _, backup in ipairs(vim.fn.glob(dir .. "/*.lua.*.bak", false, true)) do
      local stat = vim.loop.fs_stat(backup)
      local group = M.group_from_path(backup)
      if stat and stat.mtime and stat.mtime.sec and group and (not target_group or group == target_group) then
        candidates[#candidates + 1] = { path = backup, group = group, mtime = stat.mtime.sec }
      end
    end
  end
  table.sort(candidates, function(lhs, rhs)
    return lhs.mtime > rhs.mtime
  end)
  if not candidates[1] then
    return nil, nil, "No backup history found."
  end
  return candidates[1].path, candidates[1].group, nil
end

return M
