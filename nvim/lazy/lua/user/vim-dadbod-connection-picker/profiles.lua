local M = {}

local group_data = require("user.vim-dadbod-connection-picker.group_data")
local restore = require("user.vim-dadbod-connection-picker.restore")
local commands = require("user.vim-dadbod-connection-picker.commands")
local ui = require("user.vim-dadbod-connection-picker.ui")
local query = require("user.vim-dadbod-connection-picker.query")
local util = require("user.vim-dadbod-connection-picker.util")

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
  backup_dir = nil,
  confirm_open = false,
  confirm_open_group = false,
  confirm_modify = false,
  confirm_delete = true,
  delete_to_trash = true,
  icons = {},
}
local command_name = "DBPicker"

local next_backup_path = restore.next_backup_path
local copy_file = restore.copy_file
local record_backup_path = restore.record_backup_path
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

local picker_shortcuts_hint = ui.picker_shortcuts_hint
local picker_shortcuts_hint_full = ui.picker_shortcuts_hint_full
local add_hint_rows = ui.add_hint_rows
local truncate_for_display = ui.truncate_for_display
local confirm_action = ui.confirm_action

local function masked_url(raw_url)
  if type(raw_url) ~= "string" then
    return raw_url
  end
  local masked = raw_url:gsub("(%w+://[^:/]+:)[^@/%s]+@", "%1****@")
  if masked ~= raw_url then
    return masked
  end
  return raw_url
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

local function next_placeholder()
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

