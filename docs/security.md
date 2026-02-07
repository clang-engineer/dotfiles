# 보안 및 민감 경로 가이드

dotfiles를 배포할 때 실수로 비밀키나 머신별 토큰을 커밋하지 않도록 아래 체크리스트를 참고하세요.

## 범위

- `home/.ssh/`
- `home/.gitconfig` 및 `includeIf` 조각들
- `home/.hammerspoon/`
- 기타 비밀 또는 머신별 경로를 참조하는 스크립트 (`scripts/unix/opt/*`, `scripts/windows/*.ps1` 등)

## 민감 경로 모범 사례

### `home/.ssh/`

- **버전 관리에는 템플릿만 포함**: 예시 키 이름, `config` 샘플 등만 유지하고 실사용 키·known_hosts는 `.gitignore`에 추가합니다.
- **권한 즉시 재설정**:

  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_* ~/.ssh/config 2>/dev/null || true
  chmod 644 ~/.ssh/*.pub 2>/dev/null || true
  ```

- **스크립트 활용**: 실제 키 생성과 config 추가는 `./scripts/unix/opt/generate-ssh-key.sh`, `./scripts/unix/opt/add-ssh-config.sh`, `./scripts/unix/opt/setup-github-account.sh` 또는 Windows 대응 스크립트를 사용해 수동 실수를 줄입니다.
- **검증**: `ssh -T git@github.com-<profile>`로 프록시 호스트 연결을 확인하고, 실패 시 권한과 config 슬러그(`service-region-role`)를 점검합니다.

### `home/.gitconfig`

- 공통 설정만 커밋하고 사용자·워크스페이스별 정보는 `includeIf` 조각으로 분리합니다.
- `./scripts/unix/opt/setup-git-includeif.sh` 또는 PowerShell 스크립트를 사용하면 디렉터리 단위 Git 사용자 정보가 자동으로 주입됩니다.
- 회사 계정 등 비공개 이메일은 `.gitconfig.local` 같이 `.gitignore`에 포함된 파일에서만 선언하세요.

### `home/.hammerspoon/`

- 자동화 Lua 스크립트에서 API 토큰을 직접 선언하지 말고 `hs.settings.get("token_name")` 또는 환경 변수(`os.getenv`)를 사용합니다.
- macOS 보안 프롬프트(Accessibility, Automation)를 요구하는 스크립트는 README 상단에 macOS 버전 조건과 필요한 권한을 주석으로 남깁니다.

### 환경 변수를 기대하는 스크립트

- `nvim-lua/windows.lua`처럼 `JAVA21_HOME` 등의 변수를 참조하는 경우, `.zshrc`·PowerShell profile과 같은 로그인 스크립트에서만 값을 내보내고 저장소에 직접 작성하지 않습니다.
- Brew/SDKMAN 경로는 절대 경로 대신 `$(brew --prefix ...)` 또는 `$HOME` 변수로 표현해 다른 머신으로 옮길 때 노출 위험을 줄입니다.

## 배포 전 점검 절차

1. `git status --ignored`로 `.gitignore`에 숨겨진 파일 중 커밋되면 안 되는 항목이 있는지 확인합니다.
2. `ls -l home/.ssh` 출력에서 권한이 `drwx------` / `-rw-------`인지 확인합니다.
3. 새로 추가한 스크립트가 비밀 데이터를 `echo`하거나 로그로 남기지 않는지 검토합니다.
4. macOS/Windows 자동화가 외부 서비스 토큰을 요구한다면, README에 **사용자가 입력할 값만** 안내하고 기본값이나 실제 토큰은 제공하지 않습니다.

## 참고

- SSH 관련 템플릿을 추가할 때는 `home/.ssh/README.md`처럼 별도 파일에 사용법을 문서화하면 협업자가 실수 없이 복제할 수 있습니다.
- 민감 경로에 새 파일을 추가하면 `.gitignore` 업데이트 여부를 항상 확인하세요.
