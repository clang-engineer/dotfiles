local M = {}

local config = require("user.vim-dadbod-connection-picker.config")
local controller = require("user.vim-dadbod-connection-picker.controller")
local group_actions = require("user.vim-dadbod-connection-picker.groups.actions")
local group_data = require("user.vim-dadbod-connection-picker.groups.store")
local group_delete = require("user.vim-dadbod-connection-picker.groups.delete")
local items = require("user.vim-dadbod-connection-picker.picker.items")
local query = require("user.vim-dadbod-connection-picker.query")
local ui = require("user.vim-dadbod-connection-picker.ui")
local util = require("user.vim-dadbod-connection-picker.util")

local layout = {
  preset = "dropdown",
  win = {
    list = { border = "none" },
    input = { border = "none" },
    preview = { border = "none" },
  },
}

local function snacks_picker()
  local ok, snacks = pcall(require, "snacks.picker")
  if not ok then
    return nil
  end
  if type(snacks) == "function" then
    return snacks
  end
  if type(snacks) == "table" and type(snacks.pick) == "function" then
    return snacks.pick
  end
  if type(snacks) == "table" and type(snacks.picker) == "table" and type(snacks.picker.pick) == "function" then
    return snacks.picker.pick
  end
  return nil
end

local function picker_keys(handlers)
  local keys = {}
  for key, handler in pairs(handlers) do
    keys[key] = { handler, mode = { "n" } }
  end
  return keys
end

local function show_empty(pick, shortcuts)
  local function start(picker)
    if picker and type(picker.close) == "function" then
      picker:close()
    end
    group_actions.prompt_first_connection(function()
      controller.pick_group({})
    end)
  end
  local win = vim.tbl_deep_extend("force", layout.win, {
    list = { keys = { n = { start, mode = { "n" } } } },
    input = { keys = {} },
  })
  pick({
    title = "DB Connections (no groups)",
    finder = function()
      local rows = items.empty()
      ui.add_hint_rows(rows, shortcuts(), { mode = "append", first_prefix = "  ", rest_prefix = "  " })
      return rows
    end,
    format = "text",
    prompt = "> ",
    preview = "preview",
    focus = "list",
    layout = layout,
    win = win,
    confirm = start,
  })
end

