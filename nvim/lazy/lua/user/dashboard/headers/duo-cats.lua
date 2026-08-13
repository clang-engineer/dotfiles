-- Joan Stark (jgs), asciiart.website/art/7598
local text = [[
           *     ,MMM8&&&.            *
                MMMM88&&&&&    .
               MMMM88&&&&&&&           C
   *           MMM88&&&&&&&&
               MMM88&&&&&&&&        .
               'MMM88&&&&&&'
                 'MMM8&&&'      *    _
        |\___/|                      \\
       =) ^Y^ (=   |\_/|              ||    '
        \  ^  /    )a a '._.-""""-.  //
         )=*=(    =\T_= /    ~  ~  \//
        /     \     `"`\   ~   / ~  /
        |     |         |~   \ |  ~/
       /| | | |\         \  ~/- \ ~\
       \| | |_|/|        || |  // /`
_/\_//_// __//\_/\_/\_((_|\((_//\_/\_/\_
|  |  |  | \_) |  |  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |
clang.engineer |  |  |  |  |  |  |  |  |  |]]

local common = require("user.dashboard.renderers.common")
local hl = common.hl
local stars = { ["*"] = true, ["+"] = true, C = true }
local rail_signatures = { "// __//", "((_|\\((_//" }

local function rail_hl(line, col, char)
  if char == "(" or char == ")" or char == "|" then
    return hl.cyan
  end
  for _, signature in ipairs(rail_signatures) do
    local first, last = line:find(signature, 1, true)
    if first and col >= first and col <= last then
      return hl.cyan
    end
  end
  return hl.grey
end

local function render(lines)
  return common.render(lines, function(line_number, col, char, line)
    if stars[char] then
      return hl.yellow
    elseif line_number == 16 then
      return rail_hl(line, col, char)
    elseif line_number >= 17 and line_number <= 20 then
      return char ~= "|" and char ~= " " and hl.cyan or hl.grey
    elseif line_number == 21 then
      return col <= #"clang.engineer" and hl.signature or hl.grey
    elseif line:find("[M&]") then
      return hl.purple
    end
    return hl.cyan
  end)
end

return { text = text, render = render, layout = "landscape" }
