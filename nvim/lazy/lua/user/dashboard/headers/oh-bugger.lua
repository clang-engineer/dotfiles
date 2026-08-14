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

local face = {
  ["O"] = true,
  ["o"] = true,
  ["@"] = true,
}

local shadows = {
  ["'"] = true,
  ["`"] = true,
  ["("] = true,
  [")"] = true,
  ["/"] = true,
  ["\\"] = true,
  ["_"] = true,
  ["-"] = true,
  ["|"] = true,
  [">"] = true,
}

local accents = {
  ["M"] = true,
  ["V"] = true,
}

local function render(lines)
  return common.render(lines, function(_, col, char, line)
    local signature_col = line:find("oh bugger!", 1, true)
    if signature_col and col >= signature_col and col < signature_col + #"oh bugger!" then
      return hl.signature
    end

    if face[char] then
      return hl.yellow
    end

    if accents[char] then
      return hl.purple
    end

    if shadows[char] then
      return hl.grey
    end

    return hl.cyan
  end)
end

return { text = text, render = render, layout = "portrait" }
