# Scripts

OS별 부트스트랩과 보조 도구가 `scripts/` 아래에 정리되어 있습니다.

## 구조

```
scripts/
├── README.md
├── setup.sh                    # Unix 오케스트레이터
├── setup.ps1                   # Windows 오케스트레이터
├── link-claude-commands.sh     # Claude Code 커맨드 링크
├── lib/
│   ├── common.sh               # 공용 함수 (link_path, ensure_dir)
│   └── common.ps1              # 공용 함수 (Write-TaskHeader, New-Junction)
├── unix/
│   ├── install-oh-my-zsh.sh    # oh-my-zsh 설치
│   ├── install-zsh-plugins.sh  # zsh 플러그인 설치
│   ├── install-tpm.sh          # TPM 설치
│   └── opt/*.sh                # SSH/Git/Java 보조 스크립트
└── windows/
    └── opt/*.ps1               # 보조 스크립트 (폰트, 터미널 등)
```

## 실행 요약

| 목적 | macOS/Linux | Windows | 비고 |
| --- | --- | --- | --- |
| 전체 환경 부트스트랩 | `./scripts/setup.sh [--force]` | `.\scripts\setup.ps1 [-Force]` | 모듈별 링킹 + 패키지 설치를 한 번에 수행합니다. |
| 개별 모듈 링킹 | `./home/setup.sh`, `./claude/setup.sh` 등 | `.\home\setup.ps1`, `.\nvim\setup.ps1` 등 | 필요한 모듈만 골라 실행하세요. |
| 선택형 도구 | `./scripts/unix/opt/add-ssh-config.sh` 등 | `.\scripts\windows\opt\generate-nvim-java.ps1` 등 | 상황별 헬퍼입니다. |

## Unix (macOS/Linux)

### 개별 모듈 실행

```sh
./home/setup.sh              # 플랫 dotfile 링킹
./claude/setup.sh            # ~/.claude 링킹
./ssh/setup.sh               # ~/.ssh 링킹
./hammerspoon/setup.sh       # ~/.hammerspoon 링킹
./nvim/setup.sh              # ~/.config/nvim + ~/.exrc.lua 링킹
```

### Install scripts

```sh
./scripts/unix/install-oh-my-zsh.sh
./scripts/unix/install-zsh-plugins.sh
./scripts/unix/install-tpm.sh
```

### Optional helpers

```sh
./scripts/unix/opt/add-ssh-config.sh
./scripts/unix/opt/generate-ssh-key.sh
./scripts/unix/opt/setup-git-includeif.sh
./scripts/unix/opt/setup-github-account.sh
./scripts/unix/opt/setup-java-versions.sh
./scripts/unix/opt/generate-nvim-java.sh
```

## Windows

### 구조

```
scripts/windows/
├── opt/
│   ├── install-font.ps1         # Nerd Font 설치
│   ├── update-terminal.ps1      # Windows Terminal 설정
│   ├── generate-nvim-java.ps1   # .nvim.lua 생성
│   ├── export-settings.ps1      # 터미널/PS 프로필 내보내기
│   └── powershell-profile-winps.ps1
└── terminal-settings.json
```

### 개별 모듈 실행

```powershell
.\home\setup.ps1       # PowerShell 프로필 링크
.\nvim\setup.ps1       # Neovim Junction 링크 + exrc
```

### Notes

- Assumes dotfiles are at `C:\Users\<you>\dotfiles`
- Installs lazygit and Windows-native CLI tools via Scoop
- Packages are read from `packages/scoop-packages.txt` (one per line)
- Updates Windows Terminal defaults (font face, acrylic, opacity)

## Claude Code

`statusline-command.sh` / `statusline-command.ps1`은 `claude/` 디렉토리에 위치합니다.
`claude/setup.sh`가 `claude/` → `~/.claude/` 심볼릭 링크를 생성하므로 별도 복사 없이 바로 동작합니다.
