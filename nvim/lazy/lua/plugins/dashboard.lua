-- dashboard: snacks.dashboard 헤더를 ASCII 고양이 아트로 교체
-- 순수 텍스트라 폰트에서 100% 선명 — 의존성 0, 크로스플랫폼
-- 고양이 둘 다 Joan Stark(jgs) 작품 (asciiart.website/art/7597, 7598)
--
-- CAT 한 단어로 전환: "duo"(고양이 두 마리) | "magic"(한 마리)
-- 주의: snacks는 header를 줄 단위로 center 정렬한다(D:block/align). 줄마다 폭이 다르면
-- center 오프셋이 달라져 왼쪽 시작점이 어긋나며 아트가 깨진다.
-- → 아래에서 모든 줄을 최대 폭으로 오른쪽 패딩해 폭을 통일 = 오프셋 동일 = 정렬 유지.
local CAT = "magic"

local cats = {
  -- two cats on a fence under a magic cloud — Joan Stark (jgs), asciiart.website/art/7598
  duo = [[
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
clang.engineer |  |  |  |  |  |  |  |  |  |]],

  -- single cat on a fence under a magic cloud — Joan Stark (jgs), asciiart.website/art/7597
  magic = [[
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
clang.engineer |  |  |  |  |  |  |  |  |  |]],
}

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local lines = vim.split(cats[CAT], "\n", { plain = true })
    local width = 0
    for _, l in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(l))
    end
    for i, l in ipairs(lines) do
      lines[i] = l .. (" "):rep(width - vim.fn.strdisplaywidth(l))
    end

    -- 영역별 색 — 전부 cyberdream 팔레트 hex. ColorScheme 시 재적용 → 테마가 덮어써도 복구.
    -- 색 바꾸려면 fg hex 만 교체.
    local function set_palette()
      vim.api.nvim_set_hl(0, "CatSky", { fg = "#bd5eff" }) -- 구름 (purple)
      vim.api.nvim_set_hl(0, "CatStar", { fg = "#f1ff5e", bold = true }) -- 별·초승달 (yellow, purple 보색)
      vim.api.nvim_set_hl(0, "CatBody", { fg = "#5ef1ff" }) -- 고양이 (cyan)
      vim.api.nvim_set_hl(0, "CatFence", { fg = "#9aa5b1" }) -- 펜스 (grey)
      vim.api.nvim_set_hl(0, "CatSign", { fg = "#ffbd5e", bold = true }) -- 서명 (orange 명패)
    end
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_palette })
    set_palette()

    -- 줄 내용으로 영역 판별 (줄 번호 하드코딩 X → duo·magic 공용).
    -- 서명 줄은 아래 루프에서 이름/펜스로 따로 쪼개므로 여기선 안 다룸.
    local function hl_for(line)
      if line:find("|  |") or line:find("^_/\\") then
        return "CatFence"
      elseif line:find("[M&]") then
        return "CatSky"
      end
      return "CatBody"
    end

    -- 한 줄을 fragment 로 분해: 별 문자(* + C)만 골드로 빼고 나머지는 영역색.
    local star_chars = { ["*"] = true, ["+"] = true, ["C"] = true }
    local function push_line(header, line, base)
      local run, run_hl = "", nil
      local function flush()
        if run ~= "" then
          header[#header + 1] = { run, hl = run_hl }
        end
        run = ""
      end
      for ch in line:gmatch(".") do
        local hl = star_chars[ch] and "CatStar" or base
        if hl ~= run_hl then
          flush()
          run_hl = hl
        end
        run = run .. ch
      end
      flush()
    end

    local header = {}
    for i, line in ipairs(lines) do
      -- 서명 줄: "clang.engineer"(CatSign) + 우측 펜스(CatFence) 로 분리
      local name, rest = line:match("^(clang%.engineer)(.*)$")
      if name then
        header[#header + 1] = { name, hl = "CatSign" }
        push_line(header, rest, "CatFence")
      else
        push_line(header, line, hl_for(line))
      end
      if i < #lines then
        header[#header + 1] = { "\n" }
      end
    end

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.sections = {
      { text = header, align = "center", padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    }
  end,
}
