-- dbs/ 하위 그룹 로더.
-- 새 그룹 추가: dbs/그룹명.lua 만들면 .all()에 자동 포함.
-- 비활성화: 파일 이름을 .lua.disabled로 바꾸거나 삭제.
--
-- 프로젝트별로 일부만 보고 싶다면 (exrc 활용):
--   1) ~/.config/nvim 등 init 파일에 `vim.o.exrc = true` 추가 (한 번만)
--   2) 프로젝트 루트에 .nvim.lua 만들고 오버라이드:
--        vim.g.dbs = require("config.options.dbs").pick("snuh", "shine")
--   3) 첫 실행 시 :trust 명령으로 해당 .nvim.lua 신뢰 등록.

local M = {}

function M.all()
  local result = {}
  local files = vim.api.nvim_get_runtime_file("lua/config/options/dbs/*.lua", true)
  table.sort(files)
  for _, path in ipairs(files) do
    local mod = path:gsub("\\", "/"):match("lua/(.+)%.lua$"):gsub("/", ".")
    vim.list_extend(result, require(mod))
  end
  return result
end

function M.pick(...)
  local result = {}
  for _, name in ipairs({ ... }) do
    vim.list_extend(result, require("config.options.dbs." .. name))
  end
  return result
end

return M
