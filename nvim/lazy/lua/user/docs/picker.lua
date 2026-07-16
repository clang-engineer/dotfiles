-- pickers: file finder (:Docs) + full-text grep (:DocsGrep) across the roots
local M = {}

local config = require("user.docs.config")
local open = require("user.docs.open")

-- file picker over `dirs`; open the chosen file (md → float, else buffer).
-- on_back (optional): <C-o> closes this picker and calls it — steps back to the
-- subdir chooser when the picked folder was wrong.
local function browse_files(dirs, on_back)
  Snacks.picker.files({
    dirs = dirs,
    confirm = function(picker, item)
      picker:close()
      if item then
        open.dispatch(Snacks.picker.util.path(item))
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
      items[#items + 1] = { text = entry, dir = root.dir .. "/" .. entry }
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

function M.open(name)
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

function M.grep(name)
  local dirs = config.grep_roots(name)
  if #dirs == 0 then
    return name and config.warn_unknown_root(name, config.root_names(true)) or config.warn_no_roots()
  end
  Snacks.picker.grep({ dirs = dirs })
end

return M
