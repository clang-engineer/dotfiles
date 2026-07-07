# packages

패키지 **목록(선언적 데이터)** 디렉터리. 설치 스크립트는 `scripts/windows/`에 있다.

## 구조

| 파일 | 설명 |
|------|------|
| `scoop-packages.txt` | Windows Scoop 패키지 목록 |
| `Brewfile` | macOS Homebrew CLI 패키지 목록 |
| `Brewfile.cask` | macOS Homebrew Cask (GUI 앱·폰트) 목록 |

## 설치

### Windows (Scoop)

```powershell
.\scripts\windows\install-packages.ps1
```

이미 설치된 패키지를 강제 재설치하려면:

```powershell
.\scripts\windows\install-packages.ps1 -Force
```

### macOS (Homebrew)

```bash
brew bundle --file=packages/Brewfile
brew bundle --file=packages/Brewfile.cask
```

## 패키지 목록 최신화 (현재 PC → 파일)

### Scoop

현재 PC에 설치된 패키지로 `scoop-packages.txt`를 갱신한다.

```powershell
scoop list | Select-Object -Skip 2 | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ -and $_ -ne '----' -and $_ -ne 'Name' } | Sort-Object | Set-Content packages/scoop-packages.txt
```

설치 실패 등 비정상 패키지가 있으면 `scoop list`에서 상태를 확인한 뒤 수동으로 제거한다.

### Homebrew

```bash
brew bundle dump --file=packages/Brewfile --force
```

## 패키지 추가/제거

1. `scoop-packages.txt` 또는 `Brewfile`을 직접 편집
2. 설치 스크립트를 다시 실행

## 설치된 모던 도구 사용법

Brewfile에 든 도구를 어떻게 설정해 쓰는지 요약. 키바인딩·alias는 `chezmoi/dot_zshrc`, git 페이저는 `chezmoi/dot_gitconfig`에 정의됨.

| 도구 | 사용법 | 설정 위치 |
|------|--------|-----------|
| `eza` | `ls` 그대로 (alias). 아이콘·git 상태 포함 | `.zshrc` alias |
| `bat` | `cat` 그대로 (alias). 구문강조·행번호. fzf 미리보기 백엔드 | `.zshrc` alias |
| `zoxide` | `z <경로일부>`로 자주 간 폴더 점프, `zi`는 후보 목록 선택 | `.zshrc` (`zoxide init`) |
| `fzf` | `Ctrl+T` 파일 선택 · `Ctrl+R` 히스토리 검색 · `Alt+C` 디렉터리 이동 | `.zshrc` (`fzf --zsh`) |
| `ripgrep` | `rg <패턴>` 초고속 검색. neovim grep 백엔드 | 기본 |
| `fd` | `fd <이름>` 직관적 파일 검색 (`find` 대체) | 기본 |
| `lazygit` | `lazygit` 실행 (스테이징·리베이스 TUI). Neovim에선 `<leader>gg` | LazyVim 통합 |
| `delta` | `git diff`/`show`/`log -p` 시 자동 적용 (별도 명령 없음) | `.gitconfig` `core.pager` |
| `gh` | `gh pr create` · `gh issue list` · `gh repo view` 등 GitHub CLI | 기본 |
| `tldr` | `tldr <명령>` — man 대신 핵심 예시만 | 기본 |

## 참고: 추가로 쓸 만한 도구

필요할 때 개별 설치. Brewfile에는 포함하지 않음.

| 도구 | 용도 | 대체 대상 |
|------|------|-----------|
| `eza` | 파일 목록 (아이콘, Git 상태 표시) | `ls` |
| `zoxide` | 스마트 디렉터리 점프 | `cd`/`autojump` |
| `delta` | Git diff 구문 강조 | `git diff` |
| `atuin` | 셸 히스토리 DB (맥락 기록·기기 간 동기화) | `Ctrl+R` / `fzf` 히스토리 |
| `tldr` | 명령어 요약 도움말 | `man` |
| `htop` | 프로세스 모니터 | `top` |
| `dust` | 디스크 사용량 시각화 | `du` |

### 향후 추가해볼 만한 설정

현재 셋업은 모던 CLI 풀세트가 거의 다 갖춰짐. 실질적으로 더 볼 후보:

- **`atuin`** — `fzf --zsh`로 `Ctrl+R` 퍼지 히스토리를 이미 쓰므로 빈 구멍이 아니라 업그레이드. 추가 이점은 실행 디렉토리·종료코드 맥락 필터 + 기기 간 동기화. **맥 여러 대를 쓰거나 맥락 검색이 잦을 때만** 값을 함.

참고: p10k에 `direnv` 세그먼트가 켜져 있으나 Brewfile 미포함 + zshrc hook 없음. 프로젝트별 env var가 필요하면 마저 붙이고, 안 쓰면 p10k에서 제거.
