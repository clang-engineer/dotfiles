# Changelog

## 2026-03-13 — Brewfile 대규모 정리

### 변경 사유
Brewfile이 오래되어 deprecated tap, EOL 패키지, 미사용 패키지가 다수 포함.
핵심 CLI 도구만 남기고 cask는 별도 파일로 분리.

### Taps 제거 (5개)
| Tap | 제거 사유 |
|-----|-----------|
| `adoptopenjdk/openjdk` | deprecated — Eclipse Adoptium으로 이관됨 |
| `domq/gdb` | Brewfile에 gdb 패키지 없음, 미사용 |
| `homebrew/bundle` | Homebrew에 기본 내장, 명시 불필요 |
| `homebrew/cask-fonts` | `homebrew/cask`에 통합됨 (2023~) |
| `homebrew/services` | 필요 시 자동 설치, 명시 불필요 |

> **참고:** tap은 Homebrew의 서드파티 패키지 저장소 등록 기능.
> 공식 저장소에 없는 패키지를 설치하려면 해당 tap을 먼저 추가해야 한다.
> (Linux apt의 PPA, Windows Scoop의 bucket과 동일한 개념)

### Brew 패키지 제거 (39개)
| 패키지 | 분류 | 제거 사유 |
|--------|------|-----------|
| `openssl@1.1`, `python@3.11`, `python@3.10` | 런타임 | EOL 버전, pyenv로 관리 |
| `libevent`, `p11-kit`, `unbound`, `gnutls`, `guile`, `harfbuzz`, `libtiff`, `libssh2` | 라이브러리 | 다른 패키지의 의존성, 직접 사용 안 함 |
| `emacs`, `cask` | 에디터 | neovim으로 대체 |
| `ccache`, `llvm`, `ccls`, `clang-format`, `cmake`, `cpplint`, `gcc`, `googletest`, `swig`, `universal-ctags` | C/C++ 도구 | 프로젝트별 필요 시 개별 설치 |
| `go`, `goaccess` | Go | 미사용 |
| `gnupg` | 보안 | 미사용 |
| `grafana`, `prometheus` | 모니터링 | 로컬 개발에 불필요 |
| `h2`, `httpie` | HTTP | 미사용 |
| `ipython`, `luarocks` | REPL/패키지 | 미사용 |
| `jmeter`, `sonar-scanner`, `swagger-codegen` | Java/QA 도구 | 미사용 |
| `make` | 빌드 | macOS 기본 내장 |
| `mas` | Mac App Store | 미사용 |
| `maven` | Java 빌드 | IDE에서 관리 |
| `nginx`, `tomcat`, `tomcat@8` | 서버 | 로컬 개발에 불필요 |
| `nmap`, `telnet`, `spoof-mac` | 네트워크 | 미사용 |
| `node`, `node-build`, `nodenv` | Node.js | nvm으로 통합 |
| `postgresql@14` | DB | 미사용 |
| `rclone` | 클라우드 동기화 | 미사용 |
| `redis` | DB | 미사용 |
| `rename` | 파일 유틸 | 미사용 |
| `the_silver_searcher` | 검색 | ripgrep으로 대체 |
| `yarn` | JS 패키지 | npm으로 충분 |
| `ack` | 검색 | ripgrep으로 대체 |

### Cask 변경
- `klogg`, `redis-insight` 제거 (미사용)
- 나머지 4개 cask → `Brewfile.cask`로 분리

### 유지된 패키지 (20개 brew + 4개 cask)
- **Brew:** autojump, bat, fd, fzf, git-lfs, jenv, jq, lazygit, libpq, neovim, nvm, pyenv, pyenv-virtualenv, rbenv, ripgrep, tmux, tree, wget, zsh-autosuggestions, zsh-syntax-highlighting
- **Cask:** font-hack-nerd-font, font-symbols-only-nerd-font, google-chrome, jetbrains-toolbox
