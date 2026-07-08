-- move window
local function move_win(xx, yy, ww, hh)
    return function()
        local win = hs.window.focusedWindow()
        local frame = win:frame()
        local screen = win:screen():frame()
        frame.x = screen.x + screen.w * xx
        frame.y = screen.y + screen.h * yy
        frame.w = screen.w * ww
        frame.h = screen.h * hh
        win:setFrame(frame)
    end
end

local mod = {'ctrl', 'option'}

-- Rectangle style keybindings: halves
hs.hotkey.bind(mod, 'left', move_win(0, 0, 1/2, 1))        -- Left Half
hs.hotkey.bind(mod, 'right', move_win(1/2, 0, 1/2, 1))     -- Right Half
hs.hotkey.bind(mod, 'up', move_win(0, 0, 1, 1/2))           -- Top Half
hs.hotkey.bind(mod, 'down', move_win(0, 1/2, 1, 1/2))       -- Bottom Half

-- Corners
hs.hotkey.bind(mod, 'u', move_win(0, 0, 1/2, 1/2))          -- Top Left
hs.hotkey.bind(mod, 'i', move_win(1/2, 0, 1/2, 1/2))        -- Top Right
hs.hotkey.bind(mod, 'j', move_win(0, 1/2, 1/2, 1/2))        -- Bottom Left
hs.hotkey.bind(mod, 'k', move_win(1/2, 1/2, 1/2, 1/2))      -- Bottom Right

-- Maximize toggle / center
local prev_frames = {}
hs.hotkey.bind(mod, 'return', function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local id = win:id()
  local frame = win:frame()
  local screen = win:screen():frame()
  local max = hs.geometry.rect(screen.x, screen.y, screen.w, screen.h)
  if frame:equals(max) and prev_frames[id] then
    win:setFrame(prev_frames[id])
    prev_frames[id] = nil
  else
    prev_frames[id] = frame:copy()
    win:setFrame(max)
  end
end)
hs.hotkey.bind(mod, 'c', move_win(1/8, 1/8, 3/4, 3/4))      -- Center (3/4 size)

-- Thirds
hs.hotkey.bind(mod, 'd', move_win(0, 0, 1/3, 1))            -- First Third
hs.hotkey.bind(mod, 'f', move_win(1/3, 0, 1/3, 1))          -- Center Third
hs.hotkey.bind(mod, 'g', move_win(2/3, 0, 1/3, 1))          -- Last Third

-- Two thirds
hs.hotkey.bind(mod, 'e', move_win(0, 0, 2/3, 1))            -- First Two Thirds
hs.hotkey.bind(mod, 't', move_win(1/3, 0, 2/3, 1))          -- Last Two Thirds
