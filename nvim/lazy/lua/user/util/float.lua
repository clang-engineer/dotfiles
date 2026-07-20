-- floating window viewer + tmux refocus (used by user.docs)
local M = {}

local function tmux_move(direction)
  return function()
    vim.fn.system("tmux select-pane -" .. direction)
  end
end

-- opts.on_back (optional): <C-o> closes the float and calls it — steps back to the
-- picker the doc was opened from, mirroring the picker→chooser back one level up.
function M.open(path, opts)
  opts = opts or {}
  local keys = {
    q = "close",
    ["<C-h>"] = { tmux_move("L"), desc = "tmux left" },
    ["<C-j>"] = { tmux_move("D"), desc = "tmux down" },
    ["<C-k>"] = { tmux_move("U"), desc = "tmux up" },
    ["<C-l>"] = { tmux_move("R"), desc = "tmux right" },
  }
  if opts.on_back then
    keys["<C-o>"] = {
      function(self)
        self:close()
        vim.schedule(opts.on_back)
      end,
      desc = "docs: back to picker",
    }
  end

  local win = Snacks.win({
    file = path,
    width = 0.85,
    height = 0.85,
    border = "rounded",
    wo = { wrap = false, spell = false },
    keys = keys,
  })

  -- render-markdown is off globally (noisy while editing); enable it just for this
  -- read-only viewer so referenced docs render prettily. buf-scoped, global untouched.
  if win.buf and vim.bo[win.buf].filetype == "markdown" then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(win.buf) then
        vim.api.nvim_buf_call(win.buf, function()
          require("render-markdown.api").buf_enable()
        end)
      end
    end)
  end

  -- refocus the float when returning to nvim after moving tmux panes
  local aug = vim.api.nvim_create_augroup("user_float_refocus", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = aug,
    callback = function()
      if win.win and vim.api.nvim_win_is_valid(win.win) then
        vim.api.nvim_set_current_win(win.win)
      else
        vim.api.nvim_del_augroup_by_id(aug)
      end
    end,
  })
end

return M
