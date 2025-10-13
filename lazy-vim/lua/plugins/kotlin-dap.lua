-- ~/.config/nvim/lua/plugins/kotlin-dap.lua
-- kotln dap 설정

return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = "mason-org/mason.nvim",
    opts = function()
      local dap = require("dap")
      if not dap.adapters.kotlin then
        dap.adapters.kotlin = {
          type = "executable",
          command = "kotlin-debug-adapter",
          options = { auto_continue_if_many_stopped = false },
        }
      end

      dap.configurations.kotlin = {
        {
          type = "kotlin",
          request = "launch",
          name = "This file",
          -- may differ, when in doubt, whatever your project structure may be,
          -- it has to correspond to the class file located at `build/classes/`
          -- and of course you have to build before you debug
          mainClass = function()
            local fname = vim.api.nvim_buf_get_name(0)
            -- src/main/kotlin/ 이후만 추출
            local relative = fname:match("src/main/kotlin/(.*)%.kt$")
            if relative then
              return relative:gsub("/", ".") -- JVM 패키지 구분자
            else
              -- fallback: 파일 이름만
              return vim.fn.fnamemodify(fname, ":t:r")
            end
          end,
          projectRoot = "${workspaceFolder}",
          jsonLogFile = "",
          enableJsonLogging = false,
        },
        {
          -- Use this for unit tests
          -- First, run
          -- ./gradlew --info cleanTest test --debug-jvm
          -- ./gradlew -x webapp bootRun --jvm-debug
          -- then attach the debugger to it
          -- :lua require('dapui').toggle()
          type = "kotlin",
          request = "attach",
          name = "Attach to debugging session",
          port = 5005,
          args = {},
          projectRoot = vim.fn.getcwd,
          hostName = "localhost",
          timeout = 2000,
        },
      }
    end,
  },
}
