## .bashrc 링크 - Non login bash startup file
```sh
ln -s $PWD/bashrc ~/.bashrc
```

## .bash_profile - Login bash startup file
```sh
$ ln -s $PWD/bash_profile ~/.bash_profile
```

## .zshrc - zshell 설정
```sh
brew install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" # oh-my-zsh 다운로드
ln -s $PWD/zshrc ~/.zshrc
```

## .ssh - ssh 인증 설정
```sh
# 인증서 네이밍룰은 id-rsa*로 해서 버전 관리 별도로 되지 않도록 >> .gitignore 
ln -s $PWD/ssh ~/.ssh
```

## .ideavimrc 링크 - intellij vim 플러그인 설정
```sh
ln -s $PWD/ideavimrc ~/.ideavimrc
```

## neovim 링크 - neovim link
1. vim-plug 설치
- [vim-plug#unix-linux](https://github.com/junegunn/vim-plug)
```sh
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```
 
2. soft link 생성
```sh
mkdir -p ~/.config
ln -s $PWD/nvim ~/.config/nvim
```

## gitconfig 링크 - 계정 정보 개별화
```sh
ln -s $PWD/gitconfig ~/.gitconfig
```

## hammerspoon 링크
```sh
ln -s $PWD/hammerspoon ~/.hammerspoon # pc 권한 허용 별도 필요
```

## tmux 설정 링크
```sh
ln -s $PWD/tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```
