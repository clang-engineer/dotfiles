# my dotfiles

# .dotfiles 다운로드 
```sh
$ git clone https://github.com/yorez/dotfiles.git ~/.dotfiles
```

## .bashrc 링크 - Non login bash startup file
```sh
$ ln -s $PWD/.bashrc ~/.bashrc
```

## .bash_profile - Login bash startup file
```sh
$ ln -s $PWD/.bash_profile ~/.bash_profile
```

## .vimrc 링크- vim 기본 설정 파일

1. vundle 설치
```sh
$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

2. soft link 생성
```sh
$ ln -s $PWD/.vimrc ~/.vimrc
```

## .ideavimrc 링크 - intellij vim 플러그인 설정
```sh
$ ln -s $PWD/.vimrc ~/.vimrc
```


## neovim 링크 - neovim link

1. vim-plug 설치
- [vim-plug#unix-linux](https://github.com/junegunn/vim-plug)
 
2. soft link 생성
```sh
$ mkdir -p ~/.config
$ ln -s $PWD/nvim ~/.config/nvim
```

```sh
$ sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```
