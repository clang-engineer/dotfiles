-- AeroSpace workspace indicator in macOS menu bar
-- Shows focused workspace + its app list in the menu bar title

local workspaces = {
  ["1:Browser"]   = "🌐",
  ["2:Terminal"]  = ">",
  ["3:Company"]   = "💬",
  ["4:JetBrains"] = "⌨",
}

local wsList = {"1:Browser", "2:Terminal", "3:Company", "4:JetBrains"}
local aero = "/opt/homebrew/bin/aerospace"
local menubar = hs.menubar.new()

local function updateTitle()
  hs.task.new(aero, function(exitCode, focusedRaw, _)
    if exitCode ~= 0 then return end
    local focused = focusedRaw:gsub("%s+$", "")
    local icon = workspaces[focused] or focused

    hs.task.new(aero, function(exitCode2, winRaw, _)
      if exitCode2 ~= 0 then
        menubar:setTitle(icon)
        return
      end

      local apps = {}
      local seen = {}
      for app in winRaw:gmatch("[^\r\n]+") do
        app = app:gsub("^%s+", ""):gsub("%s+$", "")
        if app ~= "" and not seen[app] then
          seen[app] = true
          table.insert(apps, app)
        end
      end

      local title = icon
      if #apps > 0 then
        title = icon .. " " .. table.concat(apps, ", ")
      end
      menubar:setTitle(title)
    end, {"list-windows", "--workspace", focused, "--format", "%{app-name}"}):start()
  end, {"list-workspaces", "--focused"}):start()
end

-- Click menu: switch workspace
menubar:setMenu(function()
  local focusedOutput = hs.execute(aero .. " list-workspaces --focused", true)
  local focused = focusedOutput and focusedOutput:gsub("%s+$", "") or ""

  local items = {}
  for _, ws in ipairs(wsList) do
    local icon = workspaces[ws]
    local isFocused = (ws == focused)
    table.insert(items, {
      title = (isFocused and "● " or "○ ") .. icon .. " " .. ws,
      fn = function()
        hs.execute(aero .. " workspace " .. ws, true)
        updateTitle()
      end,
    })
  end
  return items
end)

local timer = hs.timer.new(0.5, updateTitle)
timer:start()

updateTitle()
