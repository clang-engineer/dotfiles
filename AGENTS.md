# Repository Guidelines

## 프로젝트 구조 및 모듈 구성
이 저장소는 셸, 에디터, 주변 도구 설정을 한곳에 모아 관리합니다. 사용자 홈과 1:1로 매핑되는 파일은 `home/` 아래에 배치되어 있으며 `.bashrc`, `.zshrc`, `.tmux.conf`, `.gitconfig`, `.hammerspoon`, `.ssh`, `.clang-format`, `.vimrc` 등이 포함됩니다. Neovim 설정은 `nvim/`에 있으며 LazyVim 기반 Lua 구성을 담은 `lazy/`와 Vimscript 중심의 `classic/`로 나뉩니다. Brew 기반 개발 환경 정의는 `Brewfile`, `Brewfile.lock.json`에서 찾을 수 있고, 보조 스크립트는 `scripts/`에 정리되어 있습니다.

## 빌드 · 테스트 · 동기화 명령
모든 명령은 저장소 루트에서 실행하세요.
- `./scripts/bootstrap.sh [--force] [--vim classic]` 명령으로 `home/` 전체를 `$HOME` 아래에 링크하고 선택한 Neovim 구성을 `~/.config/nvim`에 배치합니다.
- `brew bundle install --file Brewfile`로 macOS 패키지와 CLI 도구를 설치하며, `brew bundle check --file Brewfile`로 누락 여부를 검증합니다.
- `nvim --headless "+Lazy sync" +qa`를 통해 LazyVim 플러그인을 새로고침하고, `tmux source-file ~/.tmux.conf`로 tmux 설정을 즉시 반영합니다.

## 코딩 스타일 및 네이밍 규칙
셸 스크립트는 두 칸 들여쓰기와 POSIX 호환 문법을 유지합니다. Vimscript는 오토커맨드와 함수 이름에 snake_case를 사용하고, Lua 파일은 `nvim/lazy/stylua.toml`에서 정의한 공백 기반 스타일(Indent 2, Column 120)을 따릅니다. `home/.ssh/config` 안의 호스트 이름은 `service-region-role` 같은 대시 구분 슬러그를 유지하고, 새 파일을 추가할 때는 모두 소문자와 하이픈 중심의 파일명을 권장합니다.

## 테스트 가이드라인
별도의 자동화 테스트는 없으므로 수동 검증이 핵심입니다. Brew 구성을 바꾼 경우 `brew bundle check --file Brewfile`를 실행하고, Neovim 플러그인 구성을 수정했다면 `:checkhealth` 결과를 확인하세요. tmux 키맵, Hammerspoon 스크립트는 각각 새 세션과 메뉴바 재로드를 통해 눈으로 검증하며, 문제가 있었던 환경 변수나 OS 버전 정보는 관련 설정 파일 상단에 주석으로 남깁니다.

## 커밋 및 PR 지침
Git 히스토리처럼 `feat(scope):`, `chore:` 형식의 짧고 목적지향적인 커밋 메시지를 작성하세요. Pull Request에는 수정 대상 구성요소, 수행한 수동 검증 명령, UI 영향을 주는 변경이라면 캡처 또는 GIF, 그리고 연관된 이슈 번호를 포함합니다. 민감 정보가 포함될 가능성이 있는 파일은 `.gitignore`에 추가하고, 필요 시 예제 템플릿만 버전에 포함시킵니다.

## 보안 및 구성 팁
실제 비밀키는 레포지토리에 포함하지 말고 템플릿이나 암호화된 형태만 유지하세요. `home/.ssh/`와 같은 민감 경로는 링크 후 퍼미션을 다시 확인하고, 머신별 절대 경로 대신 `env` 변수나 `$(brew --prefix ...)`를 활용해 이식성을 확보합니다.
