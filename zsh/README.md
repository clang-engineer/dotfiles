# Zsh 설정

## 구조

| 파일 | 설명 |
|------|------|
| `.zshrc` | 메인 설정. oh-my-zsh, 플러그인, 버전 매니저, fzf 등 로드 |
| `setup.sh` | oh-my-zsh 및 플러그인 설치 스크립트 |

## .zshrc 로드 순서

1. tmux 자동 실행
2. locale, secrets
3. brew prefix 캐싱
4. oh-my-zsh + 플러그인 (git, brew, zsh-syntax-highlighting, zsh-autosuggestions)
5. 에디터, alias
6. 버전 매니저 (rbenv, nvm, jenv, pyenv)
7. fzf 키바인딩
8. zoxide (autojump 대체, z/zi 명령어)

## fzf 단축키

| 키 | 기능 |
|----|------|
| `Ctrl+R` | 히스토리 퍼지 검색 |
| `Ctrl+T` | 현재 디렉터리 아래 파일/폴더 퍼지 검색 → 커맨드라인에 붙여넣기 |
| `Alt+C` | 디렉터리만 퍼지 검색 → 바로 cd |

## CLI 도구 사용법

### rg (ripgrep) — 텍스트 검색

```bash
rg "TODO"                      # 현재 디렉터리에서 검색
rg "함수명" -t ts              # .ts 파일에서만 검색
rg -i "error" --glob "*.log"   # 대소문자 무시, .log 파일만
```

grep보다 빠르고 `.gitignore`를 자동 무시.

### fd — 파일 검색

```bash
fd -e lua                # .lua 파일 찾기
fd config                # 이름에 config 포함된 파일 찾기
fd -t d src              # 디렉터리만 검색
```

find 대체. 직관적 문법, `.gitignore` 자동 무시.

### bat — 파일 보기

```bash
bat file.sh              # 구문 강조 + 행번호로 파일 보기
bat -l json data.txt     # 언어 지정
```

cat 대체. 구문 강조, Git 변경 표시.

### jq — JSON 처리

```bash
cat data.json | jq '.items[].name'   # 필드 추출
curl -s api.example.com | jq '.'     # JSON 포맷팅
```

### tree — 디렉터리 구조

```bash
tree -L 2                # 2단계까지 출력
tree -I node_modules     # 특정 디렉터리 제외
```

## oh-my-zsh 플러그인

| 플러그인 | 설명 |
|----------|------|
| `git` | Git alias 모음 (`gst`, `gco`, `gp` 등) |
| `brew` | Homebrew 자동완성 |
| `zsh-syntax-highlighting` | 입력 시 실시간 구문 강조 |
| `zsh-autosuggestions` | 이전 명령어 기반 자동 완성 제안 (→ 키로 수락) |
