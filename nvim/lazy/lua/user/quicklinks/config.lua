-- merge user options + normalize dir
local M = {}

local defaults = {
  dir = nil, -- if nil, use the VAULT_DIR environment variable
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
end

-- Returns a normalized absolute path. nil if missing or not a directory.
function M.get_dir()
  local raw = options.dir or vim.env.VAULT_DIR
  if not raw or raw == "" then
    return nil
  end
  local dir = vim.fs.normalize(raw)
  return vim.fn.isdirectory(dir) == 1 and dir or nil
end

function M.warn_no_dir()
  vim.notify(
    "quicklinks: dir is not set or the directory does not exist.\n"
      .. "Specify it with setup({ dir = ... }) or set the VAULT_DIR environment variable.",
    vim.log.levels.WARN,
    { title = "quicklinks" }
  )
end

return M
