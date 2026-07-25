local M = {}

local util = require("user.vim-dadbod-connection-picker.util")
local query = require("user.vim-dadbod-connection-picker.query")

local ctx = {}

function M.setup(options)
  ctx = options or {}
end

local function get_defaults()
  if type(ctx.get_defaults) == "function" then
    local values = ctx.get_defaults()
    if type(values) == "table" then
      return values
    end
  end
  return {}
end

local function get_group_icons()
  if type(ctx.get_group_icons) == "function" then
    local icons = ctx.get_group_icons()
    if type(icons) == "table" then
      return icons
    end
  end
  return {
    folder_expanded = "[-]",
    folder_collapsed = "[+]",
    open_group = ">",
    open_all = ">>",
  }
end

local function get_command_name()
  if type(ctx.command_name) == "function" then
    return tostring(ctx.command_name() or "DBPicker")
  end
  if type(ctx.command_name) == "string" then
    return ctx.command_name
  end
  return "DBPicker"
end

local function call_notify(level, message)
  if level == "info" and type(ctx.show_info) == "function" then
    ctx.show_info(message)
    return
  end
  if level == "warn" and type(ctx.show_warn) == "function" then
    ctx.show_warn(message)
    return
  end
  if level == "error" and type(ctx.show_error) == "function" then
    ctx.show_error(message)
    return
  end

  local level_map = {
    info = vim.log.levels.INFO,
    warn = vim.log.levels.WARN,
    error = vim.log.levels.ERROR,
  }
  vim.notify(message, level_map[level] or vim.log.levels.INFO)
end

local function show_info(message)
  call_notify("info", message)
end

local function show_warn(message)
  call_notify("warn", message)
end

local function show_error(message)
  call_notify("error", message)
end

local function get_fn(name)
  return ctx[name]
end

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

local function truncate_for_display(value)
  local max_len = 72
  if type(value) ~= "string" then
    return ""
  end
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len - 3) .. "..."
end

