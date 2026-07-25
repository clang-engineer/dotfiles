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
  backup_dir = nil,
  confirm_open = false,
  confirm_open_group = false,
  confirm_modify = false,
  confirm_delete = true,
  delete_to_trash = true,
  icons = {},
}

local function normalize_backup_dir(path)
  local fallback = vim.fn.stdpath("data") .. "/vim-dadbod-connection-picker/connections-backup"
  if type(path) ~= "string" or vim.trim(path) == "" then
    return fallback
  end
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

local function ensure_directory(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  local mkdir_ok = vim.fn.mkdir(path, "p")
  if mkdir_ok ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    return false
  end
  return true
end

local function normalize_backup_path(path)
  if type(path) ~= "string" then
    return nil
  end
  local normalized = vim.fn.fnamemodify(vim.trim(path), ":p")
  if normalized == "" then
    return nil
  end
  normalized = normalized:gsub("/+$", "")
  return normalized
end

local function resolve_backup_dir(raw_dir)
  local preferred = normalize_backup_dir(raw_dir)
  if ensure_directory(preferred) then
    return normalize_backup_path(preferred)
  end

  local fallback = normalize_backup_dir(nil)
  if ensure_directory(fallback) then
    return normalize_backup_path(fallback)
  end

  return nil
end

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

local function filter_starts_with(values, needle)
  if needle == nil or needle == "" then
    return values
  end

  local result = {}
  for _, value in ipairs(values) do
    if vim.startswith(value, needle) then
      result[#result + 1] = value
    end
  end
  return result
end

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
  return {
    "/:filter, <CR>:open, a:add conn, n:add group, ? :shortcuts",
  }
end

local function picker_shortcuts_hint_full()
  return {
    "/:filter, <CR>:open",
    "a:add conn",
    "n:add group",
    "e:edit",
    "r:rename",
    "d:delete",
    "u:undo",
    "<C-r>:redo",
    "?:compact",
  }
end

local function normalize_hint_lines(raw)
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

local function add_hint_rows(rows, raw_lines, opts)
  local lines = normalize_hint_lines(raw_lines)
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

local function truncate_for_display(value)
  local max_len = 72
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len - 3) .. "..."
end

local function confirm_action(message, detail, should_confirm, opts)
  if should_confirm == false then
    return true
  end
  if should_confirm == nil then
    should_confirm = defaults.confirm_open
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
      local normalized = truncate_for_display(vim.trim(line))
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
    show_warn("Please type y or n.")
  end
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

local function next_backup_path(path)
  local backup_dir = resolve_backup_dir(defaults.backup_dir)
  if not backup_dir then
    return nil
  end

  if type(path) ~= "string" then
    return nil
  end
  local filename = vim.fn.fnamemodify(path, ":t")
  if filename == "" then
    return nil
  end

  local timestamp = os.date("%Y%m%d%H%M%S")
  local next_index = 1
  local candidate = string.format("%s/%s.%s.bak", backup_dir, filename, timestamp)

  while vim.fn.filereadable(candidate) == 1 do
    next_index = next_index + 1
    candidate = string.format("%s/%s.%s.%d.bak", backup_dir, filename, timestamp, next_index)
  end

  return candidate
end

local GUARD_PREFIX = "vim_dbcp_restore_"
local BACKUP_HISTORY_LIMIT = 20
local restore_state = {
  busy = false,
  journal = nil,
  consumed = nil,
  redo = nil,
}

local function restore_guard_clear()
  restore_state.busy = false
end

local function restore_journal()
  local journal = restore_state.journal
  if type(journal) ~= "table" then
    journal = {}
    restore_state.journal = journal
  end
  return journal
end

local function restore_consumed()
  local consumed = restore_state.consumed
  if type(consumed) ~= "table" then
    consumed = {}
    restore_state.consumed = consumed
  end
  return consumed
end

local function mark_backup_consumed(path)
  local normalized = normalize_backup_path(path)
  if not normalized then
    return
  end

  local consumed = restore_consumed()
  local next_state = { normalized }
  for _, saved in ipairs(consumed) do
    local normalized_saved = normalize_backup_path(saved)
    if normalized_saved and normalized_saved ~= normalized then
      next_state[#next_state + 1] = normalized_saved
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #next_state) do
    consumed[i] = next_state[i]
  end
  for i = #next_state + 1, #consumed do
    consumed[i] = nil
  end
end

local function restore_redo()
  local redo = restore_state.redo
  if type(redo) ~= "table" then
    redo = {}
    restore_state.redo = redo
  end
  return redo
end

local function restore_redo_clear()
  restore_state.redo = {}
end

local function restore_redo_push(entry)
  local raw_entry = entry or {}
  local undo_path = normalize_backup_path(raw_entry.undo_path)
  local redo_path = normalize_backup_path(raw_entry.redo_path)
  if not undo_path and not redo_path then
    return
  end

  local entry_group = raw_entry.group
  if type(entry_group) == "string" then
    entry_group = group_data.normalize_group_name(entry_group)
  end

  local next_stack = {
    {
      undo_path = undo_path,
      redo_path = redo_path,
      group = entry_group,
    },
  }

  local existing = restore_redo()
  for _, item in ipairs(existing) do
    if type(item) == "table" then
      local item_undo = normalize_backup_path(item.undo_path)
      local item_redo = normalize_backup_path(item.redo_path)
      if item_undo ~= undo_path or item_redo ~= redo_path then
        next_stack[#next_stack + 1] = item
      end
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #next_stack) do
    existing[i] = next_stack[i]
  end
  for i = #next_stack + 1, #existing do
    existing[i] = nil
  end

  if redo_path then
    mark_backup_consumed(redo_path)
  end
end

local function restore_redo_pop()
  local redo = restore_redo()
  local top = redo[1]
  if not top then
    return nil
  end
  table.remove(redo, 1)
  return top
end

local function is_consumed_backup(path)
  local normalized = normalize_backup_path(path)
  if not normalized then
    return false
  end
  local consumed = restore_consumed()
  for _, saved in ipairs(consumed) do
    local normalized_saved = normalize_backup_path(saved)
    if normalized_saved == normalized then
      return true
    end
  end
  return false
end

local function consume_backup_entry(backup_path)
  local normalized = normalize_backup_path(backup_path)
  if not normalized then
    return
  end

  local journal = restore_journal()
  local next_journal = {}
  for _, path in ipairs(journal) do
    local normalized_path = normalize_backup_path(path)
    if normalized_path ~= normalized then
      next_journal[#next_journal + 1] = normalized_path
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #next_journal) do
    journal[i] = next_journal[i]
  end
  for i = #next_journal + 1, #journal do
    journal[i] = nil
  end

  mark_backup_consumed(backup_path)
end

local function record_backup_path(backup_path, opts)
  opts = opts or {}
  local normalized = normalize_backup_path(backup_path)
  if not normalized then
    return
  end

  local journal = restore_journal()
  local deduped = {}
  table.insert(deduped, normalized)
  for _, path in ipairs(journal) do
    local normalized_path = normalize_backup_path(path)
    if normalized_path and normalized_path ~= normalized then
      deduped[#deduped + 1] = normalized_path
    end
  end

  for i = 1, math.min(BACKUP_HISTORY_LIMIT, #deduped) do
    journal[i] = deduped[i]
  end
  for i = #deduped + 1, #journal do
    journal[i] = nil
  end

  local consumed = restore_consumed()
  local next_consumed = {}
  for _, saved in ipairs(consumed) do
    local normalized_saved = normalize_backup_path(saved)
    if normalized_saved and normalized_saved ~= normalized then
      next_consumed[#next_consumed + 1] = normalized_saved
    end
  end
  for i = 1, #next_consumed do
    consumed[i] = next_consumed[i]
  end
  for i = #next_consumed + 1, #consumed do
    consumed[i] = nil
  end

  if opts.clear_redo ~= false then
    restore_redo_clear()
  end
end

local function backup_group_from_path(path)
  if type(path) ~= "string" then
    return nil
  end

  local base = vim.fn.fnamemodify(path, ":t")
  if base == "" then
    return nil
  end

  local without_suffix = base:gsub("%.bak$", "")
  while without_suffix:match("%.%d+$") do
    without_suffix = without_suffix:gsub("%.%d+$", "")
  end
  without_suffix = without_suffix:gsub("%.lua%.?$", "")
  return without_suffix ~= "" and without_suffix or nil
end

local function is_existing_backup_path(path)
  local normalized = normalize_backup_path(path)
  return type(normalized) == "string" and vim.fn.filereadable(normalized) == 1
end

local function latest_backup_from_journal(target_group)
  local journal = restore_journal()
  for _, path in ipairs(journal) do
    local group = backup_group_from_path(path)
    if not group then
      -- skip malformed backup filenames
    elseif is_consumed_backup(path) then
      -- skip already-restored backup
    elseif target_group and group ~= target_group then
      -- skip different group
    elseif is_existing_backup_path(path) then
      return path, group
    end

  end
  return nil, nil
end

local function copy_file(source, destination)
  if type(source) ~= "string" or type(destination) ~= "string" then
    return false, "invalid path"
  end
  local destination_dir = vim.fn.fnamemodify(destination, ":h")
  if not ensure_directory(destination_dir) then
    return false, "failed to create destination directory: " .. destination_dir
  end

  if vim.loop.fs_copyfile then
    local ok, err = vim.loop.fs_copyfile(source, destination)
    if ok then
      return true
    end
    return false, tostring(err)
  end

  local read_ok, lines_or_err = pcall(vim.fn.readfile, source)
  if not read_ok or type(lines_or_err) ~= "table" then
    return false, tostring(lines_or_err or "read failed")
  end
  local write_ok, write_err = pcall(vim.fn.writefile, lines_or_err, destination)
  if not write_ok then
    return false, tostring(write_err)
  end
  return true
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
    string.format("URL: %s", masked_url(conn.url)),
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
            text = string.format("Group: %s\nNo connections configured.\nTip: use :DBConnections edit %s", group, group),
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

local function latest_any_group_backup(target_group)
  local dirs = {}
  local seen = {}
  local function add_path(path)
    if type(path) ~= "string" then
      return
    end
    if seen[path] then
      return
    end
    seen[path] = true
    dirs[#dirs + 1] = path
  end

  local configured_backup_dir = resolve_backup_dir(defaults.backup_dir)
  if configured_backup_dir then
    add_path(configured_backup_dir)
  end

  local runtime_backups =
    vim.api.nvim_get_runtime_file("lua/user/vim-dadbod-connection-picker/connections/*.lua.*.bak", true)
  for _, backup in ipairs(runtime_backups or {}) do
    add_path(vim.fn.fnamemodify(backup, ":h"))
  end

  add_path(group_data.connections_dir())
  local file_dirs = group_data.connection_file_dirs()
  for _, dir in ipairs(file_dirs) do
    add_path(dir)
  end

  local candidates = {}
  for _, dir in ipairs(dirs) do
    local pattern = dir .. "/*.lua.*.bak"
    local backup_matches = vim.fn.glob(pattern, false, true)
    for _, backup in ipairs(backup_matches) do
      local stat = vim.loop.fs_stat(backup)
      if stat and stat.mtime and stat.mtime.sec then
        local group = backup_group_from_path(backup)
      local is_eligible = true
      if not group then
        is_eligible = false
      end
        if is_consumed_backup(backup) then
          is_eligible = false
        elseif target_group and group ~= target_group then
          is_eligible = false
        end
        if is_eligible then
          candidates[#candidates + 1] = {
            path = backup,
            group = group,
            mtime = stat.mtime.sec,
          }
        end
      end
    end
  end

  table.sort(candidates, function(lhs, rhs)
    return lhs.mtime > rhs.mtime
  end)

  if #candidates == 0 then
    return nil, nil, "No backup history found."
  end

  return candidates[1].path, candidates[1].group, nil
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
  open_file(path)
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
    open_file(path)
    return
  end

  group_data.write_group_file(path, defaults.group_placeholders)
  show_info("Created group file: " .. path)
  open_file(path)
end

function M.restore_group(group, opts)
  opts = opts or {}
  local mode = opts.mode or "manual"
  local global_busy = restore_state.busy
  if global_busy then
    return
  end
  restore_state.busy = true

  if mode == "undo" then
    -- keep redo stack while working through undo/redo.
  else
    restore_redo_clear()
  end

  local requested_group = nil
  if group and group ~= "" then
    requested_group = group_data.normalize_group_name(group)
    if not requested_group then
      restore_guard_clear()
      show_warn("Invalid group name: " .. tostring(group))
      return
    end
  end

  local backup_path
  local backup_group
  local err
  local entry
  local undo_backup_path

  if mode == "undo" then
    backup_path, backup_group, err = latest_backup_from_journal(requested_group)
    if not backup_path then
      backup_path, backup_group, err = latest_any_group_backup(requested_group)
    end
  elseif mode == "redo" then
    entry = restore_redo_pop()
    if not entry then
      restore_guard_clear()
      show_warn("No redo history.")
      return
    end
    backup_path = entry.redo_path
    backup_group = entry.group or backup_group_from_path(backup_path)
    undo_backup_path = entry.undo_path
  else
    backup_path, backup_group, err = latest_backup_from_journal(requested_group)
    if not backup_path then
      backup_path, backup_group, err = latest_any_group_backup(requested_group)
    end
  end

  if not backup_path then
    restore_guard_clear()
    local no_record_msg = "No restore history."
    if requested_group then
      no_record_msg = "No restore history for group: " .. requested_group
    end
    show_warn(err or no_record_msg)
    return
  end

  if not is_existing_backup_path(backup_path) then
    restore_guard_clear()
    show_warn("Selected backup no longer exists: " .. tostring(backup_path))
    return
  end

  if not backup_group then
    restore_guard_clear()
    show_warn("Failed to identify group from latest backup.")
    return
  end

  local restore_group = group_data.normalize_group_name(backup_group)
  if not restore_group then
    restore_guard_clear()
    show_warn("Failed to identify group from latest backup.")
    return
  end

  local restore_path = group_data.group_file(restore_group)
  if not restore_path then
    restore_guard_clear()
    show_warn("Unable to resolve restore target group: " .. tostring(restore_group))
    return
  end

  restore_path = normalize_backup_path(restore_path)
  if type(restore_path) ~= "string" or restore_path == "" then
    restore_guard_clear()
    show_error("Unable to resolve restore target path.")
    return
  end

  local redo_snapshot
  if mode == "undo" and vim.fn.filereadable(restore_path) == 1 then
    redo_snapshot = next_backup_path(restore_path)
    if not redo_snapshot then
      restore_guard_clear()
      show_error("Failed to resolve redo snapshot path.")
      return
    end
    local snapshot_ok, snapshot_err = copy_file(restore_path, redo_snapshot)
    if not snapshot_ok then
      restore_guard_clear()
      show_error("Failed to snapshot current file for redo: " .. tostring(snapshot_err))
      return
    end
  end

  local title = "Restore latest backup?"
  if mode == "undo" then
    title = "Undo (restore previous backup)?"
  elseif mode == "redo" then
    title = "Redo (restore latest undone state)?"
  end
  local safe_backup
  if
    not confirm_action(
      title,
      string.format("Group: %s\nTarget: %s\nBackup: %s", restore_group, restore_path, backup_path),
      defaults.confirm_modify
  )
  then
    if redo_snapshot then
      vim.fn.delete(redo_snapshot)
    end
    restore_guard_clear()
    return
  end

  if vim.fn.filereadable(restore_path) == 1 then
    safe_backup = next_backup_path(restore_path)
    if not safe_backup then
      safe_backup = restore_path .. ".dbcp.before"
    end
    local ok, backup_err = vim.loop.fs_rename(restore_path, safe_backup)
    if not ok then
      if redo_snapshot then
        vim.fn.delete(redo_snapshot)
      end
      restore_guard_clear()
      show_error("Failed to backup current group file before restore: " .. tostring(backup_err))
      return
    end
  end

  local ok, restore_err = copy_file(backup_path, restore_path)
  if not ok then
    if safe_backup then
      local rollback_ok, rollback_err = vim.loop.fs_rename(safe_backup, restore_path)
      if not rollback_ok then
        show_error(
          "Failed to restore current file after restore failure: "
            .. tostring(rollback_err)
            .. ". Backup at "
            .. tostring(safe_backup)
        )
      end
    end
    if redo_snapshot then
      vim.fn.delete(redo_snapshot)
    end
    restore_guard_clear()
    show_error("Failed to restore group from backup: " .. tostring(restore_err))
    return
  end

  if safe_backup then
    vim.fn.delete(safe_backup)
  end

  if mode == "undo" then
    consume_backup_entry(backup_path)
    restore_redo_push({
      undo_path = backup_path,
      redo_path = redo_snapshot,
      group = restore_group,
    })
  elseif mode == "redo" then
    if undo_backup_path then
      record_backup_path(undo_backup_path, { clear_redo = false })
    end
  end

  restore_guard_clear()
  if mode == "undo" then
    show_info("Undid restore for: " .. restore_group)
  elseif mode == "redo" then
    show_info("Redid restore for: " .. restore_group)
  else
    show_info("Restored group from backup: " .. restore_group)
  end

  if type(opts.on_success) == "function" then
    opts.on_success()
    return
  end
  open_file(restore_path)
end

function M.open_connection_group(group)
  M.open(group)
end

function M.open_profile(name)
  M.open(name)
end

function M.setup(opts)
  local options = vim.tbl_extend("force", defaults, opts or {})
  options.backup_dir = resolve_backup_dir(options.backup_dir)
  defaults = options
  group_icons = normalize_icons(options)
  group_label_map = options.group_labels or options.profile_labels or {}

  local command_profile = "DBConnections"

  local function run_open(cmd)
    local raw = vim.trim(cmd.args)
    local args = vim.split(raw, "%s+", { trimempty = true })

    if #args == 0 then
      M.pick_profile({})
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

    if mode == "restore" or mode == "recover" then
      M.restore_group(args[2])
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
      show_info(":DBConnections restore      Restore latest backup from trash (latest first)")
      show_info(":DBConnections recover      Same as restore")
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
      vim.list_extend(candidates, { "all", "add", "new", "edit", "restore", "recover", "help", "?" })
      return filter_starts_with(candidates, arg_lead)
    end

    if parts[2] == "edit" then
      return filter_starts_with(group_command_candidates(), arg_lead)
    end

    if parts[2] == "add" or parts[2] == "new" then
      return {}
    end

    if parts[2] == "restore" or parts[2] == "recover" then
      return {}
    end

    return filter_starts_with(group_command_candidates(), arg_lead)
  end

  vim.api.nvim_create_user_command(command_profile, run_open, {
    nargs = "*",
    complete = connection_command_complete,
    desc = "Open DB connection picker (`:DBConnections [all|<group>|add|edit <group>|restore|help`)",
  })
end

return M
