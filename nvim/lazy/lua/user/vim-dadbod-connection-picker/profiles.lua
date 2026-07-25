local M = {}

local group_data = require("user.vim-dadbod-connection-picker.group_data")

local picker_layout = {
  preset = "dropdown",
  win = {
    list = {
      border = "none",
    },
    input = {
      border = "none",
    },
    preview = {
      border = "none",
    },
  },
}

local defaults = {
  group_labels = {},
  group_placeholders = {
    { name = "example", url = "postgresql://localhost:5432/db" },
  },
  icon_style = "ascii",
  confirm_open = false,
  confirm_open_group = false,
  icons = {},
}

local icon_styles = {
  ascii = {
    folder_expanded = "[-]",
    folder_collapsed = "[+]",
    open_group = ">",
    open_all = ">>",
  },
  emoji = {
    folder_expanded = "📂",
    folder_collapsed = "📁",
    open_group = "📂",
    open_all = "🚀",
  },
  nerd = {
    folder_expanded = "",
    folder_collapsed = "",
    open_group = "",
    open_all = "+",
  },
}

local group_icons = {}
local group_label_map = {}

local function sorted_keys(values)
  local keys = {}
  for key in pairs(values) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

local function has_value(values, needle)
  for _, value in ipairs(values) do
    if value == needle then
      return true
    end
  end
  return false
end

local function show_info(message)
  vim.notify(message, vim.log.levels.INFO)
end

local function show_warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

local function show_error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function normalize_icons(options)
  local style_name = options.icon_style or "ascii"
  local style = icon_styles[style_name] or icon_styles.ascii
  local merged = vim.tbl_extend("force", style, options.icons or {})
  return {
    folder_expanded = merged.folder_expanded or style.folder_expanded,
    folder_collapsed = merged.folder_collapsed or style.folder_collapsed,
    open_group = merged.open_group or style.open_group,
    open_all = merged.open_all or merged.open_group or style.open_group,
  }
end

local function picker_shortcuts_hint()
  return "Shortcuts: / filter, <CR> open, a add connection, n add group, e edit"
end

local function truncate_for_display(value)
  local max_len = 72
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len - 3) .. "..."
end

local function confirm_open(message)
  if not defaults.confirm_open then
    return true
  end
  local choice = vim.fn.confirm(message, "&Open\n&Cancel", 1, "Question")
  return choice == 1
end

local function resolve_group_label(group)
  if type(group) ~= "string" or group == "" then
    return group
  end

  local mapped = group_label_map[group]
  if type(mapped) == "string" and mapped ~= "" then
    return mapped
  end
  return group
end

local function next_placeholder(values)
  local source = defaults.group_placeholders
  if type(source) ~= "table" or #source == 0 then
    return {
      name = "example",
      url = "postgresql://localhost:5432/db",
    }
  end

  local raw = source[1]
  return {
    name = raw.name or "example",
    url = raw.url or "postgresql://localhost:5432/db",
  }
end

local function fill_connection_with_prompt(on_done)
  local next_conn = next_placeholder()
  vim.ui.input({
    prompt = "Connection name: ",
    default = next_conn.name,
  }, function(name)
    if name == nil then
      return
    end
    if name == "" then
      name = next_conn.name
    end

    vim.ui.input({
      prompt = "Connection URL: ",
      default = next_conn.url,
    }, function(url)
      if url == nil then
        return
      end
      if url == "" then
        url = next_conn.url
      end
      on_done({
        name = name,
        url = url,
      })
    end)
  end)
end

local function prompt_new_group_name(opts)
  opts = opts or {}
  local default_name = opts.default_name or ""

  vim.ui.input({
    prompt = "New group name: ",
    default = default_name,
  }, function(raw_name)
    if raw_name == nil then
      return
    end
    local normalized = group_data.normalize_group_name(raw_name)
    if not normalized or normalized == "" then
      show_warn("Invalid group name.")
      return
    end

    M.create_group(normalized)
  end)
end

local function open_group_file_for_edit(path)
  vim.schedule(function()
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local line_count = #lines
    local cursor_line = line_count > 1 and (line_count - 1) or line_count
    if cursor_line < 1 then
      cursor_line = 1
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { cursor_line, 0 })
    show_info("Edit newly added connection on the current line if needed.")
  end)
end

