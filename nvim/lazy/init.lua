-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- toolbox quick viewer (:Toolbox / :ToolboxGrep)
require("user.toolbox").setup()

-- quicklinks unified picker (:Quicklinks / :QuicklinksAdd / :QuicklinksEdit)
require("user.quicklinks").setup()
