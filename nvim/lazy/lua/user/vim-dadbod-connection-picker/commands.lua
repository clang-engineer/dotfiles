local M = {}
local util = require("user.vim-dadbod-connection-picker.util")

local SUPPORTED_SUBCOMMANDS = {
  "all",
  "add",
  "edit",
  "restore",
  "help",
  "?",
}

function M.setup(opts)
  opts = opts or {}

  local command_name = opts.command_name or "DBPicker"
  local open_group_picker = opts.open_group_picker or function()
  end
  local open_group = opts.open or function()
  end
  local edit_group = opts.edit_group or function()
  end
  local create_group = opts.create_group or function()
  end
  local restore_group = opts.restore_group or function()
  end
  local show_info = opts.show_info or function(message)
    vim.notify(message, vim.log.levels.INFO)
  end
  local show_warn = opts.show_warn or function(message)
    vim.notify(message, vim.log.levels.WARN)
  end
  local available_groups = opts.group_candidates or function()
    return {}
  end

  local function show_usage()
    local groups = available_groups()
    show_info("Usage:")
    show_info(":" .. command_name .. "           Open group picker")
    show_info(":" .. command_name .. " <group>    Open one group directly")
    show_info(":" .. command_name .. " add <group>   Create a new group file")
    show_info(":" .. command_name .. " restore      Restore latest backup from history")
    show_info(":" .. command_name .. " all        Open all groups")
    show_info(":" .. command_name .. " edit <group> Open group file")
    show_info("Available groups: " .. table.concat(groups, ", "))
  end

  local function handle_group_picker_command(cmd)
    local raw = vim.trim(cmd.args)
    local args = vim.split(raw, "%s+", { trimempty = true })

    if #args == 0 then
      open_group_picker({})
      return
    end

    local subcommand = args[1]
    if subcommand == "all" then
      open_group("all", nil, { prefix = false })
      return
    end

    if subcommand == "edit" then
      local group = args[2]
      if not group then
        show_warn("Specify group name: :" .. command_name .. " " .. subcommand .. " <group>")
        return
      end
      edit_group(group)
      return
    end

    if subcommand == "restore" then
      restore_group(args[2])
      return
    end

    if subcommand == "add" then
      local group = args[2]
      if not group then
        show_warn("Specify group name: :" .. command_name .. " " .. subcommand .. " <group>")
        return
      end
      create_group(group)
      return
    end

    if subcommand == "help" or subcommand == "?" then
      show_usage()
      return
    end

    open_group(subcommand, nil, { prefix = false })
  end

  local function connection_group_candidates()
    return available_groups()
  end

  local function connection_command_complete(arg_lead, cmd_line)
    local parts = vim.split(vim.trim(cmd_line), "%s+", { trimempty = true })
    local groups = available_groups()

    if #parts <= 1 then
      local candidates = vim.deepcopy(groups)
      vim.list_extend(candidates, vim.deepcopy(SUPPORTED_SUBCOMMANDS))
      return util.filter_starts_with(candidates, arg_lead)
    end

    if parts[2] == "edit" then
      return util.filter_starts_with(connection_group_candidates(), arg_lead)
    end

    if parts[2] == "add" then
      return {}
    end

    if parts[2] == "restore" then
      return {}
    end

    return util.filter_starts_with(connection_group_candidates(), arg_lead)
  end

  vim.api.nvim_create_user_command(
    command_name,
    handle_group_picker_command,
    {
      nargs = "*",
      complete = connection_command_complete,
      desc = "Open DB connection picker (`:"
        .. command_name
        .. " [all|<group>|add|edit <group>|restore|help`)"
    }
  )
end

return M
