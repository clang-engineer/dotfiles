-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Setup Java environment (before jdtls starts)
require("config.java-env").setup()

-- cheatsheet 빠른 뷰어 (:Toolbox / :ToolboxGrep)
require("config.cheatsheet")
