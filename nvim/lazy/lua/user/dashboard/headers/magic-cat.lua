-- Joan Stark (jgs), asciiart.website/art/7597
local text = [[
           *     ,MMM8&&&.            *
                MMMM88&&&&&    .
               MMMM88&&&&&&&        C
   *           MMM88&&&&&&&&
               MMM88&&&&&&&&          .
               'MMM88&&&&&&'
                 'MMM8&&&'      *
        |\___/|                  +
        )     (             .              '
       =\     /=        *
         )===(       *
        /     \            .
        |     |
       /       \
       \       /
_/\_/\_/\__  _/_/\_/\_/\_/\_/\_/\_/\_/\_/\_
|  |  |  |( (  |  |  |  |  |  |  |  |  |  |
|  |  |  | ) ) |  |  |  |  |  |  |  |  |  |
|  |  |  |(_(  |  |  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |
clang.engineer |  |  |  |  |  |  |  |  |  |]]

local common = require("user.dashboard.renderers.common")
local hl = common.hl
local stars = { ["*"] = true, ["+"] = true, C = true }

local function rail_hl(line, col, char)
  if char == "(" or char == ")" or char == "|" then
    return hl.cyan
  end

  local first, last = line:find("\\[_ ]+/")
  if first and line:sub(first, last):find("  ", 1, true) and col >= first and col <= last then
    return hl.cyan
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
