-- show winow hint
hs.hotkey.bind({'shift'}, 'F1', hs.hints.windowHints)

-- move window
local function move_win(xx, yy, ww, hh)
    return function()
        local win = hs.window.focusedWindow()
        local frame = win:frame()
        local screen = win:screen():frame()
        frame.x = screen.w * xx
        frame.y = screen.h * yy
        frame.w = screen.w * ww
        frame.h = screen.h * hh
        win:setFrame(frame)
    end
end

local mod = {'ctrl', 'option'}

-- Rectangle style keybindings
hs.hotkey.bind(mod, 'left', move_win(0, 0, 1/2, 1))       -- 왼쪽 반
hs.hotkey.bind(mod, 'right', move_win(1/2, 0, 1/2, 1))    -- 오른쪽 반
hs.hotkey.bind(mod, 'up', move_win(0, 0, 1, 1/2))          -- 위쪽 반
hs.hotkey.bind(mod, 'down', move_win(0, 1/2, 1, 1/2))      -- 아래쪽 반
hs.hotkey.bind(mod, 'return', move_win(0, 0, 1, 1))         -- 전체화면
hs.hotkey.bind(mod, 'u', move_win(0, 0, 1/2, 1/2))          -- 왼쪽 상단
hs.hotkey.bind(mod, 'j', move_win(0, 1/2, 1/2, 1/2))        -- 왼쪽 하단
hs.hotkey.bind(mod, 'i', move_win(1/2, 0, 1/2, 1/2))        -- 오른쪽 상단
hs.hotkey.bind(mod, 'k', move_win(1/2, 1/2, 1/2, 1/2))      -- 오른쪽 하단
