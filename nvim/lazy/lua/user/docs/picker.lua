-- pickers: file finder (:Docs) + full-text grep (:DocsGrep) across the roots
local M = {}

local config = require("user.docs.config")
local open = require("user.docs.open")

function M.open(name)
  local dirs = config.file_roots(name)
  if #dirs == 0 then
    return name and config.warn_unknown_root(name, config.root_names(false)) or config.warn_no_roots()
  end
  Snacks.picker.files({
    dirs = dirs,
    confirm = function(picker, item)
      picker:close()
      if item then
        open.dispatch(Snacks.picker.util.path(item))
      end
    end,
  })
end

function M.grep(name)
  local dirs = config.grep_roots(name)
  if #dirs == 0 then
    return name and config.warn_unknown_root(name, config.root_names(true)) or config.warn_no_roots()
  end
  Snacks.picker.grep({ dirs = dirs })
end

return M
