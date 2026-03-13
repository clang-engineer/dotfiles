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
    ├── install-scoop.ps1       # Scoop 설치
    ├── install-packages.ps1    # 패키지 설치
    ├── install-font.ps1        # Nerd Font 설치
    ├── update-terminal.ps1     # Windows Terminal 설정
    └── opt/*.ps1               # 보조 스크립트
```

## 실행 요약

| 목적 | macOS/Linux | Windows | 비고 |
| --- | --- | --- | --- |
| 전체 환경 부트스트랩 | `./scripts/setup.sh [--force]` | `.\scripts\setup.ps1 [-Force]` | 모듈별 링킹 + 패키지 설치를 한 번에 수행합니다. |
| 개별 모듈 링킹 | `./home/setup.sh`, `./claude/setup.sh` 등 | `.\home\setup.ps1`, `.\nvim\setup.ps1` 등 | 필요한 모듈만 골라 실행하세요. |
| 선택형 도구 | `./scripts/unix/opt/add-ssh-config.sh` 등 | `.\scripts\windows\opt\nvim-java.ps1` 등 | 상황별 헬퍼입니다. |

## Claude Code

| 목적 | macOS/Linux | Windows | 비고 |
| --- | --- | --- | --- |
| 상태 표시줄 설정 | `statusline-command.sh` | `statusline-command.ps1` | `~/.claude/settings.json`에 경로를 등록하면 세션 하단에 cwd, branch, 토큰 사용량이 표시됩니다. |

## 추가 문서

- Unix (macOS/Linux): `scripts/unix/README.md`
- Windows: `scripts/windows/README.md`
