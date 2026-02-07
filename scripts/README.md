# Scripts

OS별 부트스트랩과 보조 도구가 `scripts/` 아래에 정리되어 있습니다.

## 구조

```
scripts/
├── README.md
├── unix/
│   ├── setup.sh                 # 전체 링크 + nvim 설치
│   ├── tasks/01-05-*.sh         # 개별 단계 실행
│   ├── opt/*.sh                 # SSH/Git/Java 보조 스크립트
│   └── lib/*.sh                 # 공용 함수
└── windows/
    ├── setup.ps1               # 전체 설정
    ├── setup-nvim.ps1          # Neovim만 설치
    └── *.ps1 / *.json          # PowerShell 프로필, 터미널 설정 등
```

## 실행 요약

| 목적 | macOS/Linux | Windows | 비고 |
| --- | --- | --- | --- |
| 전체 환경 부트스트랩 | `./scripts/unix/setup.sh [--force] [--vim classic]` | `./scripts/windows/setup.ps1` | `home/` 링크, Neovim 구성, tmux 재적용 등을 한 번에 수행합니다. |
| 필요 단계를 개별 실행 | `./scripts/unix/tasks/01-link-dotfiles.sh` 등 | 각 PowerShell 스크립트 (예: `./scripts/windows/setup-nvim.ps1`) | README에서 순서를 확인하고 필요한 단계만 골라 실행하세요. |
| 선택형 도구 | `./scripts/unix/opt/add-ssh-config.sh` 등 | `./scripts/windows/nvim-java.ps1` 등 | SSH 키, Git includeIf, `.nvim.lua` 생성, Java 버전 고정과 같은 상황별 헬퍼입니다. |

## 추가 문서

- Unix (macOS/Linux): `scripts/unix/README.md`
- Windows: `scripts/windows/README.md`
