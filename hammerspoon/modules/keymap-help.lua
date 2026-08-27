-- Menu-bar access to existing window keymaps and Hammerspoon window hints.
-- No additional keyboard shortcut: click the Hammerspoon menu-bar item.

local menu = hs.menubar.new()
if not menu then return end

menu:setTitle("⌘?")
menu:setTooltip("Window keymaps")

local help = [[
AeroSpace · Main
⌥ H/J/K/L          Focus window (tiled/floating)
⌥⇧ H/J/K/L         Move tiled window
⌥ 1/2/3/4          Workspace
⌥⇧ 1/2/3/4         Move to workspace
⌥ Tab              Previous workspace
⌥ /                Tile layout
⌥ ,                Accordion layout
⌥ - / =            Resize
⌥⇧ 0               Reflow windows
⌥⇧ ;               Service mode

AeroSpace · Service
Esc                 Reload config
R                   Flatten/reset layout
F                   Floating / tiling
Backspace           Close others
⌥⇧ H/J/K/L         Join with direction

Rectangle
⌃⌥ ←/→/↑/↓         Halves
⌃⌥ U/I/J/K         Corners
⌃⌥ D/F/G           Thirds
⌃⌥ E/T             Two thirds
⌃⌥ Return          Maximize / restore
⌃⌥ C               Center
]]

local helpCanvas

local function toggleHelp()
  if helpCanvas then
    helpCanvas:delete()
    helpCanvas = nil
    return
  end

  local screenFrame = hs.screen.mainScreen():frame()
  local width, height = 560, 520

  helpCanvas = hs.canvas.new({
    x = screenFrame.x + (screenFrame.w - width) / 2,
    y = screenFrame.y + (screenFrame.h - height) / 2,
    w = width,
    h = height,
  })

  helpCanvas[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = { white = 0.12, alpha = 0.96 },
    roundedRectRadii = { xRadius = 8, yRadius = 8 },
  }

  helpCanvas[2] = {
    type = "text",
    text = help,
    textFont = "Menlo",
    textSize = 15,
    textColor = { white = 0.95 },
    frame = { x = 18, y = 18, w = width - 36, h = height - 36 },
  }

  helpCanvas:show()
end

menu:setMenu({
  { title = "Keymap Help", fn = toggleHelp },
  { title = "Window Hints", fn = hs.hints.windowHints },
})

return menu
