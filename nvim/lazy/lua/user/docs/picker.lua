-- pickers: file finder (:Docs) + full-text grep (:DocsGrep) across the roots
local M = {}

local config = require("user.docs.config")
local open = require("user.docs.open")

function M.open()
  local dirs = config.file_roots()
  if #dirs == 0 then
    return config.warn_no_roots()
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

function M.grep()
  local dirs = config.grep_roots()
  if #dirs == 0 then
    return config.warn_no_roots()
  end
  Snacks.picker.grep({ dirs = dirs })
end

return M
