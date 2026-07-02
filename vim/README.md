# Vim (Legacy)

옛 Vim 설정 아카이브. 현재 부트스트랩에서 **자동 링크하지 않는다**. 필요할 때 수동으로 링크해서 쓴다.

## 두 스냅샷

| 파일 | 플러그인 매니저 | 비고 |
| --- | --- | --- |
| `init.vim` | [vim-plug](https://github.com/junegunn/vim-plug) + [coc.nvim](https://github.com/neoclide/coc.nvim) | 보다 최신 스냅샷. `vim-custom/`, `vim-plugin/`, `templates/`, `coc-settings.json` 동반. |
| `.vimrc` | [Vundle](https://github.com/VundleVim/Vundle.vim) | 더 옛 스냅샷. 단독 파일. |

## 수동 링크

```bash
# vim-plug + coc 스냅샷 사용
ln -snf "$PWD/vim/init.vim" ~/.vimrc

# 또는 Vundle 스냅샷 사용
ln -snf "$PWD/vim/.vimrc" ~/.vimrc
```

플러그인 설치는 각 매니저의 표준 절차를 따른다(vim-plug: `:PlugInstall`, Vundle: `:PluginInstall`).
