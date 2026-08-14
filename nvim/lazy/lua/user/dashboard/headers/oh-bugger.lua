-- ASCII art from https://asciiart.website/art/7701
local text = [[
        ,
       /|
      / |
     /  /
    |   |
   /    |
   |    \_
   |      \__
   \       __\_______
    \                 \_
    | /                 \
    \/                   \
     |                    |
     \                   \|
     |                    \
     \                     |
     /\    \_               \
    / |      \__ (   )       \
   /  \      / |\\  /       __\____
snd|  ,     |  /\ \ \__    |       \_
   \_/|\___/   \   \}}}\__|  (@)     )
    \)\)\)      \_\---\   \|       \ \
                  \>\>\>   \   /\__o_o)
                            | /  VVVVV
                            \ \    \
                             \ \MMMMM                  oh bugger!
                              \______/         _____ /
                                              |  O O|
                                             /___|_|/\_
                                        ==( |          |
                                             (o)====(o)
]]

local common = require("user.dashboard.renderers.common")
local hl = common.hl

local face = { ["("] = true, [")"] = true, ["O"] = true, ["o"] = true, ["@"] = true }

local function render(lines)
  return common.render(lines, function(_, _, char)
    if face[char] then
      return hl.yellow
    end
    return hl.cyan
  end)
end

return { text = text, render = render, layout = "portrait" }
