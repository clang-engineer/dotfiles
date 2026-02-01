return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local java_home = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21"))
      local gradle_java_home = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 17"))
      if java_home == "" then
        return opts
      end

      if gradle_java_home == "" then
        gradle_java_home = nil
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
        cmd_env = gradle_java_home and {
          JAVA_HOME = gradle_java_home,
          GRADLE_OPTS = "-Dorg.gradle.java.home=" .. gradle_java_home,
        } or nil,
      })

      -- Disable java-test bundle loading to avoid bundle errors.
      opts.test = false

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          import = {
            gradle = gradle_java_home and {
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
