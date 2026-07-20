-- pickers + command registration: file finder (:Docs) + full-text grep (:DocsGrep)
local M = {}

local config = require("user.docs.config")
local float = require("user.util.float")
local pins = require("user.docs.pins")

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

-- unpinning a folder asks first (folders are coarse, deliberate pins). the picker is
-- closed before the prompt so its insert-mode input can't swallow the y/n, then `reopen`
-- rebuilds the view. pinning and file-unpinning are cheap, so they skip the prompt.
local function confirm_unpin_folder(picker, path, reopen)
  picker:close()
  vim.schedule(function()
    if vim.fn.confirm(("Unpin folder?\n%s"):format(vim.fn.fnamemodify(path, ":~")), "&Yes\n&No", 2) == 1 then
      pins.toggle(path)
    end
    reopen()
  end)
end

-- shared pin behaviour for the file-style pickers. adds <C-p> (toggle pin of the
-- current path) to actions/win, and returns the picker opts that make pinned paths
-- show a 📌 and sort to the top (score boost); frecency orders everything else.
-- `reopen` rebuilds this view after a confirmed folder unpin.
local function pin_opts(actions, win, reopen)
  actions.docs_pin = function(picker)
    local item = picker:current()
    if not item then
      return
    end
    local path = Snacks.picker.util.path(item)
    if vim.fn.isdirectory(path) == 1 and pins.is_pinned(path) then
      confirm_unpin_folder(picker, path, reopen)
    else
      pins.toggle(path)
      picker:refresh()
    end
  end
  win.input.keys["<c-p>"] = { "docs_pin", mode = { "i", "n" } }
  return {
    matcher = { frecency = true },
    transform = function(item)
      if item.file and pins.is_pinned(item.file) then
        -- in :Docs the pinned finder (source 1) already emits every pin; drop the
        -- files finder's (source > 1) duplicate so a pin never shows twice.
        if item.source_id and item.source_id > 1 then
          return false
        end
        item.score_add = (item.score_add or 0) + 1000
      end
      return item
    end,
    format = function(item, picker)
      local ret = require("snacks.picker.format").file(item, picker)
      if item.file and pins.is_pinned(item.file) then
        table.insert(ret, 1, { "📌 ", "Special" })
      end
      return ret
    end,
  }
end

-- file picker over `dirs`; open the chosen file (md → float, else buffer).
-- <C-o> steps back one level (threaded into the float too).
local function browse_files(dirs, on_back)
  local actions, win = back_keys(on_back)
  local opts = pin_opts(actions, win, function()
    browse_files(dirs, on_back)
  end)
  opts.dirs = dirs
  opts.confirm = function(picker, item)
    picker:close()
    if item then
      open_file(Snacks.picker.util.path(item), function()
        browse_files(dirs, on_back)
      end)
    end
  end
  opts.actions = actions
  opts.win = win
  Snacks.picker.files(opts)
end

