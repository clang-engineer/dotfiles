-- toolbox 빠른 뷰어: $TOOLBOX_DIR 전체를 nvim에서 검색/열람
--   :Toolbox          → 파일 피커 (repo 전체 퍼지 검색 + 미리보기, Enter로 플로팅 열람)
--   :Toolbox <주제>   → cheatsheets/<주제>.md 바로 플로팅 열람 (탭 자동완성)
--   :ToolboxGrep      → repo 전체 본문 grep 검색
-- 의존성 없음: 이미 깔린 snacks + render-markdown 재사용.

local function toolbox_dir()
  local toolbox = vim.env.TOOLBOX_DIR
  if not toolbox or toolbox == "" then
    return nil
  end
  local dir = vim.fs.normalize(toolbox)
  return vim.fn.isdirectory(dir) == 1 and dir or nil
end

-- 플로팅 창에 파일을 띄움 (q로 닫기, 마크다운은 render-markdown이 렌더)
local function open_float(path)
  Snacks.win({
    file = path,
    width = 0.85,
    height = 0.85,
    border = "rounded",
    wo = { wrap = false, spell = false },
    keys = { q = "close" },
  })
end

local function warn_no_toolbox()
  vim.notify("TOOLBOX_DIR 가 설정되지 않았습니다.", vim.log.levels.WARN, { title = "toolbox" })
end

-- 파일 피커 (repo 전체) → Enter 시 플로팅 열람
local function pick()
  local root = toolbox_dir()
  if not root then
    return warn_no_toolbox()
  end
  Snacks.picker.files({
    cwd = root,
    confirm = function(picker, item)
      picker:close()
      if item then
        open_float(root .. "/" .. item.file)
      end
    end,
  })
end

vim.api.nvim_create_user_command("Toolbox", function(opts)
  if opts.args ~= "" then
    -- 인자 = cheatsheet 이름 → 바로 열기
    local root = toolbox_dir()
    local path = root and (root .. "/cheatsheets/" .. opts.args .. ".md")
    if path and vim.fn.filereadable(path) == 1 then
      open_float(path)
    else
      vim.notify("cheatsheet 없음: " .. opts.args, vim.log.levels.WARN, { title = "toolbox" })
    end
  else
    pick()
  end
end, {
  nargs = "?",
  complete = function(arglead)
    local root = toolbox_dir()
    if not root then
      return {}
    end
    local names = {}
    for _, f in ipairs(vim.fn.globpath(root .. "/cheatsheets", "*.md", false, true)) do
      local name = vim.fn.fnamemodify(f, ":t:r")
      if name ~= "README" and vim.startswith(name, arglead) then
        names[#names + 1] = name
      end
    end
    return names
  end,
  desc = "toolbox 검색 (인자 없으면 전체 피커, 인자는 cheatsheet 바로 열기)",
})

vim.api.nvim_create_user_command("ToolboxGrep", function()
  local root = toolbox_dir()
  if not root then
    return warn_no_toolbox()
  end
  Snacks.picker.grep({ cwd = root })
end, { desc = "toolbox 전체 본문 grep 검색" })
