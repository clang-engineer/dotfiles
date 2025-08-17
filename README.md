```sh
# .bash 설정
ln -s $PWD/bashrc ~/.bashrc
ln -s $PWD/bash_profile ~/.bash_profile

# .zshrc - zshell 설정
ln -s $PWD/bashrc ~/.bashrc

# ssh 설정
ln -s $PWD/ssh ~/.ssh # 인증서 네이밍룰은 id-rsa*로 해서 버전 관리 별도로 되지 않도록 >> .gitignore 

# neovim 설정
mkdir -p ~/.config
ln -s $PWD/nvim ~/.config/nvim

# tmux 설정
ln -s $PWD/tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf

ln -s $PWD/gitconfig ~/.gitconfig  # git 설정
ln -s $PWD/hammerspoon ~/.hammerspoon # hammerspoon 설정, 권한 설정 및 자동 실행 설정 필요
ln -s $PWD/ideavimrc ~/.ideavimrc # intellij vim 설정
```
