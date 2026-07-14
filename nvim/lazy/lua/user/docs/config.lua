-- resolve knowledge-base roots (search targets) from env or setup opts
local M = {}

-- default roots, in order. grep_only roots are searched by :DocsGrep only.
local default_specs = {
  { env = "VAULT_DIR" },
  { env = "DEVKIT_DIR" },
  { env = "BLOG_DIR", grep_only = true },
}

local function build_default_roots()
  local roots = {}
  for _, spec in ipairs(default_specs) do
    local raw = vim.env[spec.env]
    if raw and raw ~= "" then
      local dir = vim.fs.normalize(raw)
      if vim.fn.isdirectory(dir) == 1 then
        table.insert(roots, { dir = dir, grep_only = spec.grep_only or false })
      end
    end
  end
  return roots
end

-- setup({ roots = { { dir = "...", grep_only = true }, ... } }) overrides the env default.
local options = {}

function M.setup(opts)
  options = vim.tbl_deep_extend("force", {}, opts or {})
end

function M.roots()
  return options.roots or build_default_roots()
end

-- dirs browsable in the :Docs picker (grep_only excluded)
function M.file_roots()
  local dirs = {}
  for _, root in ipairs(M.roots()) do
    if not root.grep_only then
      table.insert(dirs, root.dir)
    end
  end
  return dirs
end

-- dirs searched by :DocsGrep (every root)
function M.grep_roots()
  local dirs = {}
  for _, root in ipairs(M.roots()) do
    table.insert(dirs, root.dir)
  end
  return dirs
end

function M.warn_no_roots()
  vim.notify(
    "docs: no search roots found.\n"
      .. "Set VAULT_DIR / DEVKIT_DIR / BLOG_DIR, or pass setup({ roots = ... }).",
    vim.log.levels.WARN,
    { title = "docs" }
  )
end

return M
