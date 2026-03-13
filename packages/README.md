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

## 백업 (내보내기)

### Scoop

`scoop-packages.txt`를 직접 편집한다. 현재 설치된 패키지 확인:

```powershell
scoop list
```

### Homebrew

```bash
brew bundle dump --file=packages/Brewfile --force
```

## 패키지 추가/제거

1. `scoop-packages.txt` 또는 `Brewfile`을 직접 편집
2. 설치 스크립트를 다시 실행
