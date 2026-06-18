-- 선택 항목 타입별 동작 분기
-- URL → vim.ui.open (브라우저)
-- *.md → 플로팅 윈도우
-- 그 외 로컬 파일/디렉토리 → vim.ui.open (외부 앱)
local M = {}

local float = require("quicklinks.float")
local config = require("quicklinks.config")

local function is_url(target)
  return target:match("^https?://") ~= nil
end

local function resolve(target, dir)
  local path = vim.fs.normalize(target)
  -- 상대 경로면 toolbox dir 기준
  if not path:match("^/") then
    path = (dir or "") .. "/" .. path
  end
  return path
end

function M.dispatch(target)
  if is_url(target) then
    vim.ui.open(target)
    return
  end

  local path = resolve(target, config.get_dir())
  local is_md = path:match("%.md$") ~= nil
  local readable = vim.fn.filereadable(path) == 1
  local is_dir = vim.fn.isdirectory(path) == 1

  if is_md and readable then
    float.open(path)
  elseif readable or is_dir then
    vim.ui.open(path)
  else
    vim.notify(
      "quicklinks: 경로를 찾을 수 없음: " .. target,
      vim.log.levels.WARN,
      { title = "quicklinks" }
    )
  end
end

return M
