local M = {}

function M.normalize_filter_pattern(pattern)
  return vim.trim(pattern or "")
end

function M.has_token_match(values, pattern)
  local normalized = M.normalize_filter_pattern(pattern)
  if normalized == "" then
    return true
  end
  normalized = string.lower(normalized)

  for _, value in ipairs(values or {}) do
    if string.find(string.lower(tostring(value)), normalized, 1, true) then
      return true
    end
  end
  return false
end

function M.find_matches(match_index, pattern, keys)
  local result = {}
  local target = type(keys) == "table" and keys or {}

  for _, key in ipairs(target) do
    local haystack = match_index[key]
    if haystack and M.has_token_match(haystack, pattern) then
      result[#result + 1] = key
    end
  end

  return result
end

return M
