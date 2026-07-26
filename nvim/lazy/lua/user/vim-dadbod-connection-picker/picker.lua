local M = {}

local controller = require("user.vim-dadbod-connection-picker.controller")
local group_data = require("user.vim-dadbod-connection-picker.group_data")
local query = require("user.vim-dadbod-connection-picker.query")
local ui = require("user.vim-dadbod-connection-picker.ui")
local util = require("user.vim-dadbod-connection-picker.util")

local picker_layout = {
  preset = "dropdown",
  win = {
    list = { border = "none" },
    input = { border = "none" },
    preview = { border = "none" },
  },
}

local function display_url(url)
  return ui.truncate_for_display(ui.mask_url(url))
end

local function build_group_preview(group, connections)
  local count = #(connections or {})
  local lines = {
    string.format("Group: %s", group),
    string.format("Total connections: %d", count),
    "",
  }
  if count == 0 then
    lines[#lines + 1] = "No connections configured."
    return table.concat(lines, "\n")
  end
  for index, conn in ipairs(connections or {}) do
    lines[#lines + 1] = string.format("%d) %s", index, conn.name)
    lines[#lines + 1] = string.format("   %s", display_url(conn.url))
  end
  return table.concat(lines, "\n")
end

local function build_connection_preview(group, conn, extra)
  local lines = {
    string.format("Group: %s", group),
    string.format("Connection: %s", conn.name),
    string.format("URL: %s", ui.mask_url(conn.url)),
  }
  if extra then
    lines[#lines + 1] = extra
  end
  return table.concat(lines, "\n")
end

local function build_group_items(groups, expanded)
  local items = {}
  local icons = controller.get_group_icons()
  for _, group in ipairs(util.sorted_keys(groups)) do
    local is_expanded = expanded[group] == true
    local glyph = is_expanded and icons.folder_expanded or icons.folder_collapsed
    local count = #(groups[group] or {})
    items[#items + 1] = {
      text = string.format("%s %s (%d)", glyph, group, count),
      kind = "group",
      group = group,
      expanded = is_expanded,
      preview = { text = build_group_preview(group, groups[group]) },
    }

    if is_expanded then
      if count > 1 then
        items[#items + 1] = {
          text = string.format("  %s Open all (%d): %s", icons.open_all, count, group),
          kind = "open_all",
          group = group,
          preview = { text = string.format("Group: %s\nOpen all %d connections at once.", group, count) },
        }
      end
      if count == 0 then
        items[#items + 1] = {
          text = "  (no connections)",
          kind = "empty_connection",
          group = group,
          preview = {
            text = string.format(
              "Group: %s\nNo connections configured.\nTip: use :%s edit %s",
              group,
              controller.get_command_name(),
              group
            ),
          },
        }
      end
      for index, conn in ipairs(groups[group] or {}) do
        items[#items + 1] = {
          text = string.format("    %s (%s)", conn.name, display_url(conn.url)),
          kind = "connection",
          group = group,
          connection = conn,
          connection_index = index,
          preview = { text = build_connection_preview(group, conn) },
        }
      end
    end
  end
  return items
end

local function build_group_match_set(groups)
  local set = {}
  for _, group in ipairs(util.sorted_keys(groups)) do
    local values = { group }
    for _, conn in ipairs(groups[group] or {}) do
      if conn.name then
        values[#values + 1] = conn.name
      end
      if conn.url then
        values[#values + 1] = conn.url
      end
    end
    set[group] = values
  end
  return set
end

local function resolve_snacks_picker()
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

local function show_empty_picker(picker_api, layout, shortcuts_hint)
  local defaults = controller.get_defaults()
  local groups_dir = group_data.connections_dir()
  local function start_setup(picker)
    if picker and type(picker.close) == "function" then
      picker:close()
    end
    controller.prompt_first_connection()
  end
  local win = vim.tbl_deep_extend("force", layout.win or {}, {
    list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), {
        ["n"] = { start_setup, mode = { "n" } },
      }),
    }),
    input = vim.tbl_deep_extend("force", (layout.win and layout.win.input) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.input and layout.win.input.keys) or {}), {}),
    }),
  })

  picker_api({
    title = "DB Connections (no groups)",
    finder = function()
      local placeholder = type(defaults.group_placeholders) == "table" and defaults.group_placeholders[1] or nil
      local sample_name = type(placeholder) == "table" and placeholder.name or "sample"
      if type(sample_name) ~= "string" or sample_name == "" then
        sample_name = "sample"
      end
      local safe_sample_name = group_data.normalize_group_name(sample_name) or "sample"
      local sample_url = type(placeholder) == "table" and placeholder.url or "postgresql://..."
      if type(sample_url) ~= "string" or sample_url == "" then
        sample_url = "postgresql://..."
      end
      local rows = {
        {
          text = "+ Add first connection",
          kind = "setup",
          preview = { text = "No DB connections found.\nPress <CR> to enter a group name, connection name, and URL." },
        },
        {
          text = "Example: " .. groups_dir .. "/" .. safe_sample_name .. ".lua",
          kind = "hint",
          preview = {
            text = groups_dir
              .. "/"
              .. safe_sample_name
              .. ".lua\nreturn { { name = "
              .. vim.inspect(vim.trim(sample_name))
              .. ", url = "
              .. vim.inspect(ui.mask_url(sample_url))
              .. " } }",
          },
        },
      }
      ui.add_hint_rows(rows, shortcuts_hint(), { mode = "append", first_prefix = "  ", rest_prefix = "  " })
      return rows
    end,
    format = "text",
    prompt = "> ",
    preview = "preview",
    focus = "list",
    layout = layout,
    win = win,
    confirm = start_setup,
  })
