# Scripts

`chezmoi apply`가 환경을 구성하는 진입점이고, `scripts/`는 그 밖의 **툴링**입니다 —
일부는 chezmoi run-스크립트가 호출하고, 대부분은 필요할 때 수동으로 실행하는 헬퍼입니다.

## 구조

```
scripts/
├── README.md
├── .secrets.example / .secrets.ps1.example   # ~/.secrets 템플릿
├── .gitconfig.local.example                  # git identity 템플릿
├── .pgpass.example                           # ~/.pgpass 템플릿
├── generate-key.sh / .ps1                    # SSH 키 생성 + ssh-agent 등록
├── add-workspace-user.sh / .ps1              # workspace별 git identity (includeIf)
├── setup-secrets.sh                          # ~/.secrets 초기화
├── setup-pgpass.sh                           # ~/.pgpass 설정
├── setup-java-versions.sh                    # jenv 기반 Java 버전 설정
├── tmux-layout.sh                            # tmux 레이아웃 헬퍼
├── lib/                                      # 공용 함수 (common.sh)
└── windows/
    ├── install-windows.ps1                   # 윈도우 설치 오케스트레이터
    ├── install-packages.ps1                  # Scoop 패키지 설치 (packages/scoop-packages.txt)
    └── opt/ (install-font.ps1, update-terminal.ps1)
```

## 실행 요약

| 목적 | macOS/Linux | Windows |
| --- | --- | --- |
| 전체 환경 구성 | `chezmoi apply` | `chezmoi apply` |
| 윈도우 전용 설치 | — | `.\scripts\windows\install-windows.ps1` |
| SSH 키 생성 | `./scripts/generate-key.sh <label> <email>` | `.\scripts\generate-key.ps1` |
| workspace별 git identity | `./scripts/add-workspace-user.sh` | `.\scripts\add-workspace-user.ps1` |
| Java 버전 (jenv) | `./scripts/setup-java-versions.sh` | — |

> chezmoi가 `run_after_30-secrets-overlay.sh`에서 `~/.secrets`의 `SECRETS_DIR`를 읽어
> `secrets` repo의 오버레이(ssh 호스트, nvim DB 접속)를 자동 실행합니다.
>
> Neovim Java LSP의 `.nvim.lua`는 셸 스크립트가 아니라 nvim 명령 `:JvmEnvInit`로
> 생성합니다 (`nvim/docs/java-lsp.md`).
