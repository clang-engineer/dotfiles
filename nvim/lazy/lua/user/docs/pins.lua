-- persistent pins for the docs viewer: a flat list of file/folder paths the user
-- marks as favorites. stored as JSON in stdpath("data") (machine-local, like the
-- picker's own frecency store). pins float to the top of :Docs; frecency sorts the rest.
local M = {}

local store = vim.fs.normalize(vim.fn.stdpath("data") .. "/docs-pins.json")

-- session cache: pins only change through M.toggle (which refreshes it), so we never
-- re-read the file per rendered item — is_pinned runs in the picker's format/transform.
local cache

local function read()
  if not cache then
    local f = io.open(store, "r")
    if f then
      local data = f:read("*a")
      f:close()
      local ok, list = pcall(vim.json.decode, data)
      cache = (ok and type(list) == "table") and list or {}
    else
      cache = {}
    end
  end
  return cache
end

local function write(list)
  cache = list
  local f = io.open(store, "w")
  if f then
    f:write(vim.json.encode(list))
    f:close()
  end
end

-- pinned paths that still exist on disk (stale entries are dropped silently)
function M.list()
  local out = {}
  for _, path in ipairs(read()) do
    if vim.uv.fs_stat(path) then
      out[#out + 1] = path
    end
  end
  return out
end

function M.is_pinned(path)
  path = vim.fs.normalize(path)
  for _, p in ipairs(read()) do
    if vim.fs.normalize(p) == path then
      return true
    end
  end
  return false
end

-- add/remove `path`; returns true if it is now pinned
function M.toggle(path)
  path = vim.fs.normalize(path)
  local list, found = {}, false
  for _, p in ipairs(read()) do
    if vim.fs.normalize(p) == path then
      found = true
    else
      list[#list + 1] = p
    end
  end
  if not found then
    list[#list + 1] = path
  end
  write(list)
  return not found
end

return M
