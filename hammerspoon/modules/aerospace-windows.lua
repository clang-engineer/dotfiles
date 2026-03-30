-- Show app list when AeroSpace workspace changes

local aero = "/opt/homebrew/bin/aerospace"

local wsIcons = {
  ["1:Browser"]   = "🌐 Browser",
  ["2:Terminal"]  = "> Terminal",
  ["3:Company"]   = "💬 Company",
  ["4:JetBrains"] = "⌨ JetBrains",
}

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

      local text = icon
      if #apps > 0 then
        text = icon .. ": " .. table.concat(apps, ", ")
      end

      hs.alert.closeAll()
      hs.alert.show(text, {textSize = 16, fadeInDuration = 0, fadeOutDuration = 0.3}, hs.screen.mainScreen(), 1.5)
    end, {"list-windows", "--workspace", focused, "--format", "%{app-name}"}):start()
  end, {"list-workspaces", "--focused"}):start()
end

-- Triggered by AeroSpace via URL scheme
hs.urlevent.bind("aerospace-workspace-changed", function()
  showWorkspaceApps()
end)
