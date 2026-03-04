# Windows Scripts

## 구조

```
scripts/windows/
├── setup.ps1                    # 오케스트레이터
├── lib/
│   ├── context.ps1              # 경로 변수 정의
│   └── common.ps1               # 공용 함수 (New-Junction 등)
├── tasks/
│   ├── 01-ensure-scoop.ps1      # Scoop 설치 + 버킷 추가
│   ├── 02-install-packages.ps1  # 패키지 설치
│   ├── 03-install-font.ps1      # Nerd Font 설치
│   ├── 04-update-terminal.ps1   # Windows Terminal 설정
│   └── 05-link-nvim.ps1         # Neovim Junction 링크
├── opt/
│   ├── nvim-java.ps1            # .nvim.lua 생성
│   ├── export-settings.ps1      # 터미널/PS 프로필 내보내기
│   └── powershell-profile-winps.ps1
├── scoop-packages.txt
├── statusline-command.ps1
├── windows-terminal-settings.json
└── scoop-export.json
```

## 전체 설정

```powershell
.\scripts\windows\setup.ps1
```

Options:

```powershell
.\scripts\windows\setup.ps1 -Force
.\scripts\windows\setup.ps1 -NvimFlavor classic
.\scripts\windows\setup.ps1 -FontName CascadiaCode-NF
```

## 개별 태스크 실행

각 태스크를 독립적으로 실행할 수 있습니다:

```powershell
.\scripts\windows\tasks\01-ensure-scoop.ps1
.\scripts\windows\tasks\05-link-nvim.ps1
```

## Claude Code

```powershell
Copy-Item scripts\windows\statusline-command.ps1 ~\.claude\statusline-command.ps1
```

## Notes

- Assumes dotfiles are at `C:\Users\<you>\dotfiles`
- Installs lazygit and Windows-native CLI tools via Scoop
- Packages are read from `scoop-packages.txt` (one per line)
- Updates Windows Terminal defaults (font face, acrylic, opacity)
