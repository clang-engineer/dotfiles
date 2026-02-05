-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Setup Java environment (before jdtls starts)
require("config.java-env").setup()
