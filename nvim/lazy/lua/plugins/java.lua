return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local function env(name)
        local value = vim.env[name]
        if value == nil or value == "" then
          return nil
        end
        return value
      end

      local function mac_java_home(version)
        if vim.fn.has("macunix") ~= 1 then
          return nil
        end
        local cmd = string.format("/usr/libexec/java_home -v %s", version)
        local value = vim.fn.trim(vim.fn.system(cmd))
        if value == "" then
          return nil
        end
        return value
      end

      -- Prefer explicit env vars, then OS-specific discovery.
      local java_home = env("JDTLS_JAVA_HOME") or mac_java_home("21") or env("JAVA_HOME")
      local gradle_java_home = env("GRADLE_JAVA_HOME") or mac_java_home("17")

      -- If no JDKs are available, keep defaults and let LazyVim handle it.
      if java_home == nil then
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