-- finder yielding every pinned path as an item. the files finder only walks `dirs`
-- and never emits folders, so pins that live outside `dirs` (or are folders) would be
-- invisible without this. the files finder's duplicate of an in-`dirs` pin is dropped
-- in the transform above (by source_id), so each pin shows exactly once.
local function pinned_finder()
  local items = {}
  for _, path in ipairs(pins.list()) do
    local is_dir = vim.fn.isdirectory(path) == 1
    items[#items + 1] = { file = path, text = path, dir = is_dir and path or nil }
  end
  return items
end

-- top-level :Docs view: pinned folders + files, then the frecency-sorted file list.
-- reuses Snacks' real files finder (fd/rg/find) via multi(), just prepending the pins.
-- confirm opens files in the viewer and browses into folders; <C-p> pins/unpins.
local function browse_all(dirs, on_back)
  local Finder = require("snacks.picker.core.finder")
  local files_finder = require("snacks.picker.config").finder("files")
  local actions, win = back_keys(on_back)
  local opts = pin_opts(actions, win, function()
    browse_all(dirs, on_back)
  end)
  opts.finder = Finder.multi({ pinned_finder, files_finder })
  opts.dirs = dirs
  opts.confirm = function(picker, item)
    picker:close()
    if item then
      local path = Snacks.picker.util.path(item)
      if vim.fn.isdirectory(path) == 1 then
        browse_files({ path }, function()
          browse_all(dirs, on_back)
        end)
      else
        open_file(path, function()
          browse_all(dirs, on_back)
        end)
      end
    end
  end
  opts.actions = actions
  opts.win = win
  Snacks.picker.pick(opts)
end

-- subdirs=true root: pick one of its immediate subfolders, then browse that folder.
-- on_back: <C-o> from the folder chooser steps up (to the root chooser).
local function browse_subdirs(root, on_back)
  local items = {}
  for entry, kind in vim.fs.dir(root.dir) do
    if kind == "directory" then
      local dir = root.dir .. "/" .. entry
      local marker = pins.is_pinned(dir) and "📌 " or ""
      items[#items + 1] = { text = marker .. entry, name = entry, dir = dir, file = dir }
    end
  end
  if #items == 0 then
    return vim.notify(("docs: no subfolders in %s"):format(root.name), vim.log.levels.WARN, { title = "docs" })
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  local actions, win = back_keys(on_back)
  actions.docs_pin = function(picker)
    local item = picker:current()
    if not item then
      return
    end
    if pins.is_pinned(item.dir) then
      confirm_unpin_folder(picker, item.dir, function()
        browse_subdirs(root, on_back)
      end)
    else
      pins.toggle(item.dir)
      picker:close()
      browse_subdirs(root, on_back) -- reopen so the 📌 marker refreshes
    end
  end
  win.input.keys["<c-p>"] = { "docs_pin", mode = { "i", "n" } }
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

-- root chooser: pinned folders on top (📌), then browsable roots. pick a root to narrow
-- into it, or a pinned folder to browse it directly. <C-p> unpins the selected pin.
-- on_back reopens whatever view opened this chooser.
local function browse_roots(on_back)
  local pinned, roots = {}, {}
  for _, path in ipairs(pins.list()) do
    if vim.fn.isdirectory(path) == 1 then
      pinned[#pinned + 1] = { text = "📌 " .. vim.fn.fnamemodify(path, ":t"), dir = path, file = path, pinned = true }
    end
  end
  for _, root in ipairs(config.roots()) do
    if root.name and not root.grep_only then
      roots[#roots + 1] = { text = root.name, root = root, file = root.dir }
    end
  end
  if #pinned == 0 and #roots == 0 then
    return config.warn_no_roots()
  end
  table.sort(pinned, function(a, b)
    return a.text < b.text
  end)
  table.sort(roots, function(a, b)
    return a.text < b.text
  end)
  local items = {}
  vim.list_extend(items, pinned)
  vim.list_extend(items, roots)

  local actions, win = back_keys(on_back)
  actions.docs_pin = function(picker)
    local item = picker:current()
    if item and item.pinned then
      confirm_unpin_folder(picker, item.dir, function()
        browse_roots(on_back) -- rebuild so the unpinned folder drops off the list
      end)
    end
  end
  win.input.keys["<c-p>"] = { "docs_pin", mode = { "i", "n" } }

  Snacks.picker.pick({
    items = items,
    format = "text",
    title = "docs roots",
    confirm = function(picker, item)
      picker:close()
      if item then
        if item.root then
          open_root(item.root, function()
            browse_roots(on_back)
          end)
        else
          browse_files({ item.dir }, function()
            browse_roots(on_back)
          end)
        end
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
  local show_all, show_roots
  show_all = function()
    browse_all(dirs, show_roots)
  end
  show_roots = function()
    browse_roots(show_all)
  end
  show_all()
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
