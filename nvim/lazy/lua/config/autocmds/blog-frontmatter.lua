-- Jekyll 블로그 포스트(`*posts/*.md`)에 frontmatter 템플릿을 깔고
-- 저장 시 `updated:` 타임스탬프를 갱신한다. vimwiki와는 무관하다.

local function stamp_kr()
  return os.date("%Y-%m-%d %H:%M:%S ") .. "+0900"
end

local function NewTemplate()
  local line_count = vim.api.nvim_buf_line_count(0)
  if line_count > 1 then
    return
  end

  local t = {
    "---",
    "title       : ",
    "description : ",
    "date        : " .. stamp_kr(),
    "updated     : " .. stamp_kr(),
    "categories  : []",
    "tags        : []",
    "pin         : false",
    "hidden      : false",
    "---",
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, t)
  vim.cmd("normal! G$")
  vim.notify("new blog post created", vim.log.levels.INFO, { title = "Blog" })
end

local function LastModified()
  if not vim.bo.modified then
    return
  end

  local bufnr = 0
  local total = vim.api.nvim_buf_line_count(bufnr)
  local n = math.min(10, total)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, n, false)
  local ts = stamp_kr()
  local changed = false

  for i, line in ipairs(lines) do
    if line:match("^%s*updated%s*:") then
      local indent = line:match("^(%s*)") or ""
      lines[i] = indent .. "updated     : " .. ts
      changed = true
      break
    end
  end

  if changed then
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(bufnr, 0, n, false, lines)
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
end

local group = vim.api.nvim_create_augroup("blog_frontmatter", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = group,
  pattern = "*posts/*.md",
  callback = NewTemplate,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = "*posts/*.md",
  callback = LastModified,
})
