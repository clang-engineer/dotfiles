-- dashboard: snacks.dashboard 헤더를 ASCII 아트로 교체
-- 순수 텍스트라 폰트에서 100% 선명 — 의존성 0, 크로스플랫폼
--
-- Neovim을 열 때마다 등록된 헤더 중 하나를 선택하고, 좌우 화살표로 순환.
-- 주의: snacks는 header를 줄 단위로 center 정렬한다(D:block/align). 줄마다 폭이 다르면
-- center 오프셋이 달라져 왼쪽 시작점이 어긋나며 아트가 깨진다.
-- → 아래에서 모든 줄을 최대 폭으로 오른쪽 패딩해 폭을 통일 = 오프셋 동일 = 정렬 유지.
local headers = require("user.dashboard.headers")
local selected_header_index = (vim.fn.rand() % #headers) + 1

local function cycle_header(dashboard, offset)
  selected_header_index = (selected_header_index + offset - 1) % #headers + 1
  dashboard:update()
end

local function header_section(dashboard)
  vim.keymap.set("n", "<Left>", function()
    cycle_header(dashboard, -1)
  end, { buffer = dashboard.buf, silent = true, desc = "Previous dashboard header" })
  vim.keymap.set("n", "<Right>", function()
    cycle_header(dashboard, 1)
  end, { buffer = dashboard.buf, silent = true, desc = "Next dashboard header" })

  local selected_header = headers[selected_header_index]
  local lines = vim.split(selected_header.text, "\n", { plain = true })
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  for i, line in ipairs(lines) do
    lines[i] = line .. (" "):rep(width - vim.fn.strdisplaywidth(line))
  end

  return { text = selected_header.render(lines), align = "center", padding = 1 }
end

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = opts.dashboard or {}
    opts.dashboard.sections = {
      header_section,
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    }
  end,
}