local function apply_group_prefix(group, conn)
  if type(conn) ~= "table" then
    return conn
  end

  if type(conn.name) ~= "string" or conn.url == nil then
    return conn
  end

  if conn.name == "" or conn.name:match("^%[[^%]]+%] ") then
    return conn
  end

  local label = resolve_group_label(group)
  if type(label) ~= "string" or label == "" then
    return conn
  end

  return vim.tbl_extend("force", conn, {
    name = string.format("[%s] %s", label, conn.name),
  })
end

function M.connections(target, opts)
  local groups = group_data.build_group_connections()
  local result = {}
  local force_prefix = opts and opts.prefix

  local function with_prefix(group, conn)
    if not force_prefix then
      return conn
    end
    return apply_group_prefix(group, conn)
  end

  local selected_group = target
  if selected_group and selected_group ~= "all" then
    selected_group = group_data.normalize_group_name(selected_group)
    if not selected_group then
      return nil
    end

    local selected = groups[selected_group]
    if type(selected) ~= "table" then
      return nil
    end

    for _, conn in ipairs(selected) do
      table.insert(result, with_prefix(selected_group, conn))
    end
    return result
  end

  for _, name in ipairs(sorted_keys(groups)) do
    for _, conn in ipairs(groups[name] or {}) do
      table.insert(result, with_prefix(name, conn))
    end
  end

  return result
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

  for idx, conn in ipairs(connections or {}) do
    lines[#lines + 1] = string.format("%d) %s", idx, conn.name)
    lines[#lines + 1] = string.format("   %s", truncate_for_display(conn.url))
  end

  return table.concat(lines, "\n")
end

local function build_connection_preview(group, conn, extra)
  local lines = {
    string.format("Group: %s", group),
    string.format("Connection: %s", conn.name),
    string.format("URL: %s", conn.url),
  }
  if extra then
    lines[#lines + 1] = extra
  end
  return table.concat(lines, "\n")
end

local function build_group_items(groups, expanded)
  local items = {}
  local ordered = sorted_keys(groups)

  for _, group in ipairs(ordered) do
    local is_expanded = expanded[group] == true
    local glyph = is_expanded and group_icons.folder_expanded or group_icons.folder_collapsed
    local count = #(groups[group] or {})

    table.insert(items, {
      text = string.format("%s %s (%d)", glyph, group, count),
      kind = "group",
      group = group,
      expanded = is_expanded,
      preview = {
        text = build_group_preview(group, groups[group]),
      },
    })

    if is_expanded then
      if #(groups[group] or {}) > 1 then
        table.insert(items, {
          text = string.format("  %s Open all (%d): %s", group_icons.open_all, #(groups[group] or {}), group),
          kind = "open_all",
          group = group,
          preview = {
            text = string.format("Group: %s\nOpen all %d connections at once.", group, #(groups[group] or {})),
          },
        })
      end

      if #(groups[group] or {}) == 0 then
        table.insert(items, {
          text = "  (no connections)",
          kind = "empty_connection",
          group = group,
          preview = {
            text = string.format("Group: %s\nNo connections configured.\nTip: use :DBConnections edit %s", group, group),
          },
        })
      end

      for _, conn in ipairs(groups[group] or {}) do
        local detail = string.format("    %s (%s)", conn.name, truncate_for_display(conn.url))
        table.insert(items, {
          text = detail,
          kind = "connection",
          group = group,
          connection = conn,
          preview = {
            text = build_connection_preview(group, conn),
          },
        })
      end
    end
  end

  return items
end

local function build_group_match_set(groups)
  local set = {}
  for _, group in ipairs(sorted_keys(groups)) do
    local haystack = {
      group,
    }
    for _, conn in ipairs(groups[group] or {}) do
      if conn.name then
        haystack[#haystack + 1] = conn.name
      end
      if conn.url then
        haystack[#haystack + 1] = conn.url
      end
    end
    set[group] = haystack
  end
  return set
end

local function build_manage_items(group_meta)
  local items = {}
  local ordered = sorted_keys(group_meta)

  for _, group in ipairs(ordered) do
    local data = group_meta[group]
    local count = #(data.connections or {})

    table.insert(items, {
      text = string.format("[%s] (%d)", group, count),
      kind = "group_manage",
      group = group,
      path = data.path,
      preview = {
        text = build_group_preview(group, data.connections),
      },
    })

    for index, conn in ipairs(data.connections or {}) do
      table.insert(items, {
        text = string.format("  %s (%s)", conn.name, truncate_for_display(conn.url)),
        kind = "connection_manage",
        group = group,
        path = data.path,
        connection = conn,
        connection_index = index,
        preview = {
          text = build_connection_preview(group, conn, "Path: " .. data.path),
        },
      })
    end
  end

  return items
end

local function open_connection(group, conn)
  if type(conn) ~= "table" or type(conn.url) ~= "string" then
    return false
  end

  local name = conn.name and conn.name ~= "" and conn.name or group
  if not confirm_open(string.format("Open connection: %s", name)) then
    return false
  end
  return M.open({ { name = conn.name, url = conn.url } }, name)
end

local function resolve_snacks_picker()
  local ok_snacks, snacks = pcall(require, "snacks.picker")
  if not ok_snacks then
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

local function run_picker(groups, expanded, opts)
  local layout = opts and opts.layout or picker_layout
  local usage_hint = type(opts) == "table" and opts.usage_hint or nil

  local function items()
    return build_group_items(groups, expanded)
  end
  local ordered_groups = sorted_keys(groups)
  local total_groups = #ordered_groups
  local total_connections = 0
  for _, group in ipairs(ordered_groups) do
    total_connections = total_connections + #(groups[group] or {})
  end

  local picker_api = resolve_snacks_picker()
  if not picker_api then
    if opts and opts.fallback and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    show_warn("snacks.picker is not available. Please install folke/snacks.nvim.")
    return
  end

  if #items() == 0 then
    local groups_dir = group_data.connections_dir()
    local no_group_win = vim.tbl_deep_extend("force", layout.win or {}, {
      list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
        keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), {
          ["n"] = {
            function()
              prompt_new_group_name({ default_name = "office" })
            end,
            mode = { "n" },
          },
        }),
      }),
      input = vim.tbl_deep_extend("force", (layout.win and layout.win.input) or {}, {
        keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.input and layout.win.input.keys) or {}), {
        }),
      }),
    })
    picker_api({
      title = "DB Connections (no groups)",
      finder = function()
        return {
          {
            text = "No DB groups found.",
            kind = "hint",
            preview = {
              text = "No DB groups found.\nPress n to add a new group.",
            },
          },
          {
            text = "Shortcut: " .. picker_shortcuts_hint(),
            kind = "hint",
            preview = {
              text = "Use the commands too: :DBConnections add <group>",
            },
          },
          {
            text = "Example: " .. groups_dir .. "/office.lua",
            kind = "hint",
            preview = {
              text = groups_dir .. "/office.lua\nreturn { { name = \"office\", url = \"postgresql://...\" } }",
            },
          },
        }
      end,
      format = "text",
      prompt = "> ",
      preview = "preview",
      focus = "list",
      layout = layout,
      win = no_group_win,
      confirm = function()
        return
      end,
    })
    return
  end

  local picker_instance = nil

  local function handle_select(picker, item)
    if not item then
      return
    end

    if item.kind == "hint" then
      return
    end

    if item.kind == "group" then
      expanded[item.group] = not (expanded[item.group] == true)
      picker:refresh()
      return
    end

  if item.kind == "open_all" then
    if defaults.confirm_open_group then
      local ok = confirm_open(string.format("Open all %d connections in %s", #(groups[item.group] or {}), item.group))
      if not ok then
        return
      end
    end
    picker:close()
    M.open(item.group, nil, { prefix = opts and opts.prefix })
      return
    end

    if item.kind == "connection" then
      picker:close()
      open_connection(item.group, item.connection)
      return
    end
  end

  local function handle_edit_current_group()
    if not picker_instance then
      return
    end
    if type(picker_instance.current) ~= "function" then
      show_warn("Current picker API does not expose current selection.")
      return
    end

    local current = picker_instance:current()
    if not current then
      return
    end

    local group = current.group
    if type(group) ~= "string" or group == "" then
      return
    end

    picker_instance:close()
    M.edit_group(group)
  end

  local function handle_add_connection_to_current_group()
    if not picker_instance then
      return
    end
    if type(picker_instance.current) ~= "function" then
      show_warn("Current picker API does not expose current selection.")
      return
    end

    local current = picker_instance:current()
    if not current then
      return
    end

    local group = current.group
    if type(group) ~= "string" or group == "" then
      return
    end

    local connections, path = group_data.load_group_connections(group)
    if not path then
      show_warn("No group file found: " .. group)
      return
    end

    local existing = connections or {}
    if type(existing) ~= "table" then
      existing = {}
    end

    fill_connection_with_prompt(function(conn)
      table.insert(existing, conn)
      group_data.write_group_file(path, existing)
      show_info("Added connection to group: " .. group)
      open_group_file_for_edit(path)
    end)
  end

  local function handle_add_group_from_picker()
    if not picker_instance then
      return
    end

    local default_name = ""
    if type(picker_instance.current) == "function" then
      local current = picker_instance:current()
      if current and type(current.group) == "string" and current.group ~= "" and current.group ~= "all" then
        default_name = current.group
      end
    end

    if default_name == "" and type(picker_instance.filter) == "function" then
      local filtered = vim.trim(picker_instance:filter().pattern or "")
      if filtered ~= "" then
        default_name = filtered
      end
    end

    prompt_new_group_name({
      default_name = default_name,
    })
  end

  local custom_win = vim.tbl_deep_extend("force", layout.win or {}, {
    list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), {
        ["e"] = {
          function()
            handle_edit_current_group()
          end,
          mode = { "n" },
        },
        ["a"] = {
          function()
            handle_add_connection_to_current_group()
          end,
          mode = { "n" },
        },
        ["n"] = {
          function()
            handle_add_group_from_picker()
          end,
          mode = { "n" },
        },
      }),
    }),
    input = vim.tbl_deep_extend("force", (layout.win and layout.win.input) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.input and layout.win.input.keys) or {}), {
        ["e"] = {
          function()
            handle_edit_current_group()
          end,
          mode = { "n", "i" },
        },
        ["a"] = {
          function()
            handle_add_connection_to_current_group()
          end,
          mode = { "n", "i" },
        },
        ["n"] = {
          function()
            handle_add_group_from_picker()
          end,
          mode = { "n" },
        },
      }),
    }),
  })

  local matches_cache = build_group_match_set(groups)
  local last_pattern = nil
  local query_pattern = ""
  local query_has_match = true

  local function has_query_match(pattern)
    local normalized = vim.trim(pattern or "")
    if normalized == "" then
      return true
    end
    normalized = string.lower(normalized)
    for _, group in ipairs(sorted_keys(groups)) do
      local haystack = matches_cache[group]
      if haystack then
        for _, target in ipairs(haystack) do
          if string.find(string.lower(target), normalized, 1, true) then
            return true
          end
        end
      end
    end
    return false
  end

  local function pattern_matches_group(group, pattern)
    local haystack = matches_cache[group]
    if not haystack or #haystack == 0 then
      return false
    end

    local lower = string.lower(pattern)
    for _, target in ipairs(haystack) do
      if string.find(string.lower(target), lower, 1, true) then
        return true
      end
    end

    return false
  end

  local function auto_expand_on_query(picker)
    local pattern = picker:filter().pattern or ""
    pattern = vim.trim(pattern)
    query_pattern = pattern
    query_has_match = has_query_match(pattern)
    if pattern == last_pattern then
      return
    end

    local changed = false
    local ordered = ordered_groups

    if pattern == "" then
      if last_pattern == nil or last_pattern == "" then
        last_pattern = pattern
        return
      end

      for _, group in ipairs(ordered) do
        if expanded[group] then
          expanded[group] = false
          changed = true
        end
      end
      if changed then
        picker:refresh()
      end
      last_pattern = pattern
      return
    end

    for _, group in ipairs(ordered) do
      local should_expand = pattern_matches_group(group, pattern)
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

  picker_instance = picker_api({
    title = string.format(
      "DB Connections (%d group%s, %d connection%s)",
      total_groups,
      total_groups == 1 and "" or "s",
      total_connections,
      total_connections == 1 and "" or "s"
    ),
    finder = function()
      local rows = items()
      if query_pattern ~= "" and not query_has_match then
        table.insert(rows, 1, {
          text = "No match for " .. string.format("%q", query_pattern) .. ". Tip: " .. picker_shortcuts_hint() .. ".",
          kind = "hint",
          preview = {
            text = "No match found. Type a different keyword, then press <CR> / open filtered group, or use n to add a group.",
          },
        })
      end
      if usage_hint then
        table.insert(rows, 1, {
          text = "> " .. usage_hint,
          kind = "hint",
          preview = {
            text = usage_hint,
          },
        })
      end
      return rows
    end,
    format = "text",
    prompt = "> ",
    preview = "preview",
    focus = "list",
    layout = layout,
    win = custom_win,
    confirm = handle_select,
    on_change = auto_expand_on_query,
  })
