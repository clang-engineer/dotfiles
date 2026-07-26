local M = {}

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

local icon_styles = {
  ascii = {
    folder_expanded = "[-]",
    folder_collapsed = "[+]",
    open_all = ">>",
  },
  emoji = {
    folder_expanded = "📂",
    folder_collapsed = "📁",
    open_all = "🚀",
  },
  nerd = {
    folder_expanded = "",
    folder_collapsed = "",
    open_all = "+",
  },
}

local command_name = "DBPicker"
local group_icons = {}
local group_labels = {}

local function normalize_icons(options)
  local style = icon_styles[options.icon_style or "ascii"] or icon_styles.ascii
  local merged = vim.tbl_extend("force", style, options.icons or {})
  return {
    folder_expanded = merged.folder_expanded or style.folder_expanded,
    folder_collapsed = merged.folder_collapsed or style.folder_collapsed,
    open_all = merged.open_all or style.open_all,
  }
end

function M.setup(opts)
  defaults = vim.tbl_extend("force", defaults, opts or {})
  command_name = defaults.command_name or command_name
  group_icons = normalize_icons(defaults)
  group_labels = defaults.group_labels or {}
end

function M.set_backup_dir(path)
  defaults.backup_dir = path
end

function M.get()
  return defaults
end

function M.command_name()
  return command_name
end

function M.icons()
  return group_icons
end

function M.group_label(group)
  if type(group) ~= "string" or group == "" then
    return group
  end
  local label = group_labels[group]
  return type(label) == "string" and label ~= "" and label or group
end

return M