local function run(groups, expanded, opts)
  local pick = snacks_picker()
  if not pick then
    controller.show_info("No group preview available")
    return
  end

  local detailed_shortcuts = false
  local function shortcuts()
    if opts.usage_hint ~= nil then
      return opts.usage_hint
    end
    return detailed_shortcuts and ui.picker_shortcuts_hint_full() or ui.picker_shortcuts_hint()
  end
  if #items.groups(groups, expanded) == 0 then
    show_empty(pick, shortcuts)
    return
  end

  local ordered_groups = util.sorted_keys(groups)
  local total_connections = 0
  for _, group in ipairs(ordered_groups) do
    total_connections = total_connections + #(groups[group] or {})
  end

  local picker_instance
  local function current_row()
    if not picker_instance or type(picker_instance.current) ~= "function" then
      if picker_instance then
        controller.show_warn("Current picker API does not expose current selection.")
      end
      return nil
    end
    return picker_instance:current()
  end
  local function current_group(require_group_row, action_label)
    local current = current_row()
    if not current or type(current.group) ~= "string" or current.group == "" then
      return nil
    end
    if require_group_row and current.kind ~= "group" then
      controller.show_warn("Move to a group row to " .. action_label .. ".")
      return nil
    end
    return current.group
  end
  local function move_up()
    local up = vim.api.nvim_replace_termcodes("<Up>", true, false, true)
    vim.schedule(function()
      if picker_instance then
        vim.api.nvim_feedkeys(up, "n", false)
      end
    end)
  end
  local function reload(reload_opts)
    groups = group_data.build_group_connections()
    if picker_instance and type(picker_instance.refresh) == "function" then
      picker_instance:refresh()
    end
    if reload_opts and reload_opts.move_up then
      move_up()
    end
  end

  local function add_group()
    local default_name = ""
    local current = current_row()
    if current and type(current.group) == "string" and current.group ~= "" and current.group ~= "all" then
      default_name = current.group
    elseif picker_instance and type(picker_instance.filter) == "function" then
      default_name = vim.trim(picker_instance:filter().pattern or "")
    end
    group_actions.prompt_new_group(default_name)
  end
  local function add_connection()
    local group = current_group(false)
    if group then
      group_actions.add_connection(group)
    elseif vim.tbl_isempty(group_data.build_group_connections()) then
      add_group()
    else
      controller.show_warn("Move to a group row to add a connection.")
    end
  end
  local function edit_group()
    local group = current_group(false)
    if group then
      picker_instance:close()
      group_actions.edit(group)
    end
  end
  local function rename_group()
    local group = current_group(true, "rename it")
    if group then
      group_actions.rename(group, reload)
    end
  end
  local function delete_item()
    local item = current_row()
    if item then
      group_delete.delete(item, reload)
    end
  end
  local function toggle_shortcuts()
    detailed_shortcuts = not detailed_shortcuts
    if picker_instance and type(picker_instance.refresh) == "function" then
      picker_instance:refresh()
    end
  end

  local handlers = {
    e = edit_group,
    a = add_connection,
    n = add_group,
    r = rename_group,
    d = delete_item,
    u = function()
      controller.restore_group(nil, { mode = "undo", on_success = reload })
    end,
    ["<C-r>"] = function()
      controller.restore_group(nil, { mode = "redo", on_success = reload })
    end,
    ["?"] = toggle_shortcuts,
  }
  local win = vim.tbl_deep_extend("force", layout.win, {
    list = { keys = picker_keys(handlers) },
    input = { keys = picker_keys(handlers) },
  })
  win.input.keys.u = nil
  win.input.keys["<C-r>"] = nil

  local match_set = items.match_set(groups)
  local last_pattern
  local query_pattern = ""
  local query_has_match = true
  local function on_change(picker)
    local pattern = picker:filter().pattern or ""
    query_pattern = query.normalize_filter_pattern(pattern)
    query_has_match = not vim.tbl_isempty(query.find_matches(match_set, pattern, util.sorted_keys(groups)))
    if pattern == last_pattern then
      return
    end
    if pattern == "" and (last_pattern == nil or last_pattern == "") then
      last_pattern = pattern
      return
    end
    local changed = false
    for _, group in ipairs(ordered_groups) do
      local should_expand = pattern ~= "" and query.has_token_match(match_set[group], pattern)
      if should_expand ~= expanded[group] then
        expanded[group] = should_expand
        changed = true
      end
    end
    if changed then
      picker:refresh()
    end
    last_pattern = pattern
  end

  local function confirm(picker, item)
    if not item or item.kind == "hint" then
      return
    end
    if item.kind == "group" then
      expanded[item.group] = not (expanded[item.group] == true)
      picker:refresh()
      return
    end
    if item.kind == "open_all" then
      local count = #(groups[item.group] or {})
      local confirm_group = config.get().confirm_open_group
      if
        confirm_group
        and not ui.confirm_action(
          string.format("Open all %d connections in %s?", count, item.group),
          string.format("Group: %s\nConnections: %d", item.group, count),
          confirm_group
        )
      then
        return
      end
      picker:close()
      controller.open(item.group, nil, { prefix = opts.prefix })
    elseif item.kind == "connection" then
      picker:close()
      controller.open_connection(item.group, item.connection)
    end
  end

  picker_instance = pick({
    title = string.format(
      "DB Connections (%d group%s, %d connection%s)",
      #ordered_groups,
      #ordered_groups == 1 and "" or "s",
      total_connections,
      total_connections == 1 and "" or "s"
    ),
    finder = function()
      local rows = items.groups(groups, expanded)
      if query_pattern ~= "" and not query_has_match then
        ui.add_hint_rows(rows, {
          "No match for " .. string.format("%q", query_pattern) .. ".",
          "Tip: / filter",
          "Press <CR> to open.",
        }, { mode = "prepend", first_prefix = "> ", rest_prefix = "  " })
      end
      ui.add_hint_rows(rows, shortcuts(), { mode = "prepend", first_prefix = "> ", rest_prefix = "  " })
      return rows
    end,
    format = "text",
    prompt = "> ",
    preview = "preview",
    focus = "list",
    layout = layout,
    win = win,
    confirm = confirm,
    on_change = on_change,
  })
end

function M.pick_group(opts)
  local groups = group_data.build_group_connections()
  local expanded = {}
  for _, group in ipairs(util.sorted_keys(groups)) do
    expanded[group] = false
  end
  run(groups, expanded, { prefix = false, usage_hint = opts and opts.usage_hint or nil })
end

return M
