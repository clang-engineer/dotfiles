return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local function present(value)
        return value ~= nil and value ~= ""
      end

      -- JDK paths injected by jvm-env.nvim at startup:
      --   JDTLS_JAVA_HOME  = JDK used to run jdtls
      --   GRADLE_JAVA_HOME = JDK used by Gradle
      local java_home = vim.env.JDTLS_JAVA_HOME
      local gradle_java_home = vim.env.GRADLE_JAVA_HOME

      -- If no JDKs are provided, keep defaults and let LazyVim handle it.
      if not present(java_home) then
        return opts
      end

      -- jdtls runtime: optional Lombok agent.
      local cmd = { vim.fn.exepath("jdtls") }
      if require("lazyvim.util").has("mason.nvim") then
        local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
        if present(lombok_jar) then
          table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
        end
      end
      -- jdtls runtime: throughput GC tuning (jdtls' own recommended args, which
      -- mason's launcher omits). Cuts GC overhead during indexing. Heap (-Xmx)
      -- left at the JVM default on purpose: 16GB RAM is tight, raising it risks swap.
      for _, arg in ipairs({
        "-XX:+UseParallelGC",
        "-XX:GCTimeRatio=4",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-Dsun.zip.disableMemoryMapping=true",
      }) do
        table.insert(cmd, "--jvm-arg=" .. arg)
      end
      -- jdtls runtime: pin the JDK used to start the server.
      table.insert(cmd, "--java-executable")
      table.insert(cmd, java_home .. "/bin/java")

      -- Gradle runtime (separate from jdtls when provided).
      opts.jdtls = vim.tbl_deep_extend("force", opts.jdtls or {}, {
        cmd = cmd,
        cmd_env = present(gradle_java_home) and {
          JAVA_HOME = gradle_java_home,
          GRADLE_OPTS = "-Dorg.gradle.java.home=" .. gradle_java_home,
        } or nil,
      })
    end,
  },
}
