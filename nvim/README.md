# Neovim 구성 안내

이 디렉터리는 두 가지 구성을 제공합니다.

| 디렉터리 | 설명 | 주요 용도 |
| --- | --- | --- |
| `nvim/lazy/` | LazyVim 기반 Lua 설정. `lua/` 이하에 플러그인과 설정이 모듈화되어 있습니다. | 최신 플러그인 생태계를 빠르게 정리하고 싶을 때.
| `nvim/classic/` | Vimscript 중심의 레거시 구성. 최소 의존성과 단순한 키맵을 유지합니다. | 서버·CI 등 보수적인 환경.

## 설치 / 전환 방법

### macOS / Linux

- 전체 부트스트랩 시: `./scripts/unix/setup.sh` (기본 LazyVim) 또는 `./scripts/unix/setup.sh --vim classic`.
- 특정 구성만 교체하려면:

  ```bash
  mkdir -p ~/.config
  ln -snf "$PWD/nvim/lazy" ~/.config/nvim      # LazyVim
  ln -snf "$PWD/nvim/classic" ~/.config/nvim   # Classic
  ```

- 구성 변경 직후 `nvim --headless "+Lazy sync" +qa`를 실행하면 LazyVim 플러그인이 최신 상태인지 확인할 수 있습니다.

### Windows

- PowerShell에서 `./scripts/windows/setup-nvim.ps1`를 실행하면 LazyVim 구성이 `%LOCALAPPDATA%/nvim`에 Junction으로 연결됩니다.
- Classic으로 전환하려면 기존 Junction을 제거하고 다음 명령을 실행합니다.

  ```powershell
  cmd /c rmdir %LOCALAPPDATA%\nvim
  cmd /c mklink /J %LOCALAPPDATA%\nvim %USERPROFILE%\dotfiles\nvim\classic
  ```

## 추천 흐름

- LazyVim: `nvim/lazy/init.lua` 에서 필요한 플러그인을 선언하고 `nvim/lazy/lua/plugins/`에 세부 구성을 분리합니다. `docs/java-env.md` 처럼 개별 기능 문서를 `docs/` 아래에 추가하면 재사용이 쉬워집니다.
- Classic: `nvim/classic/init.vim`(또는 동일 루트의 Vimscript)을 수정하면 되며, Vimscript 스타일은 `snake_case` 오토커맨드/함수 규칙을 따릅니다.

## 전환 체크리스트

1. 기존 `~/.config/nvim` 또는 `%LOCALAPPDATA%/nvim` 링크를 제거합니다.
2. 새 구성을 링크합니다.
3. LazyVim 사용 시 `nvim --headless "+Lazy! sync" +qa`로 플러그인 메타데이터를 갱신합니다.
4. tmux/IDE에서 `nvim`을 다시 열고 `:checkhealth`로 상태를 확인합니다.
5. Java나 언어별 설정이 필요한 프로젝트라면 `.nvim.lua`를 생성하고 `docs/java-env.md`를 참고합니다.

## 문제 해결

- `:checkhealth` 출력에서 LuaRocks, node, python3 등 의존성이 없으면 Brew/Scoop로 설치한 뒤 다시 실행합니다.
- LazyVim 플러그인 설치 중 오류가 발생하면 `rm -rf ~/.local/share/nvim`(또는 Windows `%LOCALAPPDATA%\nvim-data`) 후 `nvim --headless "+Lazy sync" +qa`를 재실행합니다.
- Classic 구성은 `:PlugStatus`(vim-plug)와 같은 플러그인 매니저 출력을 확인하세요.
