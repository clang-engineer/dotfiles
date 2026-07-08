-- Under Copilot Business policy the /models response always comes back with
-- model_picker_enabled=false, so CopilotChat's default filter drops all chat models.
-- Intercept the curl response to enable the picker flag on chat models only, then call
-- the original get_models. Delete this file once the org policy is lifted or the picker
-- is enabled in GitHub personal settings.
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
