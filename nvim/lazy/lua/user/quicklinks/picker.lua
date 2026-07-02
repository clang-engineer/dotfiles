-- 통합 픽커: quicklinks.md 항목 + cheatsheets/*.md
local M = {}

local config = require("user.quicklinks.config")
local store = require("user.quicklinks.store")
local open = require("user.quicklinks.open")

local KIND_ICON = {
  url = "🔗",
  cheatsheet = "📘",
  file = "📄",
}

local function classify(target)
  if target:match("^https?://") then
    return "url"
  end
  return "file"
end

local function build_items(dir)
  local items = {}

  -- quicklinks.md 항목
  for _, entry in ipairs(store.load(dir)) do
    table.insert(items, {
      text = entry.name,
      target = entry.target,
      tags = entry.tags,
      kind = classify(entry.target),
    })
  end

  -- cheatsheets/*.md 자동 인덱싱 (README 제외)
  for _, file in ipairs(vim.fn.globpath(dir .. "/cheatsheets", "*.md", false, true)) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    if name ~= "README" then
      table.insert(items, {
        text = name,
        target = "cheatsheets/" .. name .. ".md",
        tags = {},
        kind = "cheatsheet",
      })
    end
  end

  return items
end

local function format_item(item)
  local icon = KIND_ICON[item.kind] or " "
  local tag_str = (#item.tags > 0) and ("  #" .. table.concat(item.tags, " #")) or ""
  return {
    { icon .. " ", "Special" },
    { item.text, "Normal" },
    { tag_str, "Comment" },
  }
end

function M.open()
  local dir = config.get_dir()
  if not dir then
    return config.warn_no_dir()
  end

  local items = build_items(dir)
  if #items == 0 then
    vim.notify("quicklinks: 항목이 없습니다.", vim.log.levels.INFO, { title = "quicklinks" })
    return
  end

  Snacks.picker.pick({
    source = "quicklinks",
    items = items,
    format = format_item,
    confirm = function(picker, item)
      picker:close()
      if item then
        open.dispatch(item.target)
      end
    end,
  })
end

return M
