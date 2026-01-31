# Dotfiles 설정 가이드

## 저장소 구조
- `home/`: `$HOME` 아래에 바로 매핑되는 파일과 디렉터리 (예: `.bashrc`, `.zshrc`, `.tmux.conf`, `.gitconfig`, `.hammerspoon`, `.ssh`).
- `nvim/`: Neovim 설정. LazyVim(`lazy/`)과 고전 Vimscript(`classic/`) 구성으로 나뉩니다.
- `scripts/`: `bootstrap.sh` 등 자동화 스크립트가 위치합니다.

## 빠른 시작
```sh
./scripts/bootstrap.sh
```
스크립트를 실행하면 `home/` 이하의 파일들을 홈 디렉터리에 심볼릭 링크하고, 기본값으로 `nvim/lazy/`를 `~/.config/nvim`에 연결한 뒤 tmux 설정을 다시 로드합니다.

### 옵션
- `--force`: 대상 위치에 있는 기존 파일이나 링크를 덮어씁니다.
- `--vim classic`: LazyVim 대신 `nvim/classic/`에 있는 Vimscript 구성을 사용합니다.
- `--help`: 사용법을 출력합니다.

필요한 패키지를 한 번에 설치하려면 부트스트랩 후 `brew bundle install --file Brewfile`를 실행하세요.

## GitHub 다중 계정 관리

여러 GitHub 계정(개인/회사)을 한 PC에서 관리하기 위한 스크립트를 제공합니다.

### 통합 설정 (추천)
```sh
./scripts/setup-github-account.sh
```
대화형 프롬프트로 다음을 한번에 설정합니다:
1. SSH 키 생성
2. SSH config 추가
3. Workspace별 Git 사용자 설정

### 개별 스크립트

필요한 부분만 설정하고 싶다면:

**1. SSH 키 생성**
```sh
./scripts/generate-ssh-key.sh
./scripts/generate-ssh-key.sh myusername my@email.com
```

**2. SSH config 추가**
```sh
./scripts/add-ssh-config.sh
./scripts/add-ssh-config.sh myusername
```

**3. Git includeIf 설정**
```sh
./scripts/setup-git-includeif.sh
./scripts/setup-git-includeif.sh ~/workspace/company "John Doe" john@company.com
```

### 사용 예시

설정 후 다음과 같이 사용합니다:

```sh
# 리포지토리 클론
git clone git@github.com-myusername:username/repo.git

# 기존 리포지토리 remote URL 변경
git remote set-url origin git@github.com-myusername:username/repo.git

# SSH 연결 테스트
ssh -T git@github.com-myusername
```

workspace 경로에서 작업하면 해당 계정의 Git 사용자 정보가 자동으로 적용됩니다.

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
ln -s "$PWD/nvim/lazy" ~/.config/nvim   # 클래식 구성을 쓰려면 "$PWD/nvim/classic" 사용
```