local function prompt_first_connection()
  vim.ui.input({
    prompt = "Group name: ",
    default = "local",
  }, function(raw_group)
    if raw_group == nil then
      return
    end

    local group = group_data.normalize_group_name(raw_group)
    if not group or group == "all" then
      show_warn("Invalid group name.")
      return
    end

    fill_connection_with_prompt(function(conn)
      if
        not confirm_action(
          "Create first connection?",
          string.format("Group: %s\nName: %s\nURL: %s", group, conn.name, masked_url(conn.url)),
          defaults.confirm_modify
        )
      then
        return
      end

      local path = group_data.group_file(group)
      group_data.write_group_file(path, { conn })
      show_info("Created first DB connection: " .. conn.name)
      vim.schedule(function()
        M.pick_group({})
      end)
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

    if
      not confirm_action(
        "Create new group?",
        string.format("Group: %s", normalized),
        defaults.confirm_modify
      )
    then
      return
    end

    M.create_group(normalized)
  end)
end

local function open_file(path)
  local escaped = vim.fn.fnameescape(path)
  local cmd = vim.bo.modifiable == false and ("edit! " .. escaped) or ("edit " .. escaped)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    show_error("Failed to open file: " .. path .. "\n" .. tostring(err))
  end
end

local function open_file_for_edit(path)
  vim.schedule(function()
    open_file(path)
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

  for _, name in ipairs(util.sorted_keys(groups)) do
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
    string.format("URL: %s", masked_url(conn.url)),
  }
  if extra then
    lines[#lines + 1] = extra
  end
  return table.concat(lines, "\n")
end

local function build_group_items(groups, expanded)
  local items = {}
  local ordered = util.sorted_keys(groups)

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
      if count > 1 then
        table.insert(items, {
          text = string.format("  %s Open all (%d): %s", group_icons.open_all, count, group),
          kind = "open_all",
          group = group,
          preview = {
            text = string.format("Group: %s\nOpen all %d connections at once.", group, count),
          },
        })
      end

      if count == 0 then
        table.insert(items, {
          text = "  (no connections)",
          kind = "empty_connection",
          group = group,
          preview = {
            text = string.format(
              "Group: %s\nNo connections configured.\nTip: use :%s edit %s",
              group,
              command_name,
              group
            ),
          },
        })
      end

      for index, conn in ipairs(groups[group] or {}) do
        local detail = string.format("    %s (%s)", conn.name, truncate_for_display(conn.url))
        table.insert(items, {
          text = detail,
          kind = "connection",
          group = group,
          connection = conn,
          connection_index = index,
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
  for _, group in ipairs(util.sorted_keys(groups)) do
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
  local ordered = util.sorted_keys(group_meta)

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
  if
    not confirm_action(
      "Open connection?",
      string.format("Group: %s\nName: %s", tostring(group), tostring(name)),
      defaults.confirm_open
    )
  then
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
  local show_detailed_shortcuts = false

  local function get_shortcuts_hint()
    if usage_hint ~= nil then
      return usage_hint
    end
    if show_detailed_shortcuts then
      return picker_shortcuts_hint_full()
    end
    return picker_shortcuts_hint()
  end

  local function items()
    return build_group_items(groups, expanded)
  end
  local ordered_groups = util.sorted_keys(groups)
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
    local function start_first_connection_setup(picker)
      if picker and type(picker.close) == "function" then
        picker:close()
      end
      prompt_first_connection()
    end

    local no_group_win = vim.tbl_deep_extend("force", layout.win or {}, {
      list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
        keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), {
          ["n"] = {
            start_first_connection_setup,
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
        local sample_name = "sample"
        if
          type(defaults.group_placeholders) == "table"
          and type(defaults.group_placeholders[1]) == "table"
          and type(defaults.group_placeholders[1].name) == "string"
          and defaults.group_placeholders[1].name ~= ""
        then
          sample_name = defaults.group_placeholders[1].name
        end
        local safe_sample_name = group_data.normalize_group_name(sample_name) or "sample"
        local sample_url = "postgresql://..."
        if
          type(defaults.group_placeholders) == "table"
          and type(defaults.group_placeholders[1]) == "table"
          and type(defaults.group_placeholders[1].url) == "string"
          and defaults.group_placeholders[1].url ~= ""
        then
          sample_url = defaults.group_placeholders[1].url
        end

        local rows = {
          {
            text = "+ Add first connection",
            kind = "setup",
            preview = {
              text = "No DB connections found.\nPress <CR> to enter a group name, connection name, and URL.",
            },
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
                .. vim.inspect(sample_url)
                .. " } }",
            },
          },
        }
        add_hint_rows(rows, get_shortcuts_hint(), {
          mode = "append",
          first_prefix = "  ",
          rest_prefix = "  ",
        })
        return rows
      end,
      format = "text",
      prompt = "> ",
      preview = "preview",
      focus = "list",
      layout = layout,
      win = no_group_win,
      confirm = start_first_connection_setup,
    })
    return
  end

  local picker_instance = nil

  local function toggle_shortcuts()
    show_detailed_shortcuts = not show_detailed_shortcuts
    if picker_instance and type(picker_instance.refresh) == "function" then
      picker_instance:refresh()
    end
  end

  local function move_picker_up()
    local up = vim.api.nvim_replace_termcodes("<Up>", true, false, true)
    vim.schedule(function()
      if picker_instance then
        vim.api.nvim_feedkeys(up, "n", false)
      end
    end)
  end

  local function close_and_reload_picker(opts)
    opts = opts or {}
    if not picker_instance then
      return
    end

    groups = group_data.build_group_connections()
    if type(picker_instance.refresh) == "function" then
      picker_instance:refresh()
    end

    if opts.move_up then
      move_picker_up()
    end
  end

  local function pick_current_row()
    if not picker_instance then
      return nil
    end
    if type(picker_instance.current) ~= "function" then
      show_warn("Current picker API does not expose current selection.")
      return nil
    end
    return picker_instance:current()
  end

  local function normalize_group_name_from_current_row(action_label, current)
    if not current then
      current = pick_current_row()
    end
    if not current then
      return nil
    end

    local group = current.group
    if type(group) ~= "string" or group == "" then
      return nil
    end

    if action_label and current.kind ~= "group" then
      show_warn("Move to a group row to " .. action_label .. ".")
      return nil
    end

    return group
  end

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
      local connection_count = #(groups[item.group] or {})
      if defaults.confirm_open_group then
        local ok = confirm_action(
          string.format("Open all %d connections in %s?", connection_count, item.group),
          string.format("Group: %s\nConnections: %d", item.group, connection_count),
          defaults.confirm_open_group
        )
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
    local group = normalize_group_name_from_current_row(nil, nil)
    if not group then
      return
    end

    picker_instance:close()
    M.edit_group(group)
  end

  local function handle_add_connection_to_current_group()
    local group = normalize_group_name_from_current_row(nil, nil)
    if not group then
      if vim.tbl_isempty(group_data.build_group_connections()) then
        handle_add_group_from_picker()
        return
      end

      show_warn("Move to a group row to add a connection.")
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
      if
        not confirm_action(
          "Add new connection?",
          string.format("Group: %s\nName: %s\nURL: %s", group, conn.name or "", masked_url(conn.url)),
          defaults.confirm_modify
        )
      then
        return
      end

      table.insert(existing, conn)
      group_data.write_group_file(path, existing)
      show_info("Added connection to group: " .. group)
      open_file_for_edit(path)
    end)
  end

  local function handle_add_group_from_picker()
    local default_name = ""
    local current = pick_current_row()
    if current and type(current.group) == "string" and current.group ~= "" and current.group ~= "all" then
      default_name = current.group
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

  local function handle_rename_current_group()
    local old_group = normalize_group_name_from_current_row("rename it", nil)
    if not old_group then
      return
    end

    local old_path = group_data.group_file(old_group)
    if not old_path then
      show_warn("Unable to resolve group path: " .. tostring(old_group))
      return
    end

    vim.ui.input({
      prompt = "Rename group: ",
      default = old_group,
    }, function(raw_name)
      if raw_name == nil then
        return
      end

      local normalized = group_data.normalize_group_name(raw_name)
      if not normalized or normalized == "" then
        show_warn("Invalid group name.")
        return
      end

      if normalized == old_group then
        show_info("Rename cancelled.")
        return
      end

      if group_data.group_file_exists(normalized) then
        show_warn("Group already exists: " .. normalized)
        return
      end

      if
        not confirm_action(
          "Rename group?",
          string.format("From: %s\nTo: %s", old_group, normalized),
          defaults.confirm_modify
        )
      then
        return
      end

      local ok, err = vim.loop.fs_rename(old_path, group_data.group_file(normalized))
      if not ok then
        show_error("Failed to rename group: " .. tostring(err))
        return
      end

      show_info("Renamed group: " .. old_group .. " -> " .. normalized)
      close_and_reload_picker({ move_up = true })
    end)
  end

  local function handle_delete_current_group()
    local current = pick_current_row()
    if not current then
      return
    end

    if current.kind == "connection" then
      local group = current.group
      if type(group) ~= "string" or group == "" then
        return
      end
      local connection_index = current.connection_index
      if type(connection_index) ~= "number" then
        show_warn("No stable connection row index. Move to a connection line and try again.")
        return
      end

      local connections, path = group_data.load_group_connections(group)
      if not path then
        show_warn("No group file found: " .. group)
        return
      end
      if type(connections) ~= "table" then
        connections = {}
      end

      local target = connections[connection_index]
      if not target then
        show_warn("No matching connection found in group: " .. group)
        return
      end

      if
        not confirm_action(
          "Delete connection?",
          string.format(
            "Group: %s\nName: %s\nURL: %s",
            group,
            tostring(target.name or ""),
            masked_url(target.url or "")
          ),
          defaults.confirm_delete,
          {
            confirm_label = "&Delete",
            cancel_label = "&Keep",
            default = 2,
          }
        )
      then
        return
      end

      local backup_path
      local has_backup = false
      if defaults.delete_to_trash then
        backup_path = next_backup_path(path)
        if not backup_path then
          show_error("Failed to resolve backup path.")
          return
        end
        local ok, err = copy_file(path, backup_path)
        if not ok then
          show_error("Failed to backup group: " .. tostring(err))
          return
        end
        record_backup_path(backup_path)
        has_backup = true
      end

      table.remove(connections, connection_index)

      local wrote_ok, write_err = pcall(group_data.write_group_file, path, connections)
      if not wrote_ok then
        if has_backup then
          local restore_ok, restore_err = copy_file(backup_path, path)
          if not restore_ok then
            show_error(
              "Failed to restore backup after write failure: "
                .. tostring(restore_err)
                .. ". Backup exists: "
                .. tostring(backup_path)
            )
          else
            show_error("Failed to delete connection: " .. tostring(write_err))
          end
        else
          show_error("Failed to delete connection: " .. tostring(write_err))
        end
        return
      end

      if has_backup then
        show_info("Backed up group before delete: " .. backup_path)
      end
      show_info("Deleted connection from " .. group .. ": " .. tostring(target.name or "unnamed"))
      close_and_reload_picker()
      return
    end

    if current.kind ~= "group" then
      show_warn("Move to a group row to delete it.")
      return
    end

    local group = current.group
    if type(group) ~= "string" or group == "" then
      return
    end

    local path = group_data.group_file(group)
    if not path then
      show_warn("Unable to resolve group file for: " .. tostring(group))
      return
    end

    if vim.fn.filereadable(path) ~= 1 then
      show_warn("No group file found: " .. tostring(group))
      return
    end

      if
        not confirm_action(
          "Delete group?",
          string.format("Group: %s\nPath: %s", group, path),
          defaults.confirm_delete,
          {
            confirm_label = "&Delete",
            cancel_label = "&Keep",
            default = 2,
          }
        )
      then
        return
      end

    if defaults.delete_to_trash then
      local backup_path = next_backup_path(path)
      if not backup_path then
        show_error("Failed to resolve backup path.")
        return
      end
      local ok, err = copy_file(path, backup_path)
      if not ok then
        show_error("Failed to backup group: " .. tostring(err))
        return
      end
      record_backup_path(backup_path)
      local removed = vim.fn.delete(path)
      if removed ~= 0 then
        show_error("Failed to delete group file: " .. path)
        return
      end
      show_info("Moved group to backup: " .. backup_path)
    else
      local removed = vim.fn.delete(path)
      if removed ~= 0 then
        show_error("Failed to delete group file: " .. path)
        return
      end
      show_info("Deleted group: " .. group)
    end

    close_and_reload_picker({ move_up = true })
  end

  local function handle_restore_current_group()
    M.restore_group(nil, {
      mode = "undo",
      on_success = function()
        close_and_reload_picker()
      end,
    })
  end

  local function handle_redo_current_group()
    M.restore_group(nil, {
      mode = "redo",
      on_success = function()
        close_and_reload_picker()
      end,
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
        ["r"] = {
          function()
            handle_rename_current_group()
          end,
          mode = { "n" },
        },
        ["d"] = {
          function()
            handle_delete_current_group()
          end,
          mode = { "n" },
        },
        ["u"] = {
          function()
            handle_restore_current_group()
          end,
          mode = { "n" },
        },
        ["<C-r>"] = {
          function()
            handle_redo_current_group()
          end,
          mode = { "n" },
        },
        ["?"] = {
          function()
            toggle_shortcuts()
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
        ["r"] = {
          function()
            handle_rename_current_group()
          end,
          mode = { "n" },
        },
        ["d"] = {
          function()
            handle_delete_current_group()
          end,
          mode = { "n" },
        },
        ["?"] = {
          function()
            toggle_shortcuts()
          end,
          mode = { "n" },
        },
      }),
    }),
  })

  if type(custom_win.input) == "table" and type(custom_win.input.keys) == "table" then
    custom_win.input.keys["u"] = nil
    custom_win.input.keys["<C-r>"] = nil
  end

  local matches_cache = build_group_match_set(groups)
  local last_pattern = nil
  local query_pattern = ""
  local query_has_match = true

  local function has_query_match(pattern)
    return not vim.tbl_isempty(query.find_matches(matches_cache, pattern, util.sorted_keys(groups)))
  end

  local function pattern_matches_group(group, pattern)
    return query.has_token_match(matches_cache[group], pattern)
  end

  local function auto_expand_on_query(picker)
    local pattern = picker:filter().pattern or ""
    query_pattern = query.normalize_filter_pattern(pattern)
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
        add_hint_rows(rows, {
          "No match for " .. string.format("%q", query_pattern) .. ".",
          "Tip: / filter",
          "Press <CR> to open.",
        }, {
          mode = "prepend",
          first_prefix = "> ",
          rest_prefix = "  ",
        })
      end
      add_hint_rows(rows, get_shortcuts_hint(), {
        mode = "prepend",
        first_prefix = "> ",
        rest_prefix = "  ",
      })
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
  local function handle_add_group_from_manage(query_pattern)
    local default_name = ""
    local trimmed_filter = vim.trim(query_pattern or "")
    if trimmed_filter ~= "" then
      default_name = trimmed_filter
    end

    prompt_new_group_name({
      default_name = default_name,
    })
  end

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
    open_file(path)
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

  local ordered_groups = util.sorted_keys(group_meta)
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
    return not vim.tbl_isempty(query.find_matches(query_set, pattern, ordered_groups))
  end

  local function auto_expand_manage_on_query(picker)
    local pattern = picker:filter().pattern or ""
    query_pattern = query.normalize_filter_pattern(pattern)
    query_has_match = has_query_match(query_pattern)
  end

  local layout = opts and opts.layout or picker_layout
  local manage_win = vim.tbl_deep_extend("force", layout.win or {}, {
    list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), {
        ["n"] = {
          function()
            handle_add_group_from_manage(query_pattern)
          end,
          mode = { "n" },
        },
      }),
    }),
    input = vim.tbl_deep_extend("force", (layout.win and layout.win.input) or {}, {
      keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.input and layout.win.input.keys) or {}), {
        ["n"] = {
          function()
            handle_add_group_from_manage(query_pattern)
          end,
          mode = { "n" },
        },
      }),
    }),
  })

  picker_api({
    title = "DB Connections Manager",
    finder = function()
      local rows = items()
      if query_pattern ~= "" and not query_has_match then
        table.insert(rows, 1, {
          text = "No match for " .. string.format("%q", query_pattern) .. ". Tip: / filter, <CR> open.",
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
    layout = layout,
    win = manage_win,
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

local function build_group_candidates()
  local groups = util.sorted_keys(group_data.build_group_connections())
  if not util.has_value(groups, "all") then
    table.insert(groups, "all")
  end
  return groups
end

function M.pick_group(opts)
  local groups = group_data.build_group_connections()
  local expanded = {}
  for _, group in ipairs(util.sorted_keys(groups)) do
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

function M.manage_groups()
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

  M.current_group = label

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
  open_file(path)
end

function M.editor(group)
  if not group then
    show_warn("Specify group name: :" .. command_name .. " edit <group>")
    return
  end
  M.edit_group(group)
end

function M.open_group(name)
  M.open(name)
end

function M.open_connection_group(group)
  M.open(group)
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
    open_file(path)
    return
  end

  group_data.write_group_file(path, defaults.group_placeholders)
  show_info("Created group file: " .. path)
  open_file(path)
end

function M.restore_group(group, opts)
  return restore.restore_group(group, opts)
end

function M.setup(opts)
  local options = vim.tbl_extend("force", defaults, opts or {})
  options.backup_dir = restore.resolve_backup_dir(options.backup_dir)
  defaults = options
  command_name = options.command_name or command_name
  group_icons = normalize_icons(options)
  group_label_map = options.group_labels or {}
  ui.setup({
    get_defaults = function()
      return defaults
    end,
    show_warn = show_warn,
  })
  restore.setup({
    get_defaults = function()
      return defaults
    end,
    group_data = group_data,
    show_info = show_info,
    show_warn = show_warn,
    show_error = show_error,
    confirm_action = confirm_action,
    open_file = open_file,
  })

  commands.setup({
    command_name = command_name,
    open_group_picker = function()
      M.pick_group({})
    end,
    open = function(group, options, opts)
      M.open(group, options, opts)
    end,
    edit_group = function(group)
      M.edit_group(group)
    end,
    create_group = function(group)
      M.create_group(group)
    end,
    restore_group = function(group)
      M.restore_group(group)
    end,
    show_info = show_info,
    show_warn = show_warn,
    group_candidates = function()
      return build_group_candidates()
    end,
  })
end

return M
