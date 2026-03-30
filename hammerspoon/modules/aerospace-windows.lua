-- Show AeroSpace workspace windows as a popup (ctrl-alt-w)

local aero = "/opt/homebrew/bin/aerospace"

local wsIcons = {
  ["1:Browser"]   = "🌐 Browser",
  ["2:Terminal"]  = "> Terminal",
  ["3:Company"]   = "💬 Company",
  ["4:JetBrains"] = "⌨ JetBrains",
}

local wsOrder = {"1:Browser", "2:Terminal", "3:Company", "4:JetBrains"}

hs.hotkey.bind({"ctrl", "alt"}, "w", function()
  hs.task.new(aero, function(_, rawOutput, _)
    local focused = rawOutput:gsub("%s+$", "")

    hs.task.new(aero, function(_, winOutput, _)
      local wsApps = {}
      for _, ws in ipairs(wsOrder) do wsApps[ws] = {} end

      if winOutput then
        for line in winOutput:gmatch("[^\r\n]+") do
          local ws, app = line:match("^(.-)%|(.+)$")
          if ws and app and wsApps[ws] then
            local seen = false
            for _, a in ipairs(wsApps[ws]) do
              if a == app then seen = true; break end
            end
            if not seen then table.insert(wsApps[ws], app) end
          end
        end
      end

      local lines = {}
      for _, ws in ipairs(wsOrder) do
        local prefix = (ws == focused) and "● " or "○ "
        local apps = #wsApps[ws] > 0 and table.concat(wsApps[ws], ", ") or "(empty)"
        table.insert(lines, prefix .. wsIcons[ws] .. ": " .. apps)
      end

      hs.alert.closeAll()
      hs.alert.show(table.concat(lines, "\n"), {textSize = 16, fadeInDuration = 0, fadeOutDuration = 0.3}, hs.screen.mainScreen(), 2)
    end, {"list-windows", "--all", "--format", "%{workspace}|%{app-name}"}):start()
  end, {"list-workspaces", "--focused"}):start()
end)
