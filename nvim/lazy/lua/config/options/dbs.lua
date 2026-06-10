-- dbs/ 하위 모든 .lua 파일을 자동 스캔해서 합침.
-- 새 그룹 추가: dbs/그룹명.lua 만들면 자동 포함.
-- 비활성화: 파일 이름을 .lua.disabled로 바꾸거나 삭제.
--
-- 프로젝트별로 일부만 보고 싶다면 (exrc 활용):
--   1) ~/.config/nvim 등 init 파일에 `vim.o.exrc = true` 추가 (한 번만)
--   2) 프로젝트 루트에 .nvim.lua 만들고 아래처럼 오버라이드:
--        vim.g.dbs = require("config.options.dbs.snuh")
--      또는 여러 그룹 합치기:
--        local function concat(...)
--          local r = {}
--          for _, t in ipairs({...}) do vim.list_extend(r, t) end
--          return r
--        end
--        vim.g.dbs = concat(
--          require("config.options.dbs.snuh"),
--          require("config.options.dbs.shine")
--        )
--   3) 첫 실행 시 :trust 명령으로 해당 .nvim.lua 신뢰 등록.

local result = {}
local files = vim.api.nvim_get_runtime_file("lua/config/options/dbs/*.lua", true)
table.sort(files)
for _, path in ipairs(files) do
  local mod = path:match("lua/(.+)%.lua$"):gsub("/", ".")
  for _, entry in ipairs(require(mod)) do
    table.insert(result, entry)
  end
end
return result
