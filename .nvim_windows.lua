-- Windows Java path configuration for Neovim
-- Modify paths according to your environment

local java21_path = "C:/Program Files/Java/jdk-21"
local java11_path = "C:/Program Files/Java/jdk-11"

-- Use environment variables if set
if vim.env.JAVA21_HOME then
  java21_path = vim.env.JAVA21_HOME
end
if vim.env.JAVA11_HOME then
  java11_path = vim.env.JAVA11_HOME
end

-- Fallback: try to find Java in common locations
local function find_java(version)
  local paths = {
    "C:/Program Files/Java/jdk-" .. version,
    "C:/Program Files/Eclipse Adoptium/jdk-" .. version .. "*",
    "C:/Program Files/Microsoft/jdk-" .. version .. "*",
    vim.env.USERPROFILE .. "/scoop/apps/openjdk" .. version .. "/current",
  }
  for _, path in ipairs(paths) do
    local expanded = vim.fn.glob(path)
    if expanded ~= "" then
      return vim.fn.split(expanded, "\n")[1]
    end
  end
  return nil
end

-- Try to auto-detect if env vars not set
if not vim.env.JAVA21_HOME then
  local found = find_java("21")
  if found then java21_path = found end
end
if not vim.env.JAVA11_HOME then
  local found = find_java("11")
  if found then java11_path = found end
end

vim.env.JDTLS_JAVA_HOME = java21_path
vim.env.GRADLE_JAVA_HOME = java11_path

-- Optional: Print paths for debugging (comment out in production)
-- print("JDTLS_JAVA_HOME: " .. vim.env.JDTLS_JAVA_HOME)
-- print("GRADLE_JAVA_HOME: " .. vim.env.GRADLE_JAVA_HOME)
