-- Display-only cheat sheet for existing AeroSpace and Rectangle bindings.
-- No additional keyboard shortcut: click the Hammerspoon menu-bar item.

local menu = hs.menubar.new()
if not menu then return end

menu:setTitle("⌨")
menu:setTooltip("Window keymaps")

local help = [[
AeroSpace
⌥ H/J/K/L          Focus
⌥⇧ H/J/K/L         Move
⌥ 1/2/3/4          Workspace
⌥⇧ 1/2/3/4         Move to workspace
⌥ Tab              Previous workspace
⌥ - / =            Resize
⌥⇧ ;               Service mode

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
  }, hs.screen.mainScreen(), 8)
end)

return menu
