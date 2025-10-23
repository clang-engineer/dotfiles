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

local mod = {'option', 'shift'}
hs.hotkey.bind(mod, 'left', move_win(0, 0, 1/2, 1))
hs.hotkey.bind(mod, 'right', move_win(1/2, 0, 1/2, 1))
hs.hotkey.bind(mod, 'up', move_win(0, 0, 1, 1/2))
hs.hotkey.bind(mod, 'down', move_win(0, 1/2, 1, 1/2))

hs.hotkey.bind(mod, '1', move_win(0, 1/2, 1/2, 1/2))
hs.hotkey.bind(mod, '2', move_win(0, 1/2, 1, 1/2))
hs.hotkey.bind(mod, '3', move_win(1/2, 1/2, 1/2, 1/2))
hs.hotkey.bind(mod, '4', move_win(0, 0, 1/2, 1))
hs.hotkey.bind(mod, '5', move_win(0, 0, 1, 1))
hs.hotkey.bind(mod, '6', move_win(1/2, 0, 1/2, 1))
hs.hotkey.bind(mod, '7', move_win(0, 0, 1/2, 1/2))
hs.hotkey.bind(mod, '8', move_win(0, 0, 1, 1/2))
hs.hotkey.bind(mod, '9', move_win(1/2, 0, 1/2, 1/2))
