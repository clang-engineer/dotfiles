return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- Project-level .nvim.lua should set:
      --   vim.env.JDTLS_JAVA_HOME and vim.env.GRADLE_JAVA_HOME
      -- Example:
      --   vim.env.JDTLS_JAVA_HOME = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"
      --   vim.env.GRADLE_JAVA_HOME = "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
      local java_home = vim.env.JDTLS_JAVA_HOME
      local gradle_java_home = vim.env.GRADLE_JAVA_HOME

      -- If no JDKs are provided, keep defaults and let LazyVim handle it.
      if java_home == nil or java_home == "" then
        return opts
      end

      local cmd = { vim.fn.exepath("jdtls") }
      if require("lazyvim.util").has("mason.nvim") then
        local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
        table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
      end
      table.insert(cmd, "--java-executable")
      table.insert(cmd, java_home .. "/bin/java")

      opts.jdtls = vim.tbl_deep_extend("force", opts.jdtls or {}, {
        cmd = cmd,
        cmd_env = (gradle_java_home ~= nil and gradle_java_home ~= "") and {
          JAVA_HOME = gradle_java_home,
          GRADLE_OPTS = "-Dorg.gradle.java.home=" .. gradle_java_home,
        } or nil,
      })

      -- Disable java-test bundle loading to avoid bundle errors.
      opts.test = false

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          import = {
            gradle = (gradle_java_home ~= nil and gradle_java_home ~= "") and {
              java = {
                home = gradle_java_home,
              },
            } or nil,
          },
        },
      })
    end,
  },
}
