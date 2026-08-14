-- (c) asciiart.website, art/6411
local text = [[
                              .`^^``"._---__
                             l._        '<`o\\
                             ^wv.             '_
                             \v v^,___,,,       ',
                              `vv``VVvvv^\`-.   "|
                                `\^      )\  \    \
                                  \\ .====!/ `    . '
                                  /'````,"    .   \ \
                                  A    A          \  .
                               _ A   A^     _,_       \
                             ," [AAA]` _.-'"  'j       !
 _                          /    .__.-"    \ / !     | |
 \`.___                    /    `    !      :   \    ! |
  `._  '---.___        _.-^ `. / .=-,\     /    '    / |
     '._` \._  `''---'/       y  ccC^|    `    /.=-,   /
        '-._ `--.\\       \ -'       !  '-.__   CCC-  /\
            '-.__  -. \   / ,         '             ,' !|
                 '--.____/_/      /  ^         /  .`    !
                          /  _-' ,  '    ___. '_.`      |
                         /      / /-. _/__ ..-`   \  _. /
                        // --    /        7 /   ,-'    /
                       ,`     ,-'         |'       ___/
                       !,    /            |   .--'`
                       ||  /|             !/  |
                       |! ` \             / ! |
         \o7            \' __!           [` `  \ clang.engineer
          |             /.- _ '_          \ --,_`__ _
         / \           (/\-/_\/\_\          ' ___./_/\\]]

local common = require("user.dashboard.renderers.common")
local hl = common.hl

local face = {
  ["A"] = true,
  ["v"] = true,
  ["V"] = true,
  ["C"] = true,
  ["c"] = true,
  ["y"] = true,
  ["o"] = true,
}

local shadows = {
  ["'"] = true,
  ['"'] = true,
  ["."] = true,
  [","] = true,
  ["`"] = true,
  ["("] = true,
  [")"] = true,
  ["/"] = true,
  ["\\"] = true,
  ["-"] = true,
  ["|"] = true,
}

local accent = {
  ["["] = true,
  ["]"] = true,
  ["^"] = true,
}

local function render(lines)
  return common.render(lines, function(line_number, col, char, line)
    local signature_col = line:find("clang.engineer", 1, true)
    if signature_col and col >= signature_col and col < signature_col + #"clang.engineer" then
      return hl.signature
    end

    if face[char] then
      return hl.yellow
    end

    if accent[char] then
      return hl.purple
    end

    if shadows[char] then
      return hl.grey
    end

    return hl.cyan
  end)
end

return { text = text, render = render, layout = "portrait" }
