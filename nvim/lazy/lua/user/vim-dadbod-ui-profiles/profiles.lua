local M = {}

local function list_connection_files()
  local files = vim.api.nvim_get_runtime_file("lua/user/vim-dadbod-ui-profiles/connections/*.lua", true)
  table.sort(files)
  return files
end

local function default_profiles_dir()
  return vim.fn.stdpath("config") .. "/lua/user/vim-dadbod-ui-profiles/connections"
end

local function profile_file(profile)
  if not profile or profile == "" then
    return nil
  end

  for _, path in ipairs(list_connection_files()) do
    if profile_name_from_path(path) == profile then
      return path
    end
  end

  return default_profiles_dir() .. "/" .. profile .. ".lua"
end

local function profile_name_from_path(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

local function load_connections(path)
  local loader = loadfile(path)
  if not loader then
    return nil
  end

  local ok, result = pcall(loader)
  if not ok or type(result) ~= "table" then
    return nil
  end

  return result
end

local function normalize_connection(conn)
  if type(conn) ~= "table" then
    return nil
  end
  if type(conn.name) ~= "string" or conn.name == "" then
    return nil
  end
  if type(conn.url) ~= "string" or conn.url == "" then
    return nil
  end
  return {
    name = conn.name,
    url = conn.url,
  }
end

local function build_profile_metadata()
  local profiles = {}
  local seen = {}

  for _, path in ipairs(list_connection_files()) do
    local profile = profile_name_from_path(path)
    if not seen[profile] then
      seen[profile] = true
      profiles[profile] = {
        path = path,
        connections = {},
      }
    end

    for _, item in ipairs(load_connections(path) or {}) do
      local normalized = normalize_connection(item)
      if normalized then
        table.insert(profiles[profile].connections, normalized)
      end
    end
  end

  return profiles
end

local function read_profile_connections(profile)
  local path = profile_file(profile)
  if not path then
    return {}
  end
  local file_connection = load_connections(path)
  local result = {}
  if type(file_connection) == "table" then
    for _, item in ipairs(file_connection) do
      local normalized = normalize_connection(item)
      if normalized then
        table.insert(result, normalized)
      end
    end
  end
  return result, path
end

local function write_profile_file(path, connections)
  local lines = { "return {" }
  for _, conn in ipairs(connections or {}) do
    local name = type(conn.name) == "string" and conn.name or ""
    local url = type(conn.url) == "string" and conn.url or ""
    lines[#lines + 1] = string.format("  { name = %q, url = %q },", name, url)
  end
  lines[#lines + 1] = "}"

  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(lines, path)
end

local function build_profiles()
  local profiles = {}
  local seen = {}

  for _, path in ipairs(list_connection_files()) do
    local profile = profile_name_from_path(path)
    if not seen[profile] then
      seen[profile] = true
      profiles[profile] = {}
    end

    for _, item in ipairs(load_connections(path) or {}) do
      local normalized = normalize_connection(item)
      if normalized then
        table.insert(profiles[profile], normalized)
      end
    end
  end

  return profiles
end

local function ordered_profiles(profiles)
  local names = {}
  for name in pairs(profiles) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

local function ordered_profile_keys(profile_meta)
  return ordered_profiles(profile_meta)
end

local function normalize_picker_layout(layout)
  if layout == "float" then
    return { preset = "dropdown" }
  end
  return layout
end

local picker_layout = "dropdown"
local use_profile_prefix = false
local profile_label_map = {}

local function resolve_profile_label(profile)
  if type(profile) ~= "string" or profile == "" then
    return profile
  end

  local mapped = profile_label_map[profile]
  if type(mapped) == "string" and mapped ~= "" then
    return mapped
  end

  return profile
end

local function apply_profile_prefix(profile, conn)
  if not use_profile_prefix then
    return conn
  end

  if type(conn) ~= "table" then
    return conn
  end

  if type(conn.name) ~= "string" or conn.url == nil then
    return conn
  end

  if conn.name == "" or conn.name:match("^%[[^%]]+%] ") then
    return conn
  end

  local label = resolve_profile_label(profile)

  if type(label) ~= "string" or label == "" then
    return conn
  end

  return vim.tbl_extend("force", conn, {
    name = string.format("[%s] %s", label, conn.name),
  })
end

function M.connections(target, opts)
  local profiles = build_profiles()
  local result = {}
  local force_prefix = opts and opts.prefix

  local function with_prefix(profile, conn)
    if force_prefix == nil then
      return apply_profile_prefix(profile, conn)
    end

    if not force_prefix then
      return conn
    end

    return apply_profile_prefix(profile, conn)
  end

  if target and target ~= "all" then
    local selected = profiles[target]
    if type(selected) ~= "table" then
      return nil
    end
    for _, conn in ipairs(selected) do
      table.insert(result, with_prefix(target, conn))
    end
    return result
  end

  for _, name in ipairs(ordered_profiles(profiles)) do
    for _, conn in ipairs(profiles[name] or {}) do
      table.insert(result, with_prefix(name, conn))
    end
  end

  return result
end

local function contains_profile(profiles, name)
  for _, value in ipairs(profiles) do
    if value == name then
      return true
    end
  end
  return false
end

local defaults = {
  command_prefix = "DBUI",
  picker_layout = "dropdown",
  prefix_by_profile = false,
  profile_labels = {},
}

local function truncate_for_display(value)
  local max_len = 72
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len - 3) .. "..."
end

local function build_profile_items(profiles, expanded)
  local items = {}
  local ordered = ordered_profiles(profiles)

  for _, profile in ipairs(ordered) do
    local is_expanded = expanded[profile] == true
    local glyph = is_expanded and "📂" or "📁"
    local count = #(profiles[profile] or {})

    table.insert(items, {
      text = string.format("%s %s (%d)", glyph, profile, count),
      kind = "profile",
      profile = profile,
      expanded = is_expanded,
    })

    if is_expanded then
        table.insert(items, {
          text = string.format("  📂 open profile %s", profile),
          kind = "open_all",
          profile = profile,
        })

      for _, conn in ipairs(profiles[profile] or {}) do
        local detail = string.format("    %s (%s)", conn.name, truncate_for_display(conn.url))
        table.insert(items, {
          text = detail,
          kind = "connection",
          profile = profile,
          connection = conn,
        })
      end
    end
  end

  return items
end

local function format_menu_prompt()
  return ""
end

local function format_manage_prompt()
  return ""
end

local function safe_input(title, default_value)
  return vim.fn.input({ prompt = title, default = default_value or "" })
end

local function ask_connection_input(profile, existing)
  local name = safe_input(("Connection name [%s]: "):format(profile), existing and existing.name)
  if name == "" then
    return nil
  end

  local url = safe_input("Connection URL: ", existing and existing.url)
  if url == "" then
    return nil
  end

  return {
    name = name,
    url = url,
  }
end

local function add_connection(profile, path)
  local connection = ask_connection_input(profile)
  if not connection then
    return false
  end

  local connections = read_profile_connections(profile)
  table.insert(connections, connection)
  write_profile_file(path, connections)
  return true
end

local function update_connection(profile, path, index, current_connection)
  local connections = read_profile_connections(profile)
  if not connections[index] then
    return false
  end

  local connection = ask_connection_input(profile, current_connection)
  if not connection then
    return false
  end

  connections[index] = connection
  write_profile_file(path, connections)
  return true
end

local function delete_connection(profile, path, index)
  local connections = read_profile_connections(profile)
  if not connections[index] then
    return false
  end

  local confirm = vim.fn.confirm(("Delete %q?"):format(connections[index].name), "&Yes\n&No")
  if confirm ~= 1 then
    return false
  end

  table.remove(connections, index)
  write_profile_file(path, connections)
  return true
end

local function manage_items(profile_meta)
  local items = {}
  local ordered = ordered_profiles(profile_meta)

  for _, profile in ipairs(ordered) do
    local data = profile_meta[profile]
    local count = #(data.connections or {})

    table.insert(items, {
      text = string.format("[%s] (%d)", profile, count),
      kind = "profile_manage",
      profile = profile,
      path = data.path,
    })

    for index, conn in ipairs(data.connections or {}) do
      table.insert(items, {
        text = string.format("  %s (%s)", conn.name, truncate_for_display(conn.url)),
        kind = "connection_manage",
        profile = profile,
        path = data.path,
        connection = conn,
        connection_index = index,
      })
    end
  end

  return items
end

local function copy_or_preview(profile, conn)
  if vim.clipboard and vim.clipboard.get and vim.clipboard.set then
    vim.fn.setreg("+", conn.url)
  else
    vim.fn.setreg("", conn.url)
  end
  vim.notify(string.format("[%s] %s copied: %s", profile, conn.name, conn.url), vim.log.levels.INFO)
end

local function open_connection(profile, conn)
  if type(conn) ~= "table" or type(conn.url) ~= "string" then
    return false
  end

  local name = conn.name and conn.name ~= "" and conn.name or profile
  return M.open({ { name = conn.name, url = conn.url } }, name)
end

local function run_picker(profiles, expanded, opts)
  local function items()
    return build_profile_items(profiles, expanded)
  end

  if #items() == 0 then
    local profiles_dir = default_profiles_dir()
    vim.notify("No DB profile found. Add profile files as Lua tables in: " .. profiles_dir, vim.log.levels.WARN)
    vim.notify(
      "Example: " .. profiles_dir .. "/office.lua -> return { { name = \"office\", url = \"postgresql://...\" } }",
      vim.log.levels.INFO
    )
    return
  end

  local ok_snacks, snacks = pcall(require, "snacks.picker")
  if not ok_snacks then
    if opts and opts.fallback and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    vim.notify("snacks.picker is not available. Please install folke/snacks.nvim.", vim.log.levels.WARN)
    return
  end

  local function handle_select(picker, item)
    if not item then
      return
    end

    if item.kind == "profile" then
      expanded[item.profile] = not (expanded[item.profile] == true)
      picker:refresh()
      return
    end

    if item.kind == "open_all" then
      picker:close()
      M.open(item.profile, nil, { prefix = opts and opts.prefix })
      return
    end

    if item.kind == "connection" then
      picker:close()
      open_connection(item.profile, item.connection)
      return
    end
  end

  local actions = {
    dbui_toggle = function(picker)
      local item = picker:current()
      if not item or item.kind ~= "profile" then
        return
      end

      expanded[item.profile] = not (expanded[item.profile] == true)
      picker:refresh()
    end,
    dbui_open = function(picker)
      handle_select(picker, picker:current())
    end,
    dbui_open_all = function(picker)
      local item = picker:current()
      if not item then
        return
      end

      if item.kind == "profile" then
        expanded[item.profile] = true
        picker:refresh()
        M.open(item.profile, nil, { prefix = opts and opts.prefix })
        return
      end

      if item.kind ~= "open_all" then
        return
      end

      picker:close()
      M.open(item.profile, nil, { prefix = opts and opts.prefix })
    end,
    dbui_preview = function(picker)
      local item = picker:current()
      if not item or item.kind ~= "connection" then
        return
      end

      copy_or_preview(item.profile, item.connection)
    end,
    dbui_copy = function(picker)
      local item = picker:current()
      if not item or item.kind ~= "connection" then
        return
      end

      copy_or_preview(item.profile, item.connection)
      picker:close()
    end,
  }

  local picker = nil
  if type(snacks) == "function" then
    picker = snacks
  elseif type(snacks) == "table" and type(snacks.pick) == "function" then
    picker = snacks.pick
  elseif type(snacks) == "table" and type(snacks.picker) == "table" and type(snacks.picker.pick) == "function" then
    picker = snacks.picker.pick
  end
  if not picker or type(picker) ~= "function" then
    if opts and opts.fallback and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    vim.notify("snacks.picker API is not available in this environment.", vim.log.levels.WARN)
    return
  end

  local win = {
    input = {
      keys = {
        ["<Tab>"] = { "dbui_toggle", mode = { "i", "n" } },
        ["<CR>"] = { "dbui_open", mode = { "i", "n" } },
        ["o"] = { "dbui_open_all", mode = { "i", "n" } },
        ["<C-y>"] = { "dbui_copy", mode = { "i", "n" } },
      },
    },
    list = {
      keys = {
        ["<Tab>"] = { "dbui_toggle", mode = { "n", "x" } },
        ["<CR>"] = { "dbui_open", mode = { "n", "x" } },
        ["o"] = { "dbui_open_all", mode = { "n", "x" } },
        ["<C-y>"] = { "dbui_copy", mode = { "n", "x" } },
      },
    },
  }
  -- Keep Enter as toggle for profile/open-all and open DBUI for connection.
  -- Reopen the picker when a non-terminal action happens.
  picker({
    title = "DB profiles",
    finder = items,
    format = "text",
    prompt = format_menu_prompt(),
    preview = "",
    actions = actions,
    focus = "list",
    layout = opts and opts.layout or picker_layout,
    win = win,
    confirm = handle_select,
  })
end

local function run_manage_picker(profile_meta, opts)
  local function items()
    return manage_items(profile_meta)
  end

  if #items() == 0 then
    vim.notify("No DB profiles found", vim.log.levels.WARN)
    return
  end

  local ok_snacks, snacks = pcall(require, "snacks.picker")
  if not ok_snacks then
    if opts and opts.fallback and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    vim.notify("snacks.picker is not available. Please install folke/snacks.nvim.", vim.log.levels.WARN)
    return
  end

  local picker
  if type(snacks) == "function" then
    picker = snacks
  elseif type(snacks) == "table" and type(snacks.pick) == "function" then
    picker = snacks.pick
  elseif type(snacks) == "table" and type(snacks.picker) == "table" and type(snacks.picker.pick) == "function" then
    picker = snacks.picker.pick
  end

  if not picker or type(picker) ~= "function" then
    if opts and opts.fallback and type(opts.fallback) == "function" then
      return opts.fallback()
    end
    vim.notify("snacks.picker API is not available in this environment.", vim.log.levels.WARN)
    return
  end

  local function refresh()
    local refreshed = build_profile_metadata()
    for profile, data in pairs(refreshed) do
      profile_meta[profile] = profile_meta[profile] or data
      profile_meta[profile].path = data.path
      profile_meta[profile].connections = data.connections
    end
    for profile, data in pairs(profile_meta) do
      if not refreshed[profile] then
        profile_meta[profile] = nil
      end
    end
    run_manage_picker(profile_meta, opts)
  end

  local function close_and_refresh(picker, action_name, action)
    picker:close()
    vim.schedule(function()
      local ok, result = xpcall(action, function(message)
        return debug.traceback(("DBUIProfile action '%s' failed: %s"):format(action_name, tostring(message)), 2)
      end)
      if not ok then
        vim.notify(result, vim.log.levels.ERROR)
        return
      end

      if result then
        refresh()
      end
    end)
  end

  local function open_profile_file(path)
    if not path then
      return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end

  local actions = {
    dbui_manage_open = function(current_picker)
      local item = current_picker:current()
      if not item then
        return
      end

      if item.kind == "connection_manage" then
        current_picker:close()
        open_connection(item.profile, item.connection)
        return
      end

      if item.path then
        current_picker:close()
        open_profile_file(item.path)
      end
    end,
    dbui_manage_add = function(current_picker)
      local item = current_picker:current()
      if not item or item.kind ~= "profile_manage" then
        return
      end

      local _, saved_path = read_profile_connections(item.profile)
      local target = item.path or saved_path
      if not target then
        return
      end

      close_and_refresh(current_picker, "dbui_manage_add", function()
        return add_connection(item.profile, target)
      end)
    end,
    dbui_manage_edit = function(current_picker)
      local item = current_picker:current()
      if not item or item.kind ~= "connection_manage" then
        return
      end

      close_and_refresh(current_picker, "dbui_manage_edit", function()
        return update_connection(item.profile, item.path, item.connection_index, item.connection)
      end)
    end,
    dbui_manage_delete = function(current_picker)
      local item = current_picker:current()
      if not item or item.kind ~= "connection_manage" then
        return
      end

      close_and_refresh(current_picker, "dbui_manage_delete", function()
        return delete_connection(item.profile, item.path, item.connection_index)
      end)
    end,
    dbui_manage_edit_file = function(current_picker)
      local item = current_picker:current()
      if not item or not item.path then
        return
      end

      current_picker:close()
      open_profile_file(item.path)
    end,
  }

  picker({
    title = "DB profile manager",
    finder = items,
    format = "text",
    prompt = format_manage_prompt(),
    preview = "",
    actions = actions,
    layout = opts and opts.layout or picker_layout,
    win = {
      input = {
        keys = {
          ["<CR>"] = { "dbui_manage_open", mode = { "i", "n" } },
          ["o"] = { "dbui_manage_open", mode = { "i", "n" } },
          ["i"] = { "dbui_manage_edit_file", mode = { "i", "n" } },
          ["a"] = { "dbui_manage_add", mode = { "i", "n" } },
          ["e"] = { "dbui_manage_edit", mode = { "i", "n" } },
          ["d"] = { "dbui_manage_delete", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<CR>"] = { "dbui_manage_open", mode = { "n", "x" } },
          ["o"] = { "dbui_manage_open", mode = { "n", "x" } },
          ["i"] = { "dbui_manage_edit_file", mode = { "n", "x" } },
          ["a"] = { "dbui_manage_add", mode = { "n", "x" } },
          ["e"] = { "dbui_manage_edit", mode = { "n", "x" } },
          ["d"] = { "dbui_manage_delete", mode = { "n", "x" } },
        },
      },
    },
  })
end

local function show_connection_preview(profile, conn)
  vim.notify(string.format("[%s] %s - %s", profile, conn.name, conn.url), vim.log.levels.INFO)
end

function M.pick_profile()
  local profiles = build_profiles()
  local expanded = {}
  for _, profile in ipairs(ordered_profiles(profiles)) do
    expanded[profile] = false
  end
  local layout = picker_layout

  local function refresh()
    run_picker(profiles, expanded, {
      layout = layout,
      prefix = false,
      refresh = refresh,
      fallback = function()
        show_connection_preview("system", { name = "", url = "" })
      end,
    })
  end

  refresh()
end

function M.pick_group()
  M.pick_profile()
end

function M.manage_profiles()
  local profile_meta = build_profile_metadata()
  local layout = picker_layout
  local function refresh()
    run_manage_picker(profile_meta, {
      layout = layout,
      fallback = function()
        vim.notify("Unable to open connection manager with snacks picker", vim.log.levels.WARN)
      end,
    })
  end

  refresh()
end

local function close_dbui()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "dbui" then
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

function M.open(profile, label_override, opts)
  local list
  local label
  local connection_opts = {
    prefix = opts and opts.prefix,
  }

  if type(profile) == "table" then
    list = profile
    label = label_override or "selected"
  else
    list = M.connections(profile, connection_opts)
    if not list then
      vim.notify("No connections found for profile: " .. tostring(profile), vim.log.levels.WARN)
      return
    end
    label = profile == "all" and "all" or (profile or "all")
  end

  if not list or vim.tbl_isempty(list) then
    vim.notify("No DB connections found to open", vim.log.levels.WARN)
    return
  end

  M.current_profile = label

  if vim.fn.exists(":DBUI") ~= 2 then
    vim.notify("vim-dadbod-ui is not available. Run :Lazy load vim-dadbod-ui first.", vim.log.levels.WARN)
    return
  end

  vim.g.dbs = list

  vim.schedule(function()
    close_dbui()
    reset_dbui_state()
    vim.cmd("DBUI")
  end)
end

function M.open_profile(name)
  M.open(name)
end

function M.edit_profile(profile)
  local _, path = read_profile_connections(profile)
  if not path then
    vim.notify("No profile file found: " .. tostring(profile), vim.log.levels.WARN)
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.setup(opts)
  local options = vim.tbl_extend("force", defaults, opts or {})
  picker_layout = normalize_picker_layout(options.picker_layout)
  use_profile_prefix = options.prefix_by_profile == true
  profile_label_map = options.profile_labels or {}
  local prefix = options.command_prefix
  local command_profile = prefix .. "Profile"

  local function run_open(cmd)
    local raw = vim.trim(cmd.args)
    local args = vim.split(raw, "%s+", { trimempty = true })

    if #args == 0 then
      M.pick_profile()
      return
    end

    local mode = args[1]
    if mode == "all" then
      M.open("all", nil, { prefix = use_profile_prefix })
      return
    end

    if mode == "manage" or mode == "editor" or mode == "edit" then
      local profile = args[2]
      if mode == "manage" then
        M.manage_profiles()
        return
      end

      if not profile then
        local command_name = command_profile
        vim.notify("Specify profile name: :" .. command_name .. " " .. mode .. " <profile>", vim.log.levels.WARN)
        return
      end

      M.edit_profile(profile)
      return
    end

    M.open(mode, nil, { prefix = false })
  end

  local function profile_candidates()
    local profiles = ordered_profiles(build_profiles())
    if not contains_profile(profiles, "all") then
      table.insert(profiles, "all")
    end
    return profiles
  end

  local function profile_or_mode_candidates()
    local candidates = profile_candidates()
    table.insert(candidates, "manage")
    table.insert(candidates, "edit")
    table.insert(candidates, "editor")
    return candidates
  end

  local function profile_command_complete(arg_lead, cmd_line)
    local parts = vim.split(vim.trim(cmd_line), "%s+", { trimempty = true })

    if #parts <= 1 then
      return vim.tbl_filter(function(item)
        return vim.startswith(item, arg_lead)
      end, { "manage", "edit", "editor" })
    end

    local first = parts[2]
    if first == "edit" or first == "editor" then
      return vim.tbl_filter(function(item)
        return vim.startswith(item, arg_lead)
      end, profile_candidates())
    end

    if first == "manage" then
      return {}
    end

    return vim.tbl_filter(function(item)
      return vim.startswith(item, arg_lead)
    end, profile_candidates())
  end

  vim.api.nvim_create_user_command(command_profile, run_open, {
    nargs = "*",
    complete = profile_command_complete,
    desc = "Open DBUI with profile, manage, or edit profile file",
  })

  if prefix ~= "DBUI" then
    vim.api.nvim_create_user_command("DBUIGroup", run_open, {
      nargs = "?",
      complete = profile_command_complete,
      desc = "Backward-compatible alias for DBUIProfile",
    })
  end

end

return M
