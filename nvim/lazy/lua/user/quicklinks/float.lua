-- floating window 열람 + tmux refocus
local M = {}

local function tmux_move(direction)
  return function()
    vim.fn.system("tmux select-pane -" .. direction)
  end
end

function M.open(path)
  local win = Snacks.win({
    file = path,
    width = 0.85,
    height = 0.85,
    border = "rounded",
    wo = { wrap = false, spell = false },
    keys = {
      q = "close",
      ["<C-h>"] = { tmux_move("L"), desc = "tmux left" },
      ["<C-j>"] = { tmux_move("D"), desc = "tmux down" },
      ["<C-k>"] = { tmux_move("U"), desc = "tmux up" },
      ["<C-l>"] = { tmux_move("R"), desc = "tmux right" },
    },
  })

  -- tmux 패널 이동 후 nvim 으로 돌아올 때 float 로 재포커스
  local aug = vim.api.nvim_create_augroup("quicklinks_refocus", { clear = true })
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
