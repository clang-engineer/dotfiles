# packages

패키지 목록 관리 및 설치를 위한 디렉터리.

## 구조

| 파일 | 설명 |
|------|------|
| `scoop-packages.txt` | Windows Scoop 패키지 목록 |
| `Brewfile` | macOS Homebrew 패키지 목록 |
| `install-packages.ps1` | Windows용 Scoop 패키지 설치 스크립트 |

## 설치

### Windows (Scoop)

```powershell
.\packages\install-packages.ps1
```

이미 설치된 패키지를 강제 재설치하려면:

```powershell
.\packages\install-packages.ps1 -Force
```

### macOS (Homebrew)

```bash
brew bundle --file=packages/Brewfile
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
