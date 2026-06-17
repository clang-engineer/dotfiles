-- 사용자 옵션 머지 + getter
local M = {}

local defaults = {
  jdtls = "21", -- jdtls 실행에 사용할 JDK 메이저 버전
  gradle = "11", -- Gradle 빌드에 사용할 JDK 메이저 버전
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
end

function M.get(key)
  return options[key]
end

return M
