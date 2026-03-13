-- Windows Java path configuration for Neovim

local java21_path = vim.env.JAVA21_HOME or "C:/Program Files/Java/jdk-21"
local java11_path = vim.env.JAVA11_HOME or "C:/Program Files/Java/jdk-11"

vim.env.JDTLS_JAVA_HOME = java21_path
vim.env.GRADLE_JAVA_HOME = java11_path
