# Vim (Legacy)

Archive of old Vim configs. The current bootstrap does **not** auto-link these. Link them manually when needed.

## Two snapshots

| File | Plugin manager | Notes |
| --- | --- | --- |
| `init.vim` | [vim-plug](https://github.com/junegunn/vim-plug) + [coc.nvim](https://github.com/neoclide/coc.nvim) | Newer snapshot. Comes with `vim-custom/`, `vim-plugin/`, `templates/`, `coc-settings.json`. |
| `.vimrc` | [Vundle](https://github.com/VundleVim/Vundle.vim) | Older snapshot. Standalone file. |

## Manual linking

```bash
# Use the vim-plug + coc snapshot
ln -snf "$PWD/vim/init.vim" ~/.vimrc

# Or use the Vundle snapshot
ln -snf "$PWD/vim/.vimrc" ~/.vimrc
```

Install plugins following each manager's standard procedure (vim-plug: `:PlugInstall`, Vundle: `:PluginInstall`).