end

local function run_manage_picker(group_meta, opts)
  local function items()
    return build_manage_items(group_meta)
  end

  if #items() == 0 then
    show_warn("No DB groups found")
    return
  end

  local picker_api = resolve_snacks_picker()
  if not picker_api then
    if opts and opts.fallback and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    show_warn("snacks.picker is not available. Please install folke/snacks.nvim.")
    return
  end

  local function open_group_file(path)
    if not path then
      return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end

  local function handle_manage_select(picker, item)
    if not item then
      return
    end

    if item.kind == "connection_manage" then
      picker:close()
      open_connection(item.group, item.connection)
      return
    end

    if item.path then
      picker:close()
      open_group_file(item.path)
    end
  end

  local ordered_groups = sorted_keys(group_meta)
  local query_pattern = ""
  local query_has_match = true
  local query_set = {}
  for _, group in ipairs(ordered_groups) do
    local payload = {
      group,
    }
    local data = group_meta[group]
    if data then
      for _, conn in ipairs(data.connections or {}) do
        if conn.name ~= nil then
          payload[#payload + 1] = conn.name
        end
        if conn.url ~= nil then
          payload[#payload + 1] = conn.url
        end
      end
    end
    query_set[group] = payload
  end

  local function has_query_match(pattern)
    local normalized = vim.trim(pattern or "")
    if normalized == "" then
      return true
    end
    normalized = string.lower(normalized)
    for _, tokens in pairs(query_set) do
      for _, token in ipairs(tokens) do
        if string.find(string.lower(tostring(token)), normalized, 1, true) then
          return true
        end
      end
    end
    return false
  end

  local function auto_expand_manage_on_query(picker)
    local pattern = picker:filter().pattern or ""
    query_pattern = vim.trim(pattern)
    query_has_match = has_query_match(query_pattern)
  end

  picker_api({
    title = "DB Connections Manager",
    finder = function()
      local rows = items()
      if query_pattern ~= "" and not query_has_match then
        table.insert(rows, 1, {
          text = "No match for " .. string.format("%q", query_pattern) .. ". Tip: " .. picker_shortcuts_hint() .. ".",
          kind = "hint",
          preview = {
            text = "No match found. Use <CR> on a connection to open it, or n to add a new group.",
          },
        })
      end
      return rows
    end,
    format = "text",
    prompt = "> ",
    focus = "list",
    preview = "preview",
    layout = opts and opts.layout or picker_layout,
    confirm = handle_manage_select,
    on_change = auto_expand_manage_on_query,
  })
end

local function close_dbui()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == "dbui" then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end

  if vim.fn.exists(":DBUIClose") == 2 then
    pcall(vim.cmd, "silent! DBUIClose")
  end
end

local function reset_dbui_state()
  if vim.fn.exists("*db_ui#reset_state") == 1 then
    pcall(vim.fn["db_ui#reset_state"])
  end
end

local function group_candidates()
  local groups = sorted_keys(group_data.build_group_connections())
  if not has_value(groups, "all") then
    table.insert(groups, "all")
  end
  return groups
end

function M.edit_profile(profile)
  M.edit_group(profile)
end

function M.pick_profile(opts)
  local groups = group_data.build_group_connections()
  local expanded = {}
  for _, group in ipairs(sorted_keys(groups)) do
    expanded[group] = false
  end

  run_picker(groups, expanded, {
    layout = picker_layout,
    prefix = false,
    usage_hint = opts and opts.usage_hint or nil,
    fallback = function()
      show_info("No group preview available")
    end,
  })
end

function M.pick_group()
  M.pick_profile()
end

function M.manage_profiles()
  local group_meta = group_data.build_group_metadata()
  run_manage_picker(group_meta, {
    layout = picker_layout,
    fallback = function()
      show_warn("Unable to open connection manager with snacks picker")
    end,
  })
end

function M.open(group, label_override, opts)
  local list
  local label
  local connection_opts = {
    prefix = opts and opts.prefix,
  }

  if type(group) == "table" then
    list = group
    label = label_override or "selected"
  else
    list = M.connections(group, connection_opts)
    if not list then
      show_warn("No connections found for group: " .. tostring(group))
      return
    end
    label = group == "all" and "all" or (group or "all")
  end

  if not list or vim.tbl_isempty(list) then
    show_warn("No DB connections found to open")
    return
  end

  M.current_profile = label

  if vim.fn.exists(":DBUI") ~= 2 then
    show_warn("vim-dadbod-ui is not available. Run :Lazy load vim-dadbod-ui first.")
    return
  end

  vim.g.dbs = list
  vim.schedule(function()
    close_dbui()
    reset_dbui_state()
    vim.cmd("DBUI")
  end)
end

function M.edit_group(group)
  local _, path = group_data.load_group_connections(group)
  if not path then
    show_warn("No group file found: " .. tostring(group))
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.editor(group)
  if not group then
    show_warn("Specify group name: :DBConnections edit <group>")
    return
  end
  M.edit_group(group)
end

function M.create_group(group)
  local normalized = group_data.normalize_group_name(group)
  if not normalized then
    show_warn("Invalid group name: " .. tostring(group))
    return
  end

  if normalized == "all" then
    show_warn("Group name cannot be `all`.")
    return
  end

  local path = group_data.group_file(normalized)
  if not path then
    show_warn("Unable to resolve group file path.")
    return
  end

  if group_data.group_file_exists(normalized) then
    show_warn("Group already exists: " .. normalized .. " (opening existing file)")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    return
  end

  group_data.write_group_file(path, defaults.group_placeholders)
  show_info("Created group file: " .. path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.open_connection_group(group)
  M.open(group)
end

function M.open_profile(name)
  M.open(name)
end

function M.setup(opts)
  local options = vim.tbl_extend("force", defaults, opts or {})
  defaults = options
  group_icons = normalize_icons(options)
  group_label_map = options.group_labels or options.profile_labels or {}

  local command_profile = "DBConnections"

  local function run_open(cmd)
    local raw = vim.trim(cmd.args)
    local args = vim.split(raw, "%s+", { trimempty = true })

    if #args == 0 then
      M.pick_profile({
        usage_hint = picker_shortcuts_hint(),
      })
      return
    end

    local mode = args[1]
    if mode == "all" then
      M.open("all", nil, { prefix = false })
      return
    end

    if mode == "edit" then
      local group = args[2]
      if not group then
        show_warn("Specify group name: :" .. command_profile .. " " .. mode .. " <group>")
        return
      end
      M.edit_group(group)
      return
    end

    if mode == "add" or mode == "new" then
      local group = args[2]
      if not group then
        show_warn("Specify group name: :" .. command_profile .. " " .. mode .. " <group>")
        return
      end
      M.create_group(group)
      return
    end

    if mode == "help" or mode == "?" then
    show_info("Usage:")
      show_info(":DBConnections           Open connection picker")
      show_info(":DBConnections <group>    Open one group directly")
      show_info(":DBConnections add <group>   Create a new group file")
      show_info(":DBConnections all        Open all groups")
      show_info(":DBConnections edit <group> Edit group file")
      show_info("Available groups: " .. table.concat(group_candidates(), ", "))
      return
    end

    M.open(mode, nil, { prefix = false })
  end

  local function group_command_candidates()
    return group_candidates()
  end

  local function connection_command_complete(arg_lead, cmd_line)
    local parts = vim.split(vim.trim(cmd_line), "%s+", { trimempty = true })
    local groups = group_candidates()

    if #parts <= 1 then
      local candidates = vim.deepcopy(groups)
      vim.list_extend(candidates, { "all", "add", "new", "edit", "help", "?" })
      return vim.tbl_filter(function(item)
        return vim.startswith(item, arg_lead)
      end, candidates)
    end

    if parts[2] == "edit" then
      return vim.tbl_filter(function(item)
        return vim.startswith(item, arg_lead)
      end, group_command_candidates())
    end

    if parts[2] == "add" or parts[2] == "new" then
      return {}
    end

    return vim.tbl_filter(function(item)
      return vim.startswith(item, arg_lead)
    end, group_command_candidates())
  end

  vim.api.nvim_create_user_command(command_profile, run_open, {
    nargs = "*",
    complete = connection_command_complete,
    desc = "Open DB connection picker (`:DBConnections [all|<group>|add|edit <group>|help`)",
  })
end

return M
