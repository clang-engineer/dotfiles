-- 사용자 옵션 머지 + dir 정규화
local M = {}

local defaults = {
  dir = nil, -- nil 이면 TOOLBOX_DIR 환경변수 사용
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
end

-- 정규화된 절대 경로 반환. 없거나 디렉토리 아니면 nil.
function M.get_dir()
  local raw = options.dir or vim.env.TOOLBOX_DIR
  if not raw or raw == "" then
    return nil
  end
  local dir = vim.fs.normalize(raw)
  return vim.fn.isdirectory(dir) == 1 and dir or nil
end

function M.warn_no_dir()
  vim.notify(
    "toolbox: dir 가 설정되지 않았거나 디렉토리가 존재하지 않습니다.\n"
      .. "setup({ dir = ... }) 으로 지정하거나 TOOLBOX_DIR 환경변수를 설정하세요.",
    vim.log.levels.WARN,
    { title = "toolbox" }
  )
end

return M
