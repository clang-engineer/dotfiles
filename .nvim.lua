-- Cross-platform Java path configuration for Neovim
-- Copy this file to your project root directory

local uname = vim.loop.os_uname()
local is_windows = uname.sysname:match("Windows") ~= nil
local is_macos = uname.sysname == "Darwin"

local java21_path = nil
local java11_path = nil

if is_windows then
  -- Windows: check env vars first, then common paths
  java21_path = vim.env.JAVA21_HOME
  java11_path = vim.env.JAVA11_HOME

  if not java21_path or not java11_path then
    local function find_java_win(version)
      local paths = {
        "C:/Program Files/Java/jdk-" .. version,
        "C:/Program Files/Eclipse Adoptium/jdk-" .. version .. "*",
        "C:/Program Files/Microsoft/jdk-" .. version .. "*",
        (vim.env.USERPROFILE or "") .. "/scoop/apps/openjdk" .. version .. "/current",
      }
      for _, path in ipairs(paths) do
        local expanded = vim.fn.glob(path)
        if expanded ~= "" then
          return vim.fn.split(expanded, "\n")[1]
        end
      end
      return nil
    end

    java21_path = java21_path or find_java_win("21")
    java11_path = java11_path or find_java_win("11")
  end

elseif is_macos then
  -- macOS: use java_home command
  local function get_java_home(version)
    local result = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. version .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and result ~= "" then
      return result
    end
    return nil
  end

  java21_path = vim.env.JAVA21_HOME or get_java_home("21")
  java11_path = vim.env.JAVA11_HOME or get_java_home("11")

else
  -- Linux: check env vars, then common paths
  java21_path = vim.env.JAVA21_HOME
  java11_path = vim.env.JAVA11_HOME

  if not java21_path or not java11_path then
    local function find_java_linux(version)
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
      return nil
    end

    java21_path = java21_path or find_java_linux("21")
    java11_path = java11_path or find_java_linux("11")
  end
end

-- Set environment variables
if java21_path then
  vim.env.JDTLS_JAVA_HOME = java21_path
end
if java11_path then
  vim.env.GRADLE_JAVA_HOME = java11_path
end

-- Debug output (uncomment to troubleshoot)
-- print(string.format("OS: %s | JDTLS: %s | GRADLE: %s",
--   uname.sysname,
--   vim.env.JDTLS_JAVA_HOME or "not found",
--   vim.env.GRADLE_JAVA_HOME or "not found"))
