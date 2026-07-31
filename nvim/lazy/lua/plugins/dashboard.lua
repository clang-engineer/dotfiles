-- dashboard: snacks.dashboard 헤더를 ASCII 아트로 교체
-- 순수 텍스트라 폰트에서 100% 선명 — 의존성 0, 크로스플랫폼
--
-- Neovim을 열 때마다 등록된 헤더 중 하나를 선택.
-- 주의: snacks는 header를 줄 단위로 center 정렬한다(D:block/align). 줄마다 폭이 다르면
-- center 오프셋이 달라져 왼쪽 시작점이 어긋나며 아트가 깨진다.
-- → 아래에서 모든 줄을 최대 폭으로 오른쪽 패딩해 폭을 통일 = 오프셋 동일 = 정렬 유지.
local headers = require("user.dashboard.headers")
local selected_header = headers[(vim.fn.rand() % #headers) + 1]

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local lines = vim.split(selected_header.text, "\n", { plain = true })
    local width = 0
    for _, l in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(l))
    end
    for i, l in ipairs(lines) do
      lines[i] = l .. (" "):rep(width - vim.fn.strdisplaywidth(l))
    end

    local header = selected_header.render(lines)

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.sections = {
      { text = header, align = "center", padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    }
  end,
}
