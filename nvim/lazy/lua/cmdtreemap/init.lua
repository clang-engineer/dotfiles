local M = {}

local function tmux_navigate(direction, fallback)
  if vim.fn.exists(":TmuxNavigateUp") == 0 and vim.fn.exists(":TmuxNavigateDown") == 0 then
    pcall(vim.cmd, "packadd vim-tmux-navigator")
  end

  local cmd
  if direction == "down" then
    cmd = "TmuxNavigateDown"
  elseif direction == "up" then
    cmd = "TmuxNavigateUp"
  end

  if cmd and vim.fn.exists(":" .. cmd) == 2 then
    vim.cmd("silent! " .. cmd)
    return true
  end

  if fallback then
    fallback()
  end
  return false
end

M.defaults = {
  layout = { preset = "sidebar" },
  focus = "list",
  win = {
    input = {
      keys = {
        ["<C-j>"] = function()
          tmux_navigate("down")
        end,
        ["<C-k>"] = function()
          tmux_navigate("up")
        end,
      },
    },
    list = {
      keys = {
        ["<C-h>"] = "focus_list",
        ["<C-l>"] = "focus_preview",
        l = "expand",
        h = "collapse",
        o = "open_url",
        ["zR"] = "expand_all",
        ["zM"] = "collapse_all",
        y = "copy_url",
        Y = "copy_install",
      },
    },
    preview = {
      keys = {
        ["<C-h>"] = "focus_list",
        ["<C-l>"] = "focus_preview",
        ["<C-j>"] = function()
          tmux_navigate("down", function()
            vim.cmd("wincmd j")
          end)
        end,
        ["<C-k>"] = function()
          tmux_navigate("up", function()
            vim.cmd("wincmd k")
          end)
        end,
        l = "focus_list",
        h = "focus_list",
      },
    },
  },
}

local function set_preview_window_maps(buf, picker)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local function focus_list()
    if picker and picker.layout and picker.layout.wins and picker.layout.wins.list then
      local list_win = picker.layout.wins.list
      if list_win:valid() and not picker.layout:is_hidden("list") then
        picker:focus("list", { show = true })
        return
      end
    end

    vim.cmd("wincmd k")
  end

  local function move_down()
    tmux_navigate("down", function()
      vim.cmd("wincmd j")
    end)
  end

  local function move_up()
    tmux_navigate("up", function()
      focus_list()
    end)
  end

  vim.keymap.set({ "n", "i" }, "<C-j>", move_down, {
    buffer = buf,
    nowait = true,
    noremap = true,
    silent = true,
  })
  vim.keymap.set({ "n", "i" }, "<C-J>", move_down, {
    buffer = buf,
    nowait = true,
    noremap = true,
    silent = true,
  })
  vim.keymap.set({ "n", "i" }, "<C-k>", move_up, {
    buffer = buf,
    nowait = true,
    noremap = true,
    silent = true,
  })
  vim.keymap.set({ "n", "i" }, "<C-K>", move_up, {
    buffer = buf,
    nowait = true,
    noremap = true,
    silent = true,
  })
end

local function set_picker_nav_keys(picker)
  local actions = require("snacks.picker.actions")
  local list_win = picker.list and picker.list.win and picker.list.win.win
  local preview_win = picker.preview and picker.preview.win and picker.preview.win.win

  if list_win and vim.api.nvim_win_is_valid(list_win) then
    local list_buf = vim.api.nvim_win_get_buf(list_win)
    vim.keymap.set("n", "<C-j>", function()
      actions.list_down(picker)
    end, { buffer = list_buf, nowait = true, noremap = true, silent = true })
    vim.keymap.set("n", "<C-k>", function()
      actions.list_up(picker)
    end, { buffer = list_buf, nowait = true, noremap = true, silent = true })
  end

  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    set_preview_window_maps(vim.api.nvim_win_get_buf(preview_win), picker)
    return
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local win_buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[win_buf].filetype == "snacks_picker_preview" then
      set_preview_window_maps(win_buf, picker)
    end
  end
end

local function reapply_nav_keys(picker, remaining)
  if not picker or picker.closed then
    return
  end
  picker.opts.auto_close = false
  remaining = remaining or 0
  set_picker_nav_keys(picker)
  if remaining <= 0 then
    return
  end
  vim.defer_fn(function()
    reapply_nav_keys(picker, remaining - 1)
  end, 10)
end

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

  local f = "cmdtreemap.finder"

  vim.schedule(function()
    Snacks.picker.sources.cmdtreemap = {
      layout = opts.layout,
      focus = opts.focus,
      win = opts.win,
      auto_close = false,
      on_show = function(picker)
        reapply_nav_keys(picker, 4)
      end,
      on_change = function(picker)
        reapply_nav_keys(picker, 4)
      end,
      finder = function(picker_opts, ctx)
        return require(f).finder(picker_opts, ctx)
      end,
      format = function(item, picker)
        return require(f).format(item, picker)
      end,
      actions = {
        confirm = function(picker)
          return require(f).expand(picker)
        end,
        expand = function(picker)
          return require(f).expand(picker)
        end,
        collapse = function(picker)
          return require(f).collapse(picker)
        end,
        expand_all = function(picker)
          require(f).expand_all()
          picker.list:set_target()
          return picker:find()
        end,
        collapse_all = function(picker)
          require(f).collapse_all()
          picker.list:set_target()
          return picker:find()
        end,
        copy_url = function(picker)
          return require(f).copy_url(picker)
        end,
        copy_install = function(picker)
          return require(f).copy_install(picker)
        end,
        open_url = function(picker)
          return require(f).open_url(picker)
        end,
      },
    }
  end)

  vim.api.nvim_create_user_command("CmdTreeMap", function()
    Snacks.picker("cmdtreemap", { auto_close = false })
  end, { desc = "CLI command evolution tree" })
end

return M
