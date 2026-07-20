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

-- <C-o> in a picker reopens the previous view (browser-style back). every view is
-- reached with an on_back thunk that reopens whoever opened it, so <C-o> retraces the
-- exact path in (doc → files → folder → root → files …). we always map the key even
-- when on_back is nil, so it can't leak to vim's i_CTRL-O and collapse the picker.
local function back_keys(on_back)
  local actions = {
    docs_back = function(picker)
      if on_back then
        picker:close()
        on_back()
      end
    end,
  }
  local win = { input = { keys = { ["<c-o>"] = { "docs_back", mode = { "i", "n" } } } } }
  return actions, win
end

-- file picker over `dirs`; open the chosen file (md → float, else buffer).
-- on_back (optional): <C-o> steps back one level. the same on_back is threaded into
-- the opened float, so the whole stack (doc → files → subdir → root) walks back on <C-o>.
local function browse_files(dirs, on_back)
  local actions, win = back_keys(on_back)
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
    actions = actions,
    win = win,
  })
end

-- subdirs=true root: pick one of its immediate subfolders, then browse that folder.
-- on_back: <C-o> from the folder chooser steps up (to the root chooser).
local function browse_subdirs(root, on_back)
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
  local actions, win = back_keys(on_back)
  Snacks.picker.pick({
    items = items,
    format = "text",
    title = root.name,
    confirm = function(picker, item)
      picker:close()
      if item then
        browse_files({ item.dir }, function()
          browse_subdirs(root, on_back)
        end)
      end
    end,
    actions = actions,
    win = win,
  })
end

-- open a root the user picked in the root chooser. on_back reopens the root chooser,
-- so <C-o> out of the chosen root's files/folders lands back on the root list.
local function open_root(root, on_back)
  if root.subdirs then
    browse_subdirs(root, on_back)
  else
    browse_files({ root.dir }, on_back)
  end
end

-- root chooser: list browsable roots; pick one to narrow into it (subdirs root → its
-- folder chooser, else its file list). on_back reopens whatever view opened this chooser.
local function browse_roots(on_back)
  local items = {}
  for _, root in ipairs(config.roots()) do
    if root.name and not root.grep_only then
      items[#items + 1] = { text = root.name, root = root, file = root.dir }
    end
  end
  if #items == 0 then
    return config.warn_no_roots()
  end
  table.sort(items, function(a, b)
    return a.text < b.text
  end)
  local actions, win = back_keys(on_back)
  Snacks.picker.pick({
    items = items,
    format = "text",
    title = "docs roots",
    confirm = function(picker, item)
      picker:close()
      if item then
        open_root(item.root, function()
          browse_roots(on_back)
        end)
      end
    end,
    actions = actions,
    win = win,
  })
end

-- entry point. the initial view and the root chooser are each other's <C-o> target,
-- so `:Docs` ⇄ root chooser toggles, and drilling into a root walks back out the same way.
local function open(name)
  local root = name and config.find_root(name)
  if root and root.subdirs then
    local show_subdirs, show_roots
    show_subdirs = function()
      browse_subdirs(root, show_roots)
    end
    show_roots = function()
      browse_roots(show_subdirs)
    end
    return show_subdirs()
  end
  local dirs = config.file_roots(name)
  if #dirs == 0 then
    return name and config.warn_unknown_root(name, config.root_names(false)) or config.warn_no_roots()
  end
  local show_files, show_roots
  show_files = function()
    browse_files(dirs, show_roots)
  end
  show_roots = function()
    browse_roots(show_files)
  end
  show_files()
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
