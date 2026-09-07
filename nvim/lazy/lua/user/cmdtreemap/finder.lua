local M = {}

M._open = {}

local function preview_text(rel)
  local t = {}
  local w = 40
  local sep = string.rep("─", w)

  t[#t + 1] = sep
  t[#t + 1] = "  " .. rel.from .. " → " .. rel.to
  t[#t + 1] = sep
  t[#t + 1] = ""

  if rel.why and rel.why ~= "" then
    t[#t + 1] = "  ■ Why"
    t[#t + 1] = "  " .. rel.why
    t[#t + 1] = ""
  end

  t[#t + 1] = "  ■ Problem"
  t[#t + 1] = "  " .. rel.problem
  t[#t + 1] = ""

  if rel.boundary and rel.boundary ~= "" then
    t[#t + 1] = "  ■ Boundary"
    t[#t + 1] = "  " .. rel.boundary
    t[#t + 1] = ""
  end

  if rel.relation and rel.relation ~= "" then
    t[#t + 1] = "  ■ Relation"
    t[#t + 1] = "  " .. rel.relation
    t[#t + 1] = ""
  end

  if rel.install and rel.install ~= "" then
    t[#t + 1] = "  ■ Install"
    t[#t + 1] = "  $ " .. rel.install
    t[#t + 1] = ""
  end

  if rel.tldr and rel.tldr ~= "" then
    t[#t + 1] = "  ■ TLDR"
    t[#t + 1] = "  tldr " .. rel.tldr
    t[#t + 1] = ""
  end

  if rel.url and rel.url ~= "" then
    t[#t + 1] = "  ■ URL"
    t[#t + 1] = "  " .. rel.url
    t[#t + 1] = ""
  end

  t[#t + 1] = sep
  t[#t + 1] = "  o:open  y:url  Y:install"
  t[#t + 1] = sep

  return table.concat(t, "\n")
end

local function cat_preview_text(cat)
  local t = {}
  local w = 40
  local sep = string.rep("─", w)

  t[#t + 1] = sep
  t[#t + 1] = "  " .. cat.name
  t[#t + 1] = sep
  t[#t + 1] = ""
  t[#t + 1] = "  " .. cat.why
  t[#t + 1] = ""
  t[#t + 1] = sep
  t[#t + 1] = "  " .. #cat.relations .. " tools"
  t[#t + 1] = "  l/Enter: expand"
  t[#t + 1] = sep

  return table.concat(t, "\n")
end

function M.finder(opts, ctx)
  local data = require("user.cmdtreemap.data")
  local items = {}

  for ci, cat in ipairs(data.categories) do
    local cat_key = cat.name
    local cat_open = M._open[cat_key] or false
    local cat_item = {
      text = cat.name .. " (" .. #cat.relations .. ")",
      file = "",
      dir = true,
      open = cat_open,
      last = ci == #data.categories,
      _cat = cat_key,
      _why = cat.why,
      preview = { text = cat_preview_text(cat), ft = "text" },
    }
    items[#items + 1] = cat_item

    if cat_open then
      -- group relations by "from", every from becomes a folder
      local groups = {}
      for _, rel in ipairs(cat.relations) do
        local key = rel.from
        if not groups[key] then
          groups[key] = {}
        end
        groups[key][#groups[key] + 1] = rel
      end

      local group_keys = {}
      for k in pairs(groups) do
        group_keys[#group_keys + 1] = k
      end
      table.sort(group_keys)

      local gi = 0
      for _, from_cmd in ipairs(group_keys) do
        local rels = groups[from_cmd]
        gi = gi + 1
        local is_last = gi == #group_keys

        local sub_key = cat_key .. ":" .. from_cmd
        local sub_open = M._open[sub_key] or false
        local sub_item = {
          text = from_cmd,
          file = "",
          dir = true,
          open = sub_open,
          last = is_last,
          parent = cat_item,
          _cat = sub_key,
          _parent_cat = cat_key,
        }
        items[#items + 1] = sub_item

        if sub_open then
          for ri, rel in ipairs(rels) do
            items[#items + 1] = {
              text = rel.to,
              file = "",
              parent = sub_item,
              last = ri == #rels,
              preview = { text = preview_text(rel), ft = "text" },
              _rel = rel,
            }
          end
        end
      end
    end
  end

  return items
end

function M.format(item, picker)
  local ret = {}
  local a = Snacks.picker.util.align

  if item.parent then
    vim.list_extend(ret, Snacks.picker.format.tree(item, picker))
  end

  if picker.opts.icons.files.enabled ~= false then
    local name = item.text
    local cat = item.dir and "directory" or "file"
    local icon, hl = Snacks.util.icon(name, cat, {
      fallback = picker.opts.icons.files,
    })
    if item.dir and item.open then
      icon = picker.opts.icons.files.dir_open
    end
    icon = a(icon, picker.opts.formatters.file.icon_width or 2)
    ret[#ret + 1] = { icon, hl, virtual = true }
  end

  local base_hl = item.dir and "SnacksPickerDirectory" or "SnacksPickerFile"
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { item.text, base_hl }

  return ret
end

local function refresh(picker)
  picker.list:set_target()
  picker:find()
end

function M.down(picker)
  local item = picker:current()
  if not item then
    return true
  end
  if item.dir and item.open then
    M._open[item._cat] = false
    refresh(picker)
  end
  return true
end

function M.confirm(picker)
  local item = picker:current()
  if not item then
    return true
  end
  if item.dir then
    M._open[item._cat] = not item.open
    refresh(picker)
  end
  return true
end

function M.toggle(picker)
  local item = picker:current()
  if not item then
    return true
  end
  if item.dir then
    M._open[item._cat] = not item.open
    refresh(picker)
  end
  return true
end

function M.expand(picker)
  local item = picker:current()
  if not item then
    return true
  end
  if item.dir and not item.open then
    M._open[item._cat] = true
    refresh(picker)
  end
  return true
end

function M.collapse(picker)
  local item = picker:current()
  if not item then
    return true
  end

  if not item.dir and item.parent then
    -- on leaf: move to parent folder (no collapse)
    for it, idx in picker:iter() do
      if it == item.parent then
        picker.list:view(idx)
        break
      end
    end
  elseif item.dir and item.open then
    -- on open folder: collapse it, cursor stays
    M._open[item._cat] = false
    refresh(picker)
    for it, idx in picker:iter() do
      if it._cat == item._cat then
        picker.list:view(idx)
        break
      end
    end
  elseif item.dir and not item.open then
    -- on collapsed folder: move to parent folder
    if item._parent_cat then
      for it, idx in picker:iter() do
        if it._cat == item._parent_cat then
          picker.list:view(idx)
          break
        end
      end
    end
  end

  return true
end

function M.expand_all()
  local data = require("user.cmdtreemap.data")
  for _, cat in ipairs(data.categories) do
    M._open[cat.name] = true
    for _, rel in ipairs(cat.relations) do
      M._open[cat.name .. ":" .. rel.from] = true
    end
  end
end

function M.collapse_all()
  local data = require("user.cmdtreemap.data")
  for _, cat in ipairs(data.categories) do
    M._open[cat.name] = false
    for _, rel in ipairs(cat.relations) do
      M._open[cat.name .. ":" .. rel.from] = false
    end
  end
end

function M.copy_url(picker)
  local item = picker:current()
  if not item then
    return true
  end
  local rel = item._rel
  if rel and rel.url then
    vim.fn.setreg("+", rel.url)
    vim.notify("URL copied", vim.log.levels.INFO)
  end
  return true
end

function M.copy_install(picker)
  local item = picker:current()
  if not item then
    return true
  end
  local rel = item._rel
  if rel and rel.install then
    vim.fn.setreg("+", rel.install)
    vim.notify("Install copied", vim.log.levels.INFO)
  end
  return true
end

function M.open_url(picker)
  local item = picker:current()
  if not item then
    return true
  end
  local rel = item._rel
  if rel and rel.url then
    vim.fn.jobstart({ "open", rel.url }, { detach = true })
  end
  return true
end

return M
