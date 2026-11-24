local M = {}
local uv = vim.uv or vim.loop
local directory = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h") .. "/dotfiles"
M.path = directory .. "/theme.lua"

local errors = {}
local watcher
local initialized = false
local stopped = false

local function report(kind, message)
  if errors[kind] == message then
    return
  end
  errors[kind] = message
  vim.schedule(function()
    if not stopped then
      vim.notify(message, vim.log.levels.ERROR, { title = "Dotfiles theme" })
    end
  end)
end

function M.read()
  local chunk, err = loadfile(M.path)
  if not chunk then
    local _, _, code = uv.fs_stat(M.path)
    if code ~= "ENOENT" then
      report("read", "Cannot read " .. M.path .. ": " .. tostring(err))
    end
    return
  end
  local ok, colorscheme = pcall(chunk)
  if not ok or type(colorscheme) ~= "string" or not colorscheme:find("%S") then
    report("read", "Invalid " .. M.path .. ": " .. (ok and "expected a colorscheme name" or tostring(colorscheme)))
    return
  end
  errors.read = nil
  return colorscheme
end

function M.reload()
  local colorscheme = M.read()
  if not colorscheme then
    return false
  end
  if colorscheme == vim.g.colors_name then
    return true
  end
  local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if ok then
    errors.apply = nil
  else
    report("apply", "Cannot load colorscheme " .. colorscheme .. ": " .. tostring(err))
  end
  return ok
end

local function close_watcher()
  if watcher then
    watcher:stop()
    watcher:close()
    watcher = nil
  end
end

function M.setup()
  if initialized then
    return M.read()
  end
  initialized = true
  local group = vim.api.nvim_create_augroup("DotfilesTheme", { clear = true })
  local fallback = false
  local function watch_failed(err)
    close_watcher()
    report("watch", "Cannot watch " .. directory .. ": " .. tostring(err) .. "; reloading on focus instead")
    if not fallback then
      fallback = true
      vim.api.nvim_create_autocmd("FocusGained", {
        group = group,
        callback = function()
          M.reload()
        end,
      })
    end
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    once = true,
    callback = function()
      stopped = true
      close_watcher()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = function()
      local err
      watcher, err = uv.new_fs_event()
      if not watcher then
        watch_failed(err)
        return
      end
      -- Watch the directory: chezmoi can replace theme.lua with an atomic rename.
      local ok
      ok, err = watcher:start(
        directory,
        {},
        vim.schedule_wrap(function(event_err, filename)
          if stopped then
            return
          end
          if event_err then
            watch_failed(event_err)
          elseif not filename or filename == "theme.lua" then
            M.reload()
          end
        end)
      )
      if not ok then
        watch_failed(err)
      end
      -- Catch changes made between reading the startup option and starting the watch.
      M.reload()
    end,
  })
  return M.read()
end

return M
