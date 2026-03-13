# Windows Scripts

## 구조

```
scripts/windows/
├── install-scoop.ps1            # Scoop 설치 + 버킷 추가
├── opt/
│   ├── install-font.ps1         # Nerd Font 설치
│   ├── update-terminal.ps1      # Windows Terminal 설정
│   ├── nvim-java.ps1            # .nvim.lua 생성
│   ├── export-settings.ps1      # 터미널/PS 프로필 내보내기
│   └── powershell-profile-winps.ps1
├── (scoop-packages.txt → packages/)
├── statusline-command.ps1
├── terminal-settings.json
└── scoop-export.json
```

## 전체 설정

```powershell
.\scripts\setup.ps1
```

Options:

```powershell
.\scripts\setup.ps1 -Force
```

## 개별 모듈 실행

```powershell
.\home\setup.ps1       # PowerShell 프로필 링크
.\nvim\setup.ps1       # Neovim Junction 링크 + exrc
```

## Claude Code

```powershell
Copy-Item scripts\windows\statusline-command.ps1 ~\.claude\statusline-command.ps1
```

## Notes

- Assumes dotfiles are at `C:\Users\<you>\dotfiles`
- Installs lazygit and Windows-native CLI tools via Scoop
- Packages are read from `packages/scoop-packages.txt` (one per line)
- Updates Windows Terminal defaults (font face, acrylic, opacity)
