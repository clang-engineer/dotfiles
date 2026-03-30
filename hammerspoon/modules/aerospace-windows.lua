-- Show app list when AeroSpace workspace changes

local aero = "/opt/homebrew/bin/aerospace"

local wsIcons = {
  ["1:Browser"]   = "1: 🌐 Browser",
  ["2:Terminal"]  = "2: > Terminal",
  ["3:Company"]   = "3: 💬 Company",
  ["4:JetBrains"] = "4: ⌨ JetBrains",
}

local alertStyle = {
  textSize = 14,
  textColor = {white = 1, alpha = 0.9},
  textFont = ".AppleSystemUIFont",
  strokeColor = {white = 0, alpha = 0},
  fillColor = {white = 0.1, alpha = 0.6},
  strokeWidth = 0,
  radius = 8,
  padding = 12,
  fadeInDuration = 0.1,
  fadeOutDuration = 0.5,
  atScreenEdge = 1,
}

local function showAlert(text)
  hs.alert.closeAll()
  hs.alert.show(text, alertStyle, hs.screen.mainScreen(), 1.5)
end

local function showWorkspaceApps()
  hs.task.new(aero, function(_, focusedRaw, _)
    local focused = focusedRaw:gsub("%s+$", "")
    local icon = wsIcons[focused] or focused

    hs.task.new(aero, function(_, winOutput, _)
      local apps = {}
      local seen = {}
      if winOutput then
        for app in winOutput:gmatch("[^\r\n]+") do
          app = app:gsub("^%s+", ""):gsub("%s+$", "")
          if app ~= "" and not seen[app] then
            seen[app] = true
            table.insert(apps, app)
          end
        end
      end

      local text = #apps > 0 and table.concat(apps, ", ") or "(empty)"

      showAlert(text)
    end, {"list-windows", "--workspace", focused, "--format", "%{app-name}"}):start()
  end, {"list-workspaces", "--focused"}):start()
end

-- Triggered by AeroSpace on workspace switch
hs.urlevent.bind("aerospace-workspace-changed", function()
  showWorkspaceApps()
end)

-- Triggered by AeroSpace on move-node-to-workspace
hs.urlevent.bind("aerospace-node-moved", function(_, params)
  local targetWs = params and params.ws or nil
  if not targetWs then return end

  local appName = params and params.app or "App"
  local targetIcon = wsIcons[targetWs] or targetWs

  showAlert(appName .. " → " .. targetIcon)
end)
