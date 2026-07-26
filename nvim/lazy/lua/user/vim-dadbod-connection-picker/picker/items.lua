local M = {}

local config = require("user.vim-dadbod-connection-picker.config")
local group_data = require("user.vim-dadbod-connection-picker.groups.store")
local ui = require("user.vim-dadbod-connection-picker.ui")
local util = require("user.vim-dadbod-connection-picker.util")

local function display_url(url)
  return ui.truncate_for_display(ui.mask_url(url))
end

local function group_preview(group, connections)
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

local function connection_preview(group, conn)
  return table.concat({
    string.format("Group: %s", group),
    string.format("Connection: %s", conn.name),
    string.format("URL: %s", ui.mask_url(conn.url)),
  }, "\n")
end

function M.groups(groups, expanded)
  local rows = {}
  local icons = config.icons()
  for _, group in ipairs(util.sorted_keys(groups)) do
    local is_expanded = expanded[group] == true
    local count = #(groups[group] or {})
    rows[#rows + 1] = {
      text = string.format("%s %s (%d)", is_expanded and icons.folder_expanded or icons.folder_collapsed, group, count),
      kind = "group",
      group = group,
      expanded = is_expanded,
      preview = { text = group_preview(group, groups[group]) },
    }
    if is_expanded and count > 1 then
      rows[#rows + 1] = {
        text = string.format("  %s Open all (%d): %s", icons.open_all, count, group),
        kind = "open_all",
        group = group,
        preview = { text = string.format("Group: %s\nOpen all %d connections at once.", group, count) },
      }
    end
    if is_expanded and count == 0 then
      rows[#rows + 1] = {
        text = "  (no connections)",
        kind = "empty_connection",
        group = group,
        preview = {
          text = string.format(
            "Group: %s\nNo connections configured.\nTip: use :%s edit %s",
            group,
            config.command_name(),
            group
          ),
        },
      }
    end
    if is_expanded then
      for index, conn in ipairs(groups[group] or {}) do
        rows[#rows + 1] = {
          text = string.format("    %s (%s)", conn.name, display_url(conn.url)),
          kind = "connection",
          group = group,
          connection = conn,
          connection_index = index,
          preview = { text = connection_preview(group, conn) },
        }
      end
    end
  end
  return rows
end

function M.match_set(groups)
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

function M.empty()
  local defaults = config.get()
  local placeholder = type(defaults.group_placeholders) == "table" and defaults.group_placeholders[1] or nil
  local sample_name = type(placeholder) == "table" and placeholder.name or "sample"
  if type(sample_name) ~= "string" or sample_name == "" then
    sample_name = "sample"
  end
  local sample_url = type(placeholder) == "table" and placeholder.url or "postgresql://..."
  if type(sample_url) ~= "string" or sample_url == "" then
    sample_url = "postgresql://..."
  end
  local dir = group_data.connections_dir()
  local filename = group_data.normalize_group_name(sample_name) or "sample"
  return {
    {
      text = "+ Add first connection",
      kind = "setup",
      preview = { text = "No DB connections found.\nPress <CR> to enter a group name, connection name, and URL." },
    },
    {
      text = "Example: " .. dir .. "/" .. filename .. ".lua",
      kind = "hint",
      preview = {
        text = dir
          .. "/"
          .. filename
          .. ".lua\nreturn { { name = "
          .. vim.inspect(vim.trim(sample_name))
          .. ", url = "
          .. vim.inspect(ui.mask_url(sample_url))
          .. " } }",
      },
    },
  }
end

return M
