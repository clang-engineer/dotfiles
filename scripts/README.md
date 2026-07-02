# Scripts

부트스트랩이 호출하는 보조 스크립트와 공용 라이브러리가 `scripts/` 아래에 모여 있습니다. 진입점은 저장소 루트의 `bootstrap.sh` / `bootstrap.ps1` 입니다.

## 구조

```
scripts/
├── README.md
├── setup-secrets.sh            # 환경 변수 비밀 설정
├── setup-java-versions.sh      # jenv 기반 Java 버전 설정
├── lib/
│   ├── common.sh               # 공용 함수 (link_path, ensure_dir)
│   └── common.ps1              # 공용 함수 (Write-TaskHeader, New-Junction)
└── windows/
    └── opt/*.ps1               # 보조 스크립트 (폰트, 터미널 등)
```

## 실행 요약

| 목적 | macOS/Linux | Windows | 비고 |
| --- | --- | --- | --- |
| 전체 환경 부트스트랩 | `./bootstrap.sh [--force]` | `.\bootstrap.ps1 [-Force]` | 모듈별 링킹 + 패키지 설치를 한 번에 수행합니다. |
| 개별 모듈 링킹 | `./zsh/setup.sh`, `./tmux/setup.sh` 등 | `.\home\setup.ps1`, `.\nvim\setup.ps1` 등 | 필요한 모듈만 골라 실행하세요. |
| 선택형 도구 | `./ssh/generate-key.sh` 등 | `.\scripts\windows\opt\update-terminal.ps1` 등 | 상황별 헬퍼입니다. |

## Unix (macOS/Linux)

### 개별 모듈 실행

```sh
./home/setup.sh              # 단독 설정 파일 링킹
./zsh/setup.sh               # zsh 설정 링킹 + oh-my-zsh/플러그인 설치
./tmux/setup.sh              # tmux 설정 링킹 + TPM 설치
./git/setup.sh               # .gitconfig 링킹
./claude/setup.sh            # ~/.claude 링킹
./ssh/setup.sh               # ~/.ssh 링킹
./hammerspoon/setup.sh       # ~/.hammerspoon 링킹
./nvim/setup.sh              # ~/.config/nvim 링킹
```

### Optional helpers

```sh
./ssh/generate-key.sh                 # SSH 키 생성 (label, email)
./git/add-workspace-user.sh           # workspace별 Git user 등록 (includeIf)
./scripts/setup-java-versions.sh      # jenv 기반 Java 버전 설정
```

> Neovim Java LSP의 `.nvim.lua`는 셸 스크립트가 아니라 nvim 명령 `:JvmEnvInit`로 생성합니다 (`nvim/docs/java-lsp.md`).

## Windows

### 구조

```
scripts/windows/
└── opt/
    ├── install-font.ps1         # Nerd Font 설치
    └── update-terminal.ps1      # Windows Terminal 설정 (폰트/투명도 패치)
```

### 개별 모듈 실행

```powershell
.\home\setup.ps1       # PowerShell 프로필 링크
.\nvim\setup.ps1       # Neovim Junction 링크
.\git\setup.ps1        # ~\.gitconfig 링크
.\ssh\setup.ps1        # ~\.ssh 링크
```

### Optional helpers (Windows)

```powershell
.\ssh\generate-key.ps1                  # SSH 키 생성 (Label, Email)
.\git\add-workspace-user.ps1            # workspace별 Git user 등록 (includeIf)
```

### Notes

- Assumes dotfiles are at `C:\Users\<you>\dotfiles`
- Installs lazygit and Windows-native CLI tools via Scoop
- Packages are read from `packages/scoop-packages.txt` (one per line)
- Updates Windows Terminal defaults (font face, acrylic, opacity)

## Claude Code

`statusline-command.sh` / `statusline-command.ps1`은 `claude/` 디렉토리에 위치합니다.
`claude/setup.sh`가 `claude/` → `~/.claude/` 심볼릭 링크를 생성하므로 별도 복사 없이 바로 동작합니다.
