local M = {}

function M.filter_starts_with(values, needle)
  if type(values) ~= "table" or #values == 0 then
    return values or {}
  end
  if needle == nil or needle == "" then
    return values
  end

  local result = {}
  for _, value in ipairs(values) do
    if vim.startswith(tostring(value), needle) then
      result[#result + 1] = value
    end
  end
  return result
end

function M.sorted_keys(values)
  local keys = {}
  for key in pairs(values) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

function M.has_value(values, needle)
  for _, value in ipairs(values) do
    if value == needle then
      return true
    end
  end
  return false
end

return M
