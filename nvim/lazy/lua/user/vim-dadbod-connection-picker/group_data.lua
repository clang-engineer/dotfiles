local M = {}

local connection_glob = "lua/user/vim-dadbod-connection-picker/connections/*.lua"

local function normalize_input_name(value)
  if type(value) ~= "string" then
    return nil
  end

  local name = vim.trim(value)
  if name:sub(-4) == ".lua" then
    name = name:sub(1, -5)
  end

  if name == "" then
    return nil
  end

  return name
end

function M.connections_dir()
  return vim.fn.stdpath("config") .. "/lua/user/vim-dadbod-connection-picker/connections"
end

function M.list_connection_files()
  local files = vim.api.nvim_get_runtime_file(connection_glob, true)
  table.sort(files)
  return files
end

function M.normalize_group_name(group)
  return normalize_input_name(group)
end

function M.group_name_from_path(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

function M.group_file(group)
  local normalized = M.normalize_group_name(group)
  if not normalized then
    return nil
  end

  for _, path in ipairs(M.list_connection_files()) do
    if M.group_name_from_path(path) == normalized then
      return path
    end
  end

  return M.connections_dir() .. "/" .. normalized .. ".lua"
end

local function normalize_connection(conn)
  if type(conn) ~= "table" then
    return nil
  end
  if type(conn.name) ~= "string" or conn.name == "" then
    return nil
  end
  if type(conn.url) ~= "string" or conn.url == "" then
    return nil
  end

  return {
    name = conn.name,
    url = conn.url,
  }
end

local function load_file(path)
  local loader = loadfile(path)
  if not loader then
    return nil
  end

  local ok, result = pcall(loader)
  if not ok or type(result) ~= "table" then
    return nil
  end

  return result
end

function M.load_group_connections(group)
  local path = M.group_file(group)
  if not path then
    return nil, nil
  end

  local raw = load_file(path)
  if not raw then
    return nil, path
  end

  local result = {}
  for _, item in ipairs(raw) do
    local normalized = normalize_connection(item)
    if normalized then
      table.insert(result, normalized)
    end
  end

  return result, path
end

function M.write_group_file(path, connections)
  local lines = { "return {" }
  for _, conn in ipairs(connections or {}) do
    local name = type(conn.name) == "string" and conn.name or ""
    local url = type(conn.url) == "string" and conn.url or ""
    lines[#lines + 1] = string.format("  { name = %q, url = %q },", name, url)
  end
  lines[#lines + 1] = "}"

  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(lines, path)
end

function M.connection_file_dirs()
  local dirs = {}
  local seen = {}

  for _, path in ipairs(M.list_connection_files()) do
    local dir = vim.fn.fnamemodify(path, ":h")
    if dir ~= "" and not seen[dir] then
      seen[dir] = true
      dirs[#dirs + 1] = dir
    end
  end

  local fallback = M.connections_dir()
  if fallback ~= "" and not seen[fallback] then
    seen[fallback] = true
    dirs[#dirs + 1] = fallback
  end

  return dirs
end

function M.group_file_exists(group)
  local path = M.group_file(group)
  if not path then
    return false
  end
  return vim.fn.filereadable(path) == 1
end

function M.build_group_connections()
  local groups = {}
  local seen = {}

  for _, path in ipairs(M.list_connection_files()) do
    local group = M.group_name_from_path(path)
    if not seen[group] then
      seen[group] = true
      groups[group] = {}
    end

    local raw = load_file(path)
    if type(raw) == "table" then
      for _, item in ipairs(raw) do
        local normalized = normalize_connection(item)
        if normalized then
          table.insert(groups[group], normalized)
        end
      end
    end
  end

  return groups
end

function M.build_group_metadata()
  local groups = {}
  local seen = {}

  for _, path in ipairs(M.list_connection_files()) do
    local group = M.group_name_from_path(path)
    if not seen[group] then
      seen[group] = true
      groups[group] = {
        path = path,
        connections = {},
      }
    end

    local raw = load_file(path)
    if type(raw) == "table" then
      for _, item in ipairs(raw) do
        local normalized = normalize_connection(item)
        if normalized then
          table.insert(groups[group].connections, normalized)
        end
      end
    end
  end

  return groups
end

return M
