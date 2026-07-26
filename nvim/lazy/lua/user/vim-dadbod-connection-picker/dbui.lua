local M = {}

local function close()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == "dbui" then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end

  if vim.fn.exists(":DBUIClose") == 2 then
    pcall(vim.cmd, "silent! DBUIClose")
  end
end

local function reset_state()
  if vim.fn.exists("*db_ui#reset_state") == 1 then
    pcall(vim.fn["db_ui#reset_state"])
  end
end

function M.open(connections, show_warn)
  if vim.fn.exists(":DBUI") ~= 2 then
    show_warn("vim-dadbod-ui is not available. Run :Lazy load vim-dadbod-ui first.")
    return
  end

  vim.g.dbs = connections
  vim.schedule(function()
    close()
    reset_state()
    vim.cmd("DBUI")
  end)
end

return M