local function confirm_action(message, detail, should_confirm, opts)
  if type(ctx.confirm_action) == "function" then
    return ctx.confirm_action(message, detail, should_confirm, opts)
  end

  if should_confirm == false then
    return true
  end
  if should_confirm == nil then
    should_confirm = get_defaults().confirm_open
  end
  if not should_confirm then
    return true
  end

  local title = tostring(message or "Confirm")
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

  local normalized = {}
  for _, line in ipairs(detail_lines) do
    local t = truncate_for_display(vim.trim(line))
    if t ~= "" then
      normalized[#normalized + 1] = t
    end
  end

  local confirm_label = "&Proceed"
  local cancel_label = "&Cancel"
  local default = 1
  if type(opts) == "table" then
    confirm_label = opts.confirm_label or confirm_label
    cancel_label = opts.cancel_label or cancel_label
    default = opts.default or default
  end

  confirm_label = tostring(confirm_label):gsub("&", "")
  cancel_label = tostring(cancel_label):gsub("&", "")
  if confirm_label == "" then
    confirm_label = "Proceed"
  end
  if cancel_label == "" then
    cancel_label = "Cancel"
  end

  local prompt_lines = { title }
  for _, line in ipairs(normalized) do
    prompt_lines[#prompt_lines + 1] = "  " .. line
  end
  local default_is_yes = default == 1
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
    show_warn("Please type y or n.")
  end
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

local function build_group_items(groups, expanded, options)
  local items = {}
  local ordered = util.sorted_keys(groups)
  local group_icons = options.group_icons or {}
  local command_name = options.command_name

  for _, group in ipairs(ordered) do
    local is_expanded = expanded[group] == true
    local glyph = is_expanded and (group_icons.folder_expanded or "[-]") or (group_icons.folder_collapsed or "[+]")
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
          text = string.format("  %s Open all (%d): %s", group_icons.open_all or ">>", count, group),
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

local function open_connection(group, conn)
  if type(conn) ~= "table" or type(conn.url) ~= "string" then
    return false
  end
  local defaults = get_defaults()
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
  if type(ctx.open_connection) == "function" then
    return ctx.open_connection({ { name = conn.name, url = conn.url } }, name)
  end
  return false
end

function M.open_groups(groups, expanded, opts)
  local defaults = get_defaults()
  local layout = (opts and opts.layout) or ctx.picker_layout
  local usage_hint = opts and opts.usage_hint or nil
  local show_detailed_shortcuts = false
  local group_data = ctx.group_data
  local command_name = get_command_name()
  local group_icons = get_group_icons()

  local function get_shortcuts_hint()
    if usage_hint ~= nil then
      return usage_hint
    end
    if show_detailed_shortcuts and type(ctx.picker_shortcuts_hint_full) == "function" then
      return ctx.picker_shortcuts_hint_full()
    end
    if type(ctx.picker_shortcuts_hint) == "function" then
      return ctx.picker_shortcuts_hint()
    end
    return {
      "/:filter, <CR>:open, a:add connection, n:add group, ? :shortcuts",
    }
  end

  local function items()
    return build_group_items(groups, expanded, {
      group_icons = group_icons,
      command_name = command_name,
    })
  end

  local ordered_groups = util.sorted_keys(groups)
  local total_groups = #ordered_groups
  local total_connections = 0
  for _, group in ipairs(ordered_groups) do
    total_connections = total_connections + #(groups[group] or {})
  end

  local picker_api = resolve_snacks_picker()
  if not picker_api then
    if opts and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    show_warn("snacks.picker is not available. Please install folke/snacks.nvim.")
    return
  end

  if #items() == 0 then
    local groups_dir = group_data and group_data.connections_dir and group_data.connections_dir() or ""
    local no_group_win = vim.tbl_deep_extend("force", layout.win or {}, {
      list = vim.tbl_deep_extend("force", (layout.win and layout.win.list) or {}, {
        keys = vim.tbl_deep_extend("force", ((layout.win and layout.win.list and layout.win.list.keys) or {}), {
          ["n"] = {
            function()
              if type(ctx.prompt_new_group_name) == "function" then
                ctx.prompt_new_group_name({ default_name = "office" })
              end
            end,
            mode = { "n" },
          },
        }),
      }),
      input = vim.tbl_deep_extend("force", (layout.win and layout.win.input) or {}, {
        keys = vim.tbl_deepenforce((layout.win and layout.win.input and layout.win.input.keys) or {}, {}),
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
            text = "No DB groups found.",
            kind = "hint",
            preview = {
              text = "No DB groups found.\nPress n to add a new group.",
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
        if type(ctx.add_hint_rows) == "function" then
          ctx.add_hint_rows(rows, get_shortcuts_hint(), {
            mode = "append",
            first_prefix = "  ",
            rest_prefix = "  ",
          })
        end
        return rows
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

  local function close_and_reload_picker(options)
    options = options or {}
    if not picker_instance then
      return
    end

    if group_data and type(group_data.build_group_connections) == "function" then
      groups = group_data.build_group_connections()
    end
    if type(picker_instance.refresh) == "function" then
      picker_instance:refresh()
    end

    if options.move_up then
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
      if type(ctx.open) == "function" then
        ctx.open(item.group, nil, { prefix = opts and opts.prefix })
      end
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

    if type(picker_instance.close) == "function" then
      picker_instance:close()
    end
    if type(ctx.edit_group) == "function" then
      ctx.edit_group(group)
    end
  end

  local function handle_add_connection_to_current_group()
    local group = normalize_group_name_from_current_row(nil, nil)
    if not group then
      if not group_data or vim.tbl_isempty(group_data.build_group_connections()) then
        if type(picker_instance.filter) == "function" and false then
          return
        end
        if type(ctx.prompt_new_group_name) == "function" then
          handle_add_group_from_picker()
        end
        return
      end
      show_warn("Move to a group row to add a connection.")
      return
    end

    if not group_data or type(group_data.load_group_connections) ~= "function" then
      show_warn("Missing group data dependency.")
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

    if type(ctx.fill_connection_with_prompt) ~= "function" then
      show_warn("Missing input helper dependency.")
      return
    end

    ctx.fill_connection_with_prompt(function(conn)
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
      if type(ctx.open_file_for_edit) == "function" then
        ctx.open_file_for_edit(path)
      end
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

    if type(ctx.prompt_new_group_name) == "function" then
      ctx.prompt_new_group_name({
        default_name = default_name,
      })
    end
  end

  local function handle_rename_current_group()
    local old_group = normalize_group_name_from_current_row("rename it", nil)
    if not old_group then
      return
    end
    if not group_data then
      show_warn("Missing group data dependency.")
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

    local next_backup_path = ctx.next_backup_path
    local copy_file = ctx.copy_file
    local record_backup_path = ctx.record_backup_path

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
        if type(next_backup_path) ~= "function" then
          show_error("Missing backup path helper.")
          return
        end

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
        if type(record_backup_path) == "function" then
          record_backup_path(backup_path)
        end
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

    local next_backup = ctx.next_backup_path
    if defaults.delete_to_trash then
      local next_backup_path_for_group
      if type(next_backup) ~= "function" then
        show_error("Missing backup path helper.")
        return
      end
      next_backup_path_for_group = next_backup(path)
      if not next_backup_path_for_group then
        show_error("Failed to resolve backup path.")
        return
      end
      local ok, err = copy_file(path, next_backup_path_for_group)
      if not ok then
        show_error("Failed to backup group: " .. tostring(err))
        return
      end
      if type(record_backup_path) == "function" then
        record_backup_path(next_backup_path_for_group)
      end
      local removed = vim.fn.delete(path)
      if removed ~= 0 then
        show_error("Failed to delete group file: " .. path)
        return
      end
      show_info("Moved group to backup: " .. next_backup_path_for_group)
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
    if type(ctx.restore_group) == "function" then
      ctx.restore_group(nil, {
        mode = "undo",
        on_success = function()
          close_and_reload_picker()
        end,
      })
    end
  end

  local function handle_redo_current_group()
    if type(ctx.restore_group) == "function" then
      ctx.restore_group(nil, {
        mode = "redo",
        on_success = function()
          close_and_reload_picker()
        end,
      })
    end
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
        if type(ctx.add_hint_rows) == "function" then
          ctx.add_hint_rows(rows, {
            "No match for " .. string.format("%q", query_pattern) .. ".",
            "Tip: / filter",
            "Press <CR> to open.",
          }, {
            mode = "prepend",
            first_prefix = "> ",
            rest_prefix = "  ",
          })
        end
      end
      if type(ctx.add_hint_rows) == "function" then
        ctx.add_hint_rows(rows, get_shortcuts_hint(), {
          mode = "prepend",
          first_prefix = "> ",
          rest_prefix = "  ",
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

function M.open_manage_picker(group_meta, opts)
  local defaults = get_defaults()
  local layout = (opts and opts.layout) or ctx.picker_layout
  local group_data = ctx.group_data

  local function handle_add_group_from_manage(query_pattern)
    local default_name = ""
    local trimmed_filter = vim.trim(query_pattern or "")
    if trimmed_filter ~= "" then
      default_name = trimmed_filter
    end

    if type(ctx.prompt_new_group_name) == "function" then
      ctx.prompt_new_group_name({
        default_name = default_name,
      })
    end
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
    if opts and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    show_warn("snacks.picker is not available. Please install folke/snacks.nvim.")
    return
  end

  local function open_group_file(path)
    if not path then
      return
    end
    if type(ctx.open_file) == "function" then
      ctx.open_file(path)
    end
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

return M
