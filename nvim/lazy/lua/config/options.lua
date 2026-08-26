-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

require("config.options.default")
require("config.options.backup-undo")

-- chezmoi encodes target dotfile names in its source filenames, so Neovim cannot
-- infer filetypes such as `dot_zshrc` from an extension. Register the source
-- names explicitly so syntax highlighting and language-aware tooling work.
vim.filetype.add({
  filename = {
    dot_zshrc = "zsh",
    dot_bashrc = "bash",
    dot_bash_profile = "bash",
    dot_gitconfig = "gitconfig",
    ["dot_tmux.conf"] = "tmux",
    ["dot_tmux.conf.local"] = "tmux",
  },
})
