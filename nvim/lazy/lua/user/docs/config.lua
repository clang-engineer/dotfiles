-- resolve knowledge-base roots (search targets) from setup opts
local M = {}

-- Each root spec:
-- dir       = path with $ENV and ~ expanded; roots that don't resolve are skipped.
-- name      = alias used to scope a search: :Docs vault / :DocsGrep devkit
-- grep_only = searched by :DocsGrep only (excluded from the :Docs file picker).
-- scoped    = searched only when named (excluded from the no-arg "all"), for subfolder
--             aliases that would otherwise double-count with their parent. :Docs analysis
local function build_roots(specs)
  local roots = {}
  for _, spec in ipairs(specs) do
    local dir = vim.fs.normalize(spec.dir)
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(roots, {
        name = spec.name,
        dir = dir,
        grep_only = spec.grep_only or false,
        scoped = spec.scoped or false,
      })
    end
  end
  return roots
end

-- setup({ roots = { { name = "notes", dir = "$VAULT_DIR/notes", scoped = true }, ... } })
local options = {}

function M.setup(opts)
  options = vim.tbl_deep_extend("force", {}, opts or {})
end

function M.roots()
  return build_roots(options.roots or {})
end

-- collect root dirs matching `include`. with a name → just that root (scoped or not);
-- without a name → the default "all" set (scoped subfolder aliases excluded).
local function collect(include, name)
  local dirs = {}
  for _, root in ipairs(M.roots()) do
    local pass = name and (root.name == name) or (not name and not root.scoped)
    if pass and include(root) then
      table.insert(dirs, root.dir)
    end
  end
  return dirs
end

-- dirs browsable in the :Docs picker (grep_only excluded), optionally one root by name
function M.file_roots(name)
  return collect(function(root)
    return not root.grep_only
  end, name)
end

-- dirs searched by :DocsGrep (every root), optionally one root by name
function M.grep_roots(name)
  return collect(function()
    return true
  end, name)
end

-- root names for command completion; grep-only roots included only for :DocsGrep
function M.root_names(include_grep_only)
  local names = {}
  for _, root in ipairs(M.roots()) do
    if root.name and (include_grep_only or not root.grep_only) then
      table.insert(names, root.name)
    end
  end
  return names
end

function M.warn_no_roots()
  vim.notify(
    "docs: no search roots found. Pass setup({ roots = { { dir = ... } } }).",
    vim.log.levels.WARN,
    { title = "docs" }
  )
end

function M.warn_unknown_root(name, valid)
  vim.notify(
    ("docs: no root named %q. available: %s"):format(name, table.concat(valid, ", ")),
    vim.log.levels.WARN,
    { title = "docs" }
  )
end

return M
