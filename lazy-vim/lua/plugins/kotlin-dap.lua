-- ~/.config/nvim/lua/plugins/kotlin-dap.lua

return {
  {
    "mfussenegger/nvim-dap",
    ft = { "kotlin" },
    opts = function()
      local dap = require("dap")
      -- adapter: kotlin-debug-adapter 사용
      dap.adapters.kotlin = {
        type = "executable",
        command = "kotlin-debug-adapter",
        options = { auto_continue_if_many_stopped = false },
      }

      dap.configurations.kotlin = {
        -- launch 모드: 현재 파일(mainClass) 실행
        {
          type = "kotlin",
          request = "launch",
          name = "Launch This File",
          mainClass = function()
            local fname = vim.api.nvim_buf_get_name(0)
            -- src/main/kotlin 이후의 부분만 추출
            local relative = fname:match("src/main/kotlin/(.*).kt$")
            if not relative then
              return vim.fn.fnamemodify(fname, ":t:r") -- fallback: 파일 이름만
            end
            -- 경로 구분자 / → .
            local class = relative:gsub("/", ".")
            return class
          end,
          projectRoot = "${workspaceFolder}",
          jsonLogFile = "",
          enableJsonLogging = false,
        },
        -- attach 모드 ./gradlew --debug-jvm 로 실행한 프로세스에 연결, :lua require('dapui').open()
        {
          type = "kotlin",
          request = "attach",
          name = "Attach to Debug Session",
          hostName = "localhost",
          port = 5005,
          timeout = 2000,
          projectRoot = vim.fn.getcwd,
          args = {},
        },
      }
    end,
  },
}
