-- backup-undo.lua: backup, swap, and undo file settings
-- Prevent file loss and keep persistent undo history

local data_dir = vim.fn.stdpath("data")

-- Enable persistent undo (keep undo history across Neovim restarts)
vim.opt.undofile = true
vim.opt.undodir = data_dir .. "/undo"

-- Swap file settings (for crash recovery)
vim.opt.swapfile = true
vim.opt.directory = data_dir .. "/swap//"

-- Backup file settings
vim.opt.backup = false -- Don't create a backup file on write (git handles it)
vim.opt.writebackup = true -- Temporary backup only during write (safety)

-- Auto-create directories
local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

ensure_dir(vim.opt.undodir:get()[1])
ensure_dir(vim.opt.directory:get()[1])

-- Undo retention settings
vim.opt.undolevels = 10000 -- number of undo steps
vim.opt.undoreload = 10000 -- max lines to save for undo on buffer reload
