local M = {}

local defaults_provider = function()
  return {}
end
local show_warn_fn = function(message)
  vim.notify(message, vim.log.levels.WARN)
end

function M.setup(opts)
  opts = opts or {}
  defaults_provider = opts.get_defaults or defaults_provider
  show_warn_fn = opts.show_warn or show_warn_fn
end

local function defaults()
  local current = defaults_provider()
  if type(current) ~= "table" then
    return {}
  end
  return current
end

function M.picker_shortcuts_hint()
  return {
    "/:filter, <CR>:open, a:add connection, n:add group, ? :shortcuts",
  }
end

function M.picker_shortcuts_hint_full()
  return {
    "/:filter, <CR>:open",
    "a:add connection",
    "n:add group",
    "e:edit",
    "r:rename",
    "d:delete",
    "u:undo",
    "<C-r>:redo",
    "?:compact",
  }
end

function M.normalize_hint_lines(raw)
  local lines = {}
  if type(raw) == "string" then
    if raw ~= "" then
      lines[#lines + 1] = raw
    end
    return lines
  end
  if type(raw) ~= "table" then
    return lines
  end
  for _, line in ipairs(raw) do
    if type(line) == "string" then
      local normalized = vim.trim(line)
      if normalized ~= "" then
        lines[#lines + 1] = normalized
      end
    end
  end
  return lines
end

function M.add_hint_rows(rows, raw_lines, opts)
  local lines = M.normalize_hint_lines(raw_lines)
  if #lines == 0 then
    return
  end

  local mode = opts and opts.mode or "append"
  local first_prefix = opts and opts.first_prefix or "> "
  local rest_prefix = opts and opts.rest_prefix or "  "

  local function make_row(prefix, text)
    rows[#rows + 1] = {
      text = prefix .. text,
      kind = "hint",
      preview = {
        text = text,
      },
    }
  end

  if mode == "prepend" then
    for idx = #lines, 1, -1 do
      local prefix = idx == #lines and first_prefix or rest_prefix
      table.insert(rows, 1, {
        text = prefix .. lines[idx],
        kind = "hint",
        preview = {
          text = lines[idx],
        },
      })
    end
    return
  end

  for idx, line in ipairs(lines) do
    local prefix = idx == 1 and first_prefix or rest_prefix
    make_row(prefix, line)
  end
end

function M.truncate_for_display(value)
  local max_len = 72
  if type(value) ~= "string" then
    return ""
  end
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len - 3) .. "..."
end

function M.mask_url(raw_url)
  if type(raw_url) ~= "string" then
    return raw_url
  end

  local scheme_start, scheme_end = raw_url:find("[%w][%w+.-]*://")
  if not scheme_start then
    return raw_url
  end

  local authority_and_path = raw_url:sub(scheme_end + 1)
  local authority, suffix = authority_and_path:match("^([^/%?#]*)(.*)$")
  local userinfo, host = authority:match("^(.*)@(.*)$")
  local username = userinfo and userinfo:match("^([^:]*):")
  if not username then
    return raw_url
  end

  return raw_url:sub(1, scheme_end) .. username .. ":****@" .. host .. suffix
end

function M.confirm_action(message, detail, should_confirm, opts)
  if should_confirm == false then
    return true
  end
  if should_confirm == nil then
    should_confirm = defaults().confirm_open
  end
  if not should_confirm then
    return true
  end

  local title = tostring(message or "")
  if title == "" then
    title = "Confirm"
  end

  local detail_lines = {}
  if type(detail) == "string" then
    detail_lines = vim.split(detail, "\n", { plain = true, trimempty = true })
  elseif type(detail) == "table" then
    for _, line in ipairs(detail) do
      if type(line) == "string" and vim.trim(line) ~= "" then
        detail_lines[#detail_lines + 1] = line
      end
    end
  end

  local summary = {}
  if #detail_lines > 0 then
    for _, line in ipairs(detail_lines) do
      local normalized = M.truncate_for_display(vim.trim(line))
      if normalized ~= "" then
        summary[#summary + 1] = normalized
      end
    end
  end

  local options = {
    confirm_label = opts and opts.confirm_label or "&Proceed",
    cancel_label = opts and opts.cancel_label or "&Cancel",
    default = opts and opts.default or 1,
  }

  local function strip_hotkey(label)
    if type(label) ~= "string" then
      return ""
    end
    return label:gsub("&", "")
  end

  local confirm_label = strip_hotkey(options.confirm_label)
  local cancel_label = strip_hotkey(options.cancel_label)
  if confirm_label == "" then
    confirm_label = "Proceed"
  end
  if cancel_label == "" then
    cancel_label = "Cancel"
  end

  local prompt_lines = { title }
  if #summary > 0 then
    for _, line in ipairs(summary) do
      prompt_lines[#prompt_lines + 1] = "  " .. line
    end
  end

  local default_is_yes = options.default == 1
  local default_hint = default_is_yes and "[Y/n]" or "[y/N]"
  prompt_lines[#prompt_lines + 1] = string.format("%s / %s %s:", confirm_label, cancel_label, default_hint)

  local prompt = table.concat(prompt_lines, "\n")
  while true do
    local answer = vim.fn.input({ prompt = prompt .. " " })
    if answer == nil then
      return false
    end
    answer = vim.trim(answer):lower()
    if answer == "" then
      return default_is_yes
    end
    if answer == "y" or answer == "yes" then
      return true
    end
    if answer == "n" or answer == "no" then
      return false
    end
    show_warn_fn("Please type y or n.")
  end
end

return M
