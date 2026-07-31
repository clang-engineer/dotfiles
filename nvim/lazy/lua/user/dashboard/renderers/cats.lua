return function(lines)
  -- 영역별 색 — 전부 cyberdream 팔레트 hex. ColorScheme 시 재적용 → 테마가 덮어써도 복구.
  -- 색 바꾸려면 fg hex 만 교체.
  local function set_palette()
    vim.api.nvim_set_hl(0, "CatSky", { fg = "#bd5eff" }) -- 구름 (purple)
    vim.api.nvim_set_hl(0, "CatStar", { fg = "#f1ff5e", bold = true }) -- 별·초승달 (yellow, purple 보색)
    vim.api.nvim_set_hl(0, "CatBody", { fg = "#5ef1ff" }) -- 고양이 (cyan)
    vim.api.nvim_set_hl(0, "CatFence", { fg = "#9aa5b1" }) -- 펜스 (grey)
    vim.api.nvim_set_hl(0, "CatSign", { fg = "#b8abd4", italic = true }) -- 서명 (은은한 라벤더 — 구름 purple 저채도, 배경 위 가독 확보)
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

  -- 한 줄을 fragment 로 분해. 별 문자(* + C)는 항상 골드, 나머지는 base 색.
  -- base 는 색 문자열이거나 (문자, 열)->색 함수 (펜스 줄에서 고양이 글리프 분리에 사용).
  local star_chars = { ["*"] = true, ["+"] = true, ["C"] = true }
  local function push_line(header, line, base)
    local base_hl = type(base) == "function" and base or function()
      return base
    end
    local run, run_hl = "", nil
    local function flush()
      if run ~= "" then
        header[#header + 1] = { run, hl = run_hl }
      end
      run = ""
    end
    local col = 0
    for ch in line:gmatch(".") do
      col = col + 1
      local hl = star_chars[ch] and "CatStar" or base_hl(ch, col)
      if hl ~= run_hl then
        flush()
        run_hl = hl
      end
      run = run .. ch
    end
    flush()
  end

  -- 펜스 줄에 걸터앉은 고양이(꼬리·엉덩이·연결부)를 fence 사이에서 cat 색으로 분리.
  -- 평면 ASCII라 레일 위에선 고양이와 펜스가 같은 글자(_ / \)를 공유 → 열(column) 로 골라낸다.
  local function fence_hl(line)
    local cat = {} -- cat 색으로 칠할 열 index 집합
    if line:find("^_/\\") then
      -- 레일: 엉덩이 글리프 ( ) | 는 cat
      for i = 1, #line do
        local c = line:sub(i, i)
        if c == "(" or c == ")" or c == "|" then
          cat[i] = true
        end
      end
      -- duo의 두 고양이 다리와 레일 연결부
      for _, signature in ipairs({ "// __//", "((_|\\((_//" }) do
        local s, e = line:find(signature, 1, true)
        if s then
          for i = s, e do
            cat[i] = true
          end
        end
      end
      -- 고양이 밑면: \…/ 사이의 _/공백 런 중 연속 2칸 공백(가랑이 갭)을 낀 구간 (magic 전용 시그니처)
      local init = 1
      while true do
        local s, e = line:find("\\[_ ]+/", init)
        if not s then
          break
        end
        if line:sub(s, e):find("  ") then
          -- 경계 \ / 포함: 고양이 다리가 몸통→꼬리로 이어지는 지점
          for i = s, e do
            cat[i] = true
          end
        end
        init = e
      end
    else
      -- post 줄: | 와 공백만 fence, 나머지(꼬리 ( ) _ \)는 cat
      for i = 1, #line do
        local c = line:sub(i, i)
        if c ~= "|" and c ~= " " then
          cat[i] = true
        end
      end
    end
    return function(_, col)
      return cat[col] and "CatBody" or "CatFence"
    end
  end

  local header = {}
  for i, line in ipairs(lines) do
    -- 서명 줄: "clang.engineer"(CatSign) + 우측 펜스(CatFence) 로 분리
    local name, rest = line:match("^(clang%.engineer)(.*)$")
    if name then
      header[#header + 1] = { name, hl = "CatSign" }
      push_line(header, rest, "CatFence")
    else
      local base = hl_for(line)
      push_line(header, line, base == "CatFence" and fence_hl(line) or base)
    end
    if i < #lines then
      header[#header + 1] = { "\n" }
    end
  end
  return header
end
