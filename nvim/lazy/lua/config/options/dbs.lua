-- dbs/ 하위 모든 .lua 파일을 자동 스캔해서 합침.
-- 새 그룹 추가: dbs/그룹명.lua 만들면 자동 포함.
-- 비활성화: 파일 이름을 .lua.disabled로 바꾸거나 삭제.

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
