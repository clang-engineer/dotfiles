-- Copilot Business 정책상 /models 응답이 model_picker_enabled=false로만 와서
-- CopilotChat 기본 필터가 채팅 모델을 전부 걸러낸다. curl 응답을 가로채
-- 채팅 모델만 picker 플래그를 켜주고 원본 get_models를 호출.
-- 추후 org 정책이 풀리거나 GitHub 개인 설정에서 picker 활성화되면 이 파일 삭제.
return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = function(_, opts)
      local providers = require("CopilotChat.config.providers")
      local curl = require("CopilotChat.utils.curl")
      local original = providers.copilot.get_models

      providers.copilot.get_models = function(headers)
        local orig_get = curl.get
        curl.get = function(url, o)
          local resp, err = orig_get(url, o)
          if resp and resp.body and resp.body.data then
            for _, m in ipairs(resp.body.data) do
              if m.capabilities and m.capabilities.type == "chat" then
                m.model_picker_enabled = true
              end
            end
          end
          return resp, err
        end
        local ok, res = pcall(original, headers)
        curl.get = orig_get
        if not ok then
          error(res)
        end
        return res
      end

      opts.model = "auto"
      return opts
    end,
  },
}
