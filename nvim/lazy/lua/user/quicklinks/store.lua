-- quicklinks.md 파싱 + 추가
-- 형식: - [name](target) #tag1 #tag2
local M = {}

local FILENAME = "quicklinks.md"

local function parse_line(line)
  local name, target = line:match("^%s*[-*]%s*%[(.-)%]%((.-)%)")
  if not name or not target then
    return nil
  end
  local tags = {}
  for tag in line:gmatch("#([%w_-]+)") do
    table.insert(tags, tag)
  end
  return { name = name, target = target, tags = tags }
end

function M.path(dir)
  return dir .. "/" .. FILENAME
end

function M.load(dir)
  local path = M.path(dir)
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  local entries = {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    local entry = parse_line(line)
    if entry then
      table.insert(entries, entry)
    end
  end
  return entries
end

function M.append(dir, name, target)
  local path = M.path(dir)
  local line = string.format("- [%s](%s)", name, target)
  if vim.fn.filereadable(path) == 1 then
    vim.fn.writefile({ line }, path, "a")
  else
    vim.fn.writefile({ "# Quicklinks", "", line }, path)
  end
end

return M
