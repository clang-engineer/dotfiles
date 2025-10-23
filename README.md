# Dotfiles 설정 가이드

## 저장소 구조
- `home/`: `$HOME` 아래에 바로 매핑되는 파일과 디렉터리 (예: `.bashrc`, `.zshrc`, `.tmux.conf`, `.gitconfig`, `.hammerspoon`, `.ssh`).
- `configs/`: 도구별로 별도 경로가 필요한 설정. 현재는 기본 LazyVim(`nvim-lazy/`)과 고전 Vimscript(`nvim-classic/`) 구성이 들어 있습니다.
- `scripts/`: `bootstrap.sh` 등 자동화 스크립트가 위치합니다.

## 빠른 시작
```sh
./scripts/bootstrap.sh
```
스크립트를 실행하면 `home/` 이하의 파일들을 홈 디렉터리에 심볼릭 링크하고, 기본값으로 `configs/nvim-lazy/`를 `~/.config/nvim`에 연결한 뒤 tmux 설정을 다시 로드합니다.

### 옵션
- `--force`: 대상 위치에 있는 기존 파일이나 링크를 덮어씁니다.
- `--vim classic`: LazyVim 대신 `configs/nvim-classic/`에 있는 Vimscript 구성을 사용합니다.
- `--help`: 사용법을 출력합니다.

필요한 패키지를 한 번에 설치하려면 부트스트랩 후 `brew bundle install --file Brewfile`를 실행하세요.

## 수동 링크 (선택 사항)
각 항목을 개별적으로 링크하고 싶다면 다음 명령을 참고하세요.
```sh
ln -s "$PWD/home/.bashrc" ~/.bashrc
ln -s "$PWD/home/.bash_profile" ~/.bash_profile
ln -s "$PWD/home/.zshrc" ~/.zshrc
ln -s "$PWD/home/.gitconfig" ~/.gitconfig
ln -s "$PWD/home/.tmux.conf" ~/.tmux.conf
tmux source-file ~/.tmux.conf
ln -s "$PWD/home/.ideavimrc" ~/.ideavimrc
ln -s "$PWD/home/.hammerspoon" ~/.hammerspoon
ln -s "$PWD/home/.ssh" ~/.ssh        # 실제 키는 커밋하지 말고, 템플릿을 추가하면 .gitignore도 갱신하세요
ln -s "$PWD/home/.clang-format" ~/.clang-format
mkdir -p ~/.config
ln -s "$PWD/configs/nvim-lazy" ~/.config/nvim   # 클래식 구성을 쓰려면 "$PWD/configs/nvim-classic" 사용
```
