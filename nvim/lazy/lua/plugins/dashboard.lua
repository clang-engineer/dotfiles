-- dashboard: snacks.dashboard 헤더를 ASCII 고양이(누워있는 냥) 아트로 교체
-- 순수 텍스트라 폰트에서 100% 선명 — 의존성 0, 크로스플랫폼
--
-- 주의: snacks는 header를 줄 단위로 center 정렬한다(D:block/align). 줄마다 폭이 다르면
-- 각 줄의 center 오프셋이 달라져 왼쪽 시작점이 어긋나고 아트가 깨진다.
-- → 모든 줄을 최대 폭으로 오른쪽 패딩해 폭을 통일하면 오프셋이 같아져 정렬이 유지된다.
local art = [[
   |\      _,,,---,,_
   /,`.-'`'    -.  ;-;;,_
  |,4-  ) )-,_..;\ (  `'-'
 '---''(_/--'  `-'\_)]]

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local lines = vim.split(art, "\n", { plain = true })
    local width = 0
    for _, l in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(l))
    end
    for i, l in ipairs(lines) do
      lines[i] = l .. (" "):rep(width - vim.fn.strdisplaywidth(l))
    end

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.preset.header = table.concat(lines, "\n")
    opts.dashboard.sections = {
      { section = "header", padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    }
  end,
}
