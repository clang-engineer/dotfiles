-- pickers + command registration: file finder (:Docs) + full-text grep (:DocsGrep)
local M = {}

local config = require("user.docs.config")
local float = require("user.util.float")

-- open a selected file: *.md in a floating viewer, other text files in a buffer.
-- on_back (md only): <C-o> in the float steps back to the picker it was opened from.
-- buffers keep <C-o> as vim's jumplist (you've left the viewer into editing).
local function open_file(path, on_back)
  if path:match("%.md$") then
    float.open(path, { on_back = on_back })
  else
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
end

-- file picker over `dirs`; open the chosen file (md → float, else buffer).
-- on_back (optional): <C-o> closes this picker and calls it — steps back to the
-- subdir chooser when the picked folder was wrong. the same <C-o> back is threaded
-- into the opened float, so it reopens this picker (one consistent step-back stack).
local function browse_files(dirs, on_back)
  Snacks.picker.files({
    dirs = dirs,
    confirm = function(picker, item)
      picker:close()
      if item then
        open_file(Snacks.picker.util.path(item), function()
          browse_files(dirs, on_back)
        end)
      end
    end,
    actions = on_back and {
      docs_back = function(picker)
        picker:close()
        on_back()
      end,
    } or nil,
    win = on_back and { input = { keys = { ["<c-o>"] = { "docs_back", mode = { "i", "n" } } } } } or nil,
  })
end

-- subdirs=true root: pick one of its immediate subfolders, then browse that folder
local function browse_subdirs(root)
  local items = {}
  for entry, kind in vim.fs.dir(root.dir) do
    if kind == "directory" then
      local dir = root.dir .. "/" .. entry
      items[#items + 1] = { text = entry, dir = dir, file = dir }
    end
  end
  if #items == 0 then
    return vim.notify(("docs: no subfolders in %s"):format(root.name), vim.log.levels.WARN, { title = "docs" })
  end
  table.sort(items, function(a, b)
    return a.text < b.text
  end)
  Snacks.picker.pick({
    items = items,
    format = "text",
    title = root.name,
    confirm = function(picker, item)
      picker:close()
      if item then
        browse_files({ item.dir }, function()
          browse_subdirs(root)
        end)
      end
    end,
  })
end

local function open(name)
  local root = name and config.find_root(name)
  if root and root.subdirs then
    return browse_subdirs(root)
  end
  local dirs = config.file_roots(name)
  if #dirs == 0 then
    return name and config.warn_unknown_root(name, config.root_names(false)) or config.warn_no_roots()
  end
  browse_files(dirs)
end

local function grep(name)
  local dirs = config.grep_roots(name)
  if #dirs == 0 then
    return name and config.warn_unknown_root(name, config.root_names(true)) or config.warn_no_roots()
  end
  Snacks.picker.grep({ dirs = dirs })
end

function M.register()
  vim.api.nvim_create_user_command("Docs", function(cmd)
    open(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return config.root_names(false)
    end,
    desc = "browse docs across the knowledge roots (optionally one root by name)",
  })

  vim.api.nvim_create_user_command("DocsGrep", function(cmd)
    grep(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return config.root_names(true)
    end,
    desc = "full-text grep across the knowledge roots (optionally one root by name)",
  })
end

return M
