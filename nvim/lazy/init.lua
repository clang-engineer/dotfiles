-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- toolbox 빠른 뷰어 (:Toolbox / :ToolboxGrep)
require("toolbox").setup()

-- quicklinks 통합 픽커 (:Quicklinks / :QuicklinksAdd / :QuicklinksEdit)
require("quicklinks").setup()
