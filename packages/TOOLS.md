# Tools Reference

패키지 목록에 포함된 도구들의 용도와 기본 사용법 정리.

> 범례: **B** = Brewfile (macOS), **S** = scoop-packages.txt (Windows), **C** = Brewfile.cask

---

## 셸 & 터미널

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `zsh-autosuggestions` | B | 이전 명령어 기반 자동 완성 제안 (회색 텍스트로 표시, → 키로 수락) |
| `zsh-syntax-highlighting` | B | 셸 입력 시 실시간 구문 강조 (유효 명령=초록, 오류=빨강) |
| `starship` | S | 크로스 플랫폼 프롬프트. Git 상태, 언어 버전 등을 프롬프트에 표시 |
| `tmux` | B | 터미널 멀티플렉서. 세션 유지, 화면 분할, 다중 창 관리 |

```bash
# tmux: 새 세션 생성 / 기존 세션 복귀
tmux new -s work
tmux attach -t work
```

## 파일 탐색 & 검색

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `fd` | B S | `find` 대체. 빠른 파일 검색, 직관적 문법 |
| `ripgrep` | B S | `grep` 대체. 초고속 텍스트 검색, `.gitignore` 자동 반영 |
| `fzf` | B S | 범용 퍼지 파인더. 파이프라인과 조합해 대화형 선택 |
| `tree` | B | 디렉터리 구조를 트리 형태로 출력 |
| `autojump` | B | 자주 방문한 디렉터리로 빠르게 이동 (`j` 명령) |
| `zoxide` | S | `autojump`/`z` 대체. 스마트 디렉터리 점프 (`z` 명령) |

```bash
# fd: 현재 디렉터리에서 .ts 파일 검색
fd -e ts

# ripgrep: 패턴 검색 (대소문자 무시)
rg -i "todo" --type ts

# fzf: 파일 선택 → vim으로 열기
vim $(fzf)

# autojump / zoxide: 디렉터리 점프
j dotfiles    # autojump (macOS)
z dotfiles    # zoxide (Windows)
```

## Git & 버전 관리

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `lazygit` | B S | Git TUI 클라이언트. 스테이징, 커밋, 리베이스를 키보드로 조작 |
| `git-lfs` | B S | Git Large File Storage. 대용량 파일(바이너리, 이미지 등)을 Git에서 효율적으로 관리 |

```bash
# lazygit: 현재 저장소에서 실행
lazygit

# git-lfs: 대용량 파일 추적 설정
git lfs install
git lfs track "*.psd"
```

## 텍스트 편집

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `neovim` | B S | Vim 기반 모던 에디터. Lua 설정, 비동기 플러그인 지원 |
| `tree-sitter` | S | 증분 파싱 라이브러리. Neovim 구문 강조·코드 접기에 사용 |

## 데이터 처리 & 네트워크

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `jq` | B S | CLI JSON 프로세서. JSON 필터링, 변환, 포맷팅 |
| `bat` | B | `cat` 대체. 구문 강조, 행 번호, Git 변경 표시 |
| `wget` | B | HTTP/FTP 파일 다운로더 |
| `libpq` | B | PostgreSQL 클라이언트 라이브러리. `psql` CLI 포함 (서버 없이 원격 DB 접속용) |

```bash
# jq: JSON에서 특정 필드 추출
curl -s https://api.example.com/data | jq '.items[].name'

# bat: 구문 강조로 파일 보기
bat src/main.ts
```

## 언어 버전 관리

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `nvm` | B S | Node.js 버전 관리자 |
| `pyenv` | B | Python 버전 관리자 |
| `pyenv-virtualenv` | B | pyenv용 가상환경 플러그인 |
| `jenv` | B S | Java 버전 전환 도구 (JDK는 별도 설치) |
| `rbenv` | B | Ruby 버전 관리자 |
| `python` | S | Windows용 Python (Scoop으로 설치) |
| `uv` | S | 초고속 Python 패키지 매니저 & 가상환경 도구 (pip/venv 대체) |

```bash
# nvm: Node.js 설치 및 전환
nvm install 20
nvm use 20

# pyenv: Python 설치 및 전환
pyenv install 3.12.0
pyenv global 3.12.0

# uv: 가상환경 생성 및 패키지 설치
uv venv
uv pip install requests

# jenv: 시스템에 설치된 JDK 등록 및 전환
jenv add /path/to/jdk
jenv global 21
```

## 빌드 & 컴파일 (Windows)

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `gcc` | S | GNU C/C++ 컴파일러 |
| `mingw` | S | Windows용 GCC 툴체인 (네이티브 바이너리 빌드) |

## 유틸리티 (Windows)

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `7zip` | S | 범용 압축/해제 도구 |
| `dark` | S | WiX Decompiler. MSI 설치 파일 분석용 |
| `opencode` | S | 터미널 기반 AI 코딩 어시스턴트 |

## GUI 앱 & 폰트 (macOS Cask)

| 도구 | 플랫폼 | 설명 |
|------|--------|------|
| `google-chrome` | C | 웹 브라우저 |
| `jetbrains-toolbox` | C | JetBrains IDE 통합 관리자 (IntelliJ, WebStorm 등) |
| `font-hack-nerd-font` | C | Hack 폰트 + Nerd Font 아이콘 패치 (터미널용) |
| `font-symbols-only-nerd-font` | C | Nerd Font 아이콘 심볼만 포함 (기존 폰트와 조합용) |
| `JetBrainsMono-NF` | S | JetBrains Mono + Nerd Font (Windows용) |
