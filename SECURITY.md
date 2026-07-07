# 보안 및 민감 경로 가이드

dotfiles를 배포할 때 실수로 비밀키나 머신별 토큰을 커밋하지 않도록 아래 체크리스트를 참고하세요.

## 범위

- `chezmoi/private_dot_ssh/` → `~/.ssh/`
- `chezmoi/dot_gitconfig` + `~/.gitconfig.local`의 `includeIf` 조각들
- `hammerspoon/`
- 비밀·머신별 경로를 참조하는 스크립트 (`scripts/generate-key.*`, `scripts/add-workspace-user.*`, `scripts/windows/*.ps1` 등)

## 민감 경로 모범 사례

### SSH (`chezmoi/private_dot_ssh/` → `~/.ssh/`)

- **버전 관리에는 공개 config만**: `config` + `config.d/00-global`·`template.example`만 chezmoi가 관리하고, 실사용 키·known_hosts·사설 호스트(`config.d/[1-9]*`)는 커밋되지 않습니다 (루트 `.gitignore` + `secrets` repo 오버레이).
- **권한**: `private_dot_ssh`의 `private_`가 `~/.ssh` 0700을 보장합니다. 키는 chezmoi가 만들지 않으므로 머신-로컬로만 존재합니다. 수동 확인:

  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_* ~/.ssh/known_hosts* 2>/dev/null || true
  chmod 644 ~/.ssh/*.pub 2>/dev/null || true
  ```

- **키 생성 자동화**: `./scripts/generate-key.sh <label> <email>` (또는 PowerShell 버전)로 키 이름 규칙·ssh-agent 등록을 일관되게 처리합니다. Host 별칭은 `~/.ssh/config.d/`에 추가하거나 `secrets` repo가 오버레이합니다.
- **검증**: `ssh -T git@github.com-<profile>`로 연결을 확인합니다.

### Git (`chezmoi/dot_gitconfig` → `~/.gitconfig`)

- 관리되는 `dot_gitconfig`에는 공통 설정만 두고, `[include] path = ~/.gitconfig.local`이 PC별 설정을 끌어당깁니다.
- 본인 identity(`[user] name/email`)는 `~/.gitconfig.local`에 둡니다. 템플릿: `scripts/.gitconfig.local.example`.
- 워크스페이스 단위 분리는 `./scripts/add-workspace-user.sh`가 `~/.gitconfig.local`에 `[includeIf]` 블록을 추가합니다.
- `~/.gitconfig.local`은 home 디렉터리에 위치하므로 repo에 들어가지 않습니다.

### `hammerspoon/`

- 자동화 Lua 스크립트에서 API 토큰을 직접 선언하지 말고 `hs.settings.get("token_name")` 또는 환경 변수(`os.getenv`)를 사용합니다.
- macOS 보안 프롬프트(Accessibility, Automation)를 요구하는 스크립트는 README 상단에 macOS 버전 조건과 필요한 권한을 주석으로 남깁니다.

### `~/.secrets` / `~/.secrets.ps1` (환경 변수 비밀 관리)

- `GITHUB_TOKEN`, `ANTHROPIC_API_KEY` 등 민감한 환경 변수는 **`~/.secrets`**(Bash/Zsh) 또는 **`~/.secrets.ps1`**(PowerShell)에 선언합니다.
- 이 파일들은 `.gitignore`에 등록되어 있으므로 커밋되지 않습니다.
- 템플릿(`scripts/.secrets.example`, `scripts/.secrets.ps1.example`)이 저장소에 포함되어 있으니, 새 환경에서는 복사 후 값만 채우면 됩니다:

  ```bash
  # Bash/Zsh
  cp ~/.secrets.example ~/.secrets
  chmod 600 ~/.secrets

  # PowerShell
  Copy-Item ~/.secrets.ps1.example ~/.secrets.ps1
  ```

- `.bashrc`, `.zshrc`, PowerShell `$PROFILE`에서 자동으로 source하므로 `setx`나 수동 export가 필요 없습니다.
- 환경 변수가 정상 로드되었는지 확인하는 방법:

  ```bash
  # Bash / Zsh
  echo $GITHUB_TOKEN
  env | grep GITHUB
  printenv GITHUB_TOKEN
  ```

  ```powershell
  # PowerShell
  echo $env:GITHUB_TOKEN
  Get-ChildItem Env: | Where-Object Name -like "GITHUB*"
  ```

  ```cmd
  # CMD
  echo %GITHUB_TOKEN%
  set GITHUB
  ```

### 환경 변수를 기대하는 스크립트

- `nvim-lua/windows.lua`처럼 `JAVA21_HOME` 등의 변수를 참조하는 경우, `.zshrc`·PowerShell profile과 같은 로그인 스크립트에서만 값을 내보내고 저장소에 직접 작성하지 않습니다.
- Brew/SDKMAN 경로는 절대 경로 대신 `$(brew --prefix ...)` 또는 `$HOME` 변수로 표현해 다른 머신으로 옮길 때 노출 위험을 줄입니다.

## 배포 전 점검 절차

1. `git status --ignored`로 `.gitignore`에 숨겨진 파일 중 커밋되면 안 되는 항목이 있는지 확인합니다.
2. `ls -l ~/.ssh` 출력에서 권한이 `drwx------` / `-rw-------`인지 확인합니다.
3. 새로 추가한 스크립트가 비밀 데이터를 `echo`하거나 로그로 남기지 않는지 검토합니다.
4. macOS/Windows 자동화가 외부 서비스 토큰을 요구한다면, README에 **사용자가 입력할 값만** 안내하고 기본값이나 실제 토큰은 제공하지 않습니다.

## 참고

- SSH·시크릿 관련 사용법은 `SETUP.md`에 문서화합니다.
- 민감 경로에 새 파일을 추가하면 `.gitignore` 업데이트 여부를 항상 확인하세요.
