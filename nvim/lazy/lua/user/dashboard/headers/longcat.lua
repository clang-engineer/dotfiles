-- Michael Lazar (mozz), asciiart.website/art/6419
local text = [[
                      _
            __       / |
            \ "-..--'_4|_
 _._____     \ _  _(C "._'._
((^     '"-._( O_ O "._` '. \
 `"'--._     \  y_     \   \|
        '-._  \_ _  __.=-.__,\_
            `'-(" ,("___       \,_____
                (_,("___     .-./     '
                |   C'___    (5)
                /    ``  '---'-'._```
               |     ```    |`    '"-._
               |    ````    \-.`
               |    ````    |  "._ ``
               /    ````    |     '-.__
              |     ```     |
              |     ```     |
              |     ```     |
              |     ```     /
              |    ````    |
              |    ```     |
              |    ```     /
              |    ```     |
              /    ```     |
             |     ```     |
             |     ```     !
             |     ```    / '-.___
             |    ````    !_      ''-
             /   `   `    | '--._____)
             |     /|     !
             !    / |     /
             |    | |    /
             |    | |   /
             |    / |   |
             /   /  |   |
            /   /   |   |
           (,,_]    (,_,)    clang.engineer]]

local common = require("user.dashboard.renderers.common")
local hl = common.hl
local face_details = { O = true, y = true }
local spots = { ["4"] = true, ["5"] = true, C = true, ["`"] = true }
local shadows = { ['"'] = true, ["'"] = true, ["."] = true, [","] = true }

local function render(lines)
  return common.render(lines, function(line_number, col, char, line)
    local signature_col = line_number == 37 and line:find("clang.engineer", 1, true)
    if signature_col and col >= signature_col then
      return hl.signature
    elseif face_details[char] then
      return hl.yellow
    elseif spots[char] then
      return hl.purple
    elseif shadows[char] then
      return hl.grey
    end
    return hl.cyan
  end)
end

return { text = text, render = render, layout = "portrait" }
