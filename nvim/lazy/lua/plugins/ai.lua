-- ai.lua: AI 코딩 어시스턴트 플러그인 모음
return {
  -- CopilotChat: 기본 모델이 gpt-4.1로 하드코딩돼 있는데 구독에서 못 찾는 경우가 있어
  -- Auto selector로 고정
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = { model = "auto" },
  },
}
