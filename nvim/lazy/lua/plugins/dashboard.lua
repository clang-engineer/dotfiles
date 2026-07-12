-- dashboard: snacks.dashboard 헤더를 ASCII 고양이 아트로 교체
-- 순수 텍스트(문자)라 폰트에서 100% 선명 — 이미지/애니 렌더 열화 없음, 의존성 0, 크로스플랫폼
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = opts.dashboard or {}
    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.preset.header = [[
   |\      _,,,---,,_
   /,`.-'`'    -.  ;-;;,_
  |,4-  ) )-,_..;\ (  `'-'
 '---''(_/--'  `-'\_)
]]
    opts.dashboard.sections = {
      { section = "header", padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    }
  end,
}
