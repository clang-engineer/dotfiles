-- Display-only cheat sheet for existing AeroSpace and Rectangle bindings.
-- No additional keyboard shortcut: click the Hammerspoon menu-bar item.

local menu = hs.menubar.new()
if not menu then return end

menu:setTitle("⌘?")
menu:setTooltip("Window keymaps")

local help = [[
AeroSpace · Main
⌥ H/J/K/L          Focus
⌥⇧ H/J/K/L         Move
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

Hammerspoon
⇧ F1                Window hints
]]

menu:setClickCallback(function()
  hs.alert.show(help, {
    textFont = "Menlo",
    textSize = 15,
    radius = 8,
    padding = 18,
  }, hs.screen.mainScreen(), 10)
end)

return menu
