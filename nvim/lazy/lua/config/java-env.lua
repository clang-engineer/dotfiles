-- Java environment configuration for nvim-jdtls
-- Usage in project .nvim.lua:
--   require("config.java-env").setup()
--   require("config.java-env").setup({ jdtls = "21", gradle = "17" })

local M = {}

local uname = vim.loop.os_uname()
local is_windows = uname.sysname:match("Windows") ~= nil
local is_macos = uname.sysname == "Darwin"

local function find_java(version)
  if is_windows then
    -- Windows: use glob with proper patterns
    local patterns = {
      "C:\\Program Files\\Eclipse Adoptium\\jdk-" .. version .. "*",
      "C:\\Program Files\\Java\\jdk-" .. version .. "*",
      "C:\\Program Files\\Microsoft\\jdk-" .. version .. "*",
    }
    for _, pattern in ipairs(patterns) do
      local expanded = vim.fn.glob(pattern)
      if expanded ~= "" then
        return vim.fn.split(expanded, "\n")[1]
      end
    end
    -- fallback: scoop
    local scoop_path = (vim.env.USERPROFILE or "") .. "\\scoop\\apps\\openjdk" .. version .. "\\current"
    if vim.fn.isdirectory(scoop_path) == 1 then
      return scoop_path
    end

  elseif is_macos then
    -- macOS: try jenv first, then java_home
    local jenv = vim.fn.trim(vim.fn.system("jenv prefix " .. version .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and jenv ~= "" then
      return jenv
    end
    local result = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. version .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and result ~= "" then
      return result
    end

  else
    -- Linux
    local paths = {
      "/usr/lib/jvm/java-" .. version .. "-openjdk",
      "/usr/lib/jvm/java-" .. version .. "-openjdk-amd64",
      "/usr/lib/jvm/jdk-" .. version,
      (vim.env.HOME or "") .. "/.sdkman/candidates/java/" .. version .. "*",
    }
    for _, path in ipairs(paths) do
      local expanded = vim.fn.glob(path)
      if expanded ~= "" then
        return vim.fn.split(expanded, "\n")[1]
      end
    end
  end

  return nil
end

function M.setup(opts)
  opts = opts or {}
  local jdtls_ver = opts.jdtls or "21"
  local gradle_ver = opts.gradle or "11"

  local jdtls_path = find_java(jdtls_ver)
  local gradle_path = find_java(gradle_ver)

  if jdtls_path then
    vim.env.JDTLS_JAVA_HOME = jdtls_path
  end
  if gradle_path then
    vim.env.GRADLE_JAVA_HOME = gradle_path
  end
end

return M
