-- Filetype mappings for chezmoi source names whose target extensions are encoded
-- in the source filename (for example dot_zshrc -> ~/.zshrc).
vim.filetype.add({
  pattern = {
    [".*/chezmoi/dot_zshrc"] = "zsh",
    [".*/chezmoi/dot_bashrc"] = "bash",
    [".*/chezmoi/dot_bash_profile"] = "bash",
    [".*/chezmoi/dot_gitconfig"] = "gitconfig",
    [".*/chezmoi/dot_tmux%.conf"] = "tmux",
    [".*/chezmoi/dot_tmux%.conf%.local"] = "tmux",
  },
})