end

local function picker_keys(handlers)
  local keys = {}
  for key, handler in pairs(handlers) do
    keys[key] = { handler, mode = { "n" } }
  end
  return keys
end

local function run_group_picker(groups, expanded, opts)
  local layout = opts.layout or picker_layout
  local show_detailed_shortcuts = false
  local function shortcuts_hint()
    if opts.usage_hint ~= nil then
      return opts.usage_hint
    end
    return show_detailed_shortcuts and ui.picker_shortcuts_hint_full() or ui.picker_shortcuts_hint()
  end

  local picker_api = resolve_snacks_picker()
  if not picker_api then
    controller.show_info("No group preview available")
    return
  end
  if #build_group_items(groups, expanded) == 0 then
    show_empty_picker(picker_api, layout, shortcuts_hint)
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
    controller.prompt_new_group_name(default_name)
  end

  local function add_connection()
    local group = current_group(false)
    if not group then
      if vim.tbl_isempty(group_data.build_group_connections()) then
        add_group()
      else
        controller.show_warn("Move to a group row to add a connection.")
      end
      return
    end
    controller.add_connection(group)
  end

  local function edit_group()
    local group = current_group(false)
    if group then
      picker_instance:close()
      controller.edit_group(group)
    end
  end

  local function rename_group()
    local group = current_group(true, "rename it")
    if group then
      controller.rename_group(group, reload)
    end
  end

  local function delete_item()
    local item = current_row()
    if item then
      controller.delete_item(item, reload)
    end
  end

  local function undo()
    controller.restore_group(nil, { mode = "undo", on_success = reload })
  end

  local function redo()
    controller.restore_group(nil, { mode = "redo", on_success = reload })
  end

  local function toggle_shortcuts()
    show_detailed_shortcuts = not show_detailed_shortcuts
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
    u = undo,
    ["<C-r>"] = redo,
    ["?"] = toggle_shortcuts,
  }
  local custom_win = vim.tbl_deep_extend("force", layout.win or {}, {
    list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), picker_keys(handlers)),
    }),
    input = vim.tbl_deep_extend("force", (layout.win and layout.win.input) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.input and layout.win.input.keys) or {}), picker_keys(handlers)),
    }),
  })
  custom_win.input.keys.u = nil
  custom_win.input.keys["<C-r>"] = nil

  local matches_cache = build_group_match_set(groups)
  local last_pattern
  local query_pattern = ""
  local query_has_match = true
  local function on_change(picker)
    local pattern = picker:filter().pattern or ""
    query_pattern = query.normalize_filter_pattern(pattern)
    query_has_match = not vim.tbl_isempty(query.find_matches(matches_cache, pattern, util.sorted_keys(groups)))
    if pattern == last_pattern then
      return
    end

    local changed = false
    if pattern == "" then
      if last_pattern == nil or last_pattern == "" then
        last_pattern = pattern
        return
      end
      for _, group in ipairs(ordered_groups) do
        if expanded[group] then
          expanded[group] = false
          changed = true
        end
      end
    else
      for _, group in ipairs(ordered_groups) do
        local should_expand = query.has_token_match(matches_cache[group], pattern)
        if should_expand ~= expanded[group] then
          expanded[group] = should_expand
          changed = true
        end
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
      local defaults = controller.get_defaults()
      if defaults.confirm_open_group then
        local confirmed = ui.confirm_action(
          string.format("Open all %d connections in %s?", count, item.group),
          string.format("Group: %s\nConnections: %d", item.group, count),
          defaults.confirm_open_group
        )
        if not confirmed then
          return
        end
      end
      picker:close()
      controller.open(item.group, nil, { prefix = opts.prefix })
      return
    end
    if item.kind == "connection" then
      picker:close()
      controller.open_connection(item.group, item.connection)
    end
  end

  picker_instance = picker_api({
    title = string.format(
      "DB Connections (%d group%s, %d connection%s)",
      #ordered_groups,
      #ordered_groups == 1 and "" or "s",
      total_connections,
      total_connections == 1 and "" or "s"
    ),
    finder = function()
      local rows = build_group_items(groups, expanded)
      if query_pattern ~= "" and not query_has_match then
        ui.add_hint_rows(rows, {
          "No match for " .. string.format("%q", query_pattern) .. ".",
          "Tip: / filter",
          "Press <CR> to open.",
        }, { mode = "prepend", first_prefix = "> ", rest_prefix = "  " })
      end
      ui.add_hint_rows(rows, shortcuts_hint(), { mode = "prepend", first_prefix = "> ", rest_prefix = "  " })
      return rows
    end,
    format = "text",
    prompt = "> ",
    preview = "preview",
    focus = "list",
    layout = layout,
    win = custom_win,
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
  run_group_picker(groups, expanded, {
    layout = picker_layout,
    prefix = false,
    usage_hint = opts and opts.usage_hint or nil,
  })
end

return M
