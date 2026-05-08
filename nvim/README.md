# Neovim 구성 안내

이 디렉터리는 두 가지 구성을 제공합니다.

| 디렉터리 | 설명 | 주요 용도 |
| --- | --- | --- |
| `nvim/lazy/` | LazyVim 기반 Lua 설정. `lua/` 이하에 플러그인과 설정이 모듈화되어 있습니다. | 최신 플러그인 생태계를 빠르게 정리하고 싶을 때.
| `nvim/classic/` | Vimscript 중심의 레거시 구성. 최소 의존성과 단순한 키맵을 유지합니다. | 서버·CI 등 보수적인 환경.

## 설치 / 전환 방법

### macOS / Linux

- 전체 부트스트랩 시: `./bootstrap.sh` (기본 LazyVim).
- 특정 구성만 교체하려면:

  ```bash
  mkdir -p ~/.config
  ln -snf "$PWD/nvim/lazy" ~/.config/nvim      # LazyVim
  ln -snf "$PWD/nvim/classic" ~/.config/nvim   # Classic
  ```

- 구성 변경 직후 `nvim --headless "+Lazy sync" +qa`를 실행하면 LazyVim 플러그인이 최신 상태인지 확인할 수 있습니다.

### Windows

- PowerShell에서 `./scripts/windows/setup-nvim.ps1`를 실행하면 LazyVim 구성이 `%LOCALAPPDATA%/nvim`에 Junction으로 연결됩니다.
- Classic으로 전환하려면 기존 Junction을 제거하고 다음 명령을 실행합니다.

  ```powershell
  cmd /c rmdir %LOCALAPPDATA%\nvim
  cmd /c mklink /J %LOCALAPPDATA%\nvim %USERPROFILE%\dotfiles\nvim\classic
  ```

## 추천 흐름

- LazyVim: `nvim/lazy/init.lua` 에서 필요한 플러그인을 선언하고 `nvim/lazy/lua/plugins/`에 세부 구성을 분리합니다. 개별 기능 문서는 각 모듈 폴더의 README에 추가합니다.
- Classic: `nvim/classic/init.vim`(또는 동일 루트의 Vimscript)을 수정하면 되며, Vimscript 스타일은 `snake_case` 오토커맨드/함수 규칙을 따릅니다.

## 전환 체크리스트

1. 기존 `~/.config/nvim` 또는 `%LOCALAPPDATA%/nvim` 링크를 제거합니다.
2. 새 구성을 링크합니다.
3. LazyVim 사용 시 `nvim --headless "+Lazy! sync" +qa`로 플러그인 메타데이터를 갱신합니다.
4. tmux/IDE에서 `nvim`을 다시 열고 `:checkhealth`로 상태를 확인합니다.
5. Java나 언어별 설정이 필요한 프로젝트라면 `.nvim.lua`를 생성하고 아래 Java Environment Setup 섹션을 참고합니다.

## 문제 해결

- `:checkhealth` 출력에서 LuaRocks, node, python3 등 의존성이 없으면 Brew/Scoop로 설치한 뒤 다시 실행합니다.
- LazyVim 플러그인 설치 중 오류가 발생하면 `rm -rf ~/.local/share/nvim`(또는 Windows `%LOCALAPPDATA%\nvim-data`) 후 `nvim --headless "+Lazy sync" +qa`를 재실행합니다.
- Classic 구성은 `:PlugStatus`(vim-plug)와 같은 플러그인 매니저 출력을 확인하세요.

---

# Java Environment Setup

## 구조

```
dotfiles/
├── nvim/lazy/
│   ├── init.lua                      # 시작 시 java-env.setup() 호출
│   └── lua/config/java-env.lua       # Java 환경 설정 모듈
├── nvim-lua/
│   ├── unix.lua                      # macOS/Linux용 .nvim.lua 템플릿
│   ├── windows.lua                   # Windows용 .nvim.lua 템플릿
│   ├── nvim-lua.sh                   # 현재 디렉터리에 템플릿 링크 생성
│   └── nvim-lua.ps1                  # PowerShell 버전
├── nvim/exrc/
│   ├── exrc-unix.lua                 # (레거시) macOS/Linux Java 경로 하드코딩 템플릿
│   └── exrc-windows.lua              # (레거시) Windows Java 경로 하드코딩 템플릿
├── nvim/opt/generate-nvim-java.sh              # config.java-env를 호출하는 .nvim.lua 생성
└── nvim/opt/generate-nvim-java.ps1 # PowerShell 버전
```

- `nvim/lazy/lua/config/java-env.lua`: OS별 Java 경로를 탐색해 `vim.env.JDTLS_JAVA_HOME`과 `vim.env.GRADLE_JAVA_HOME`을 채웁니다.
- `nvim-lua/*.lua`: 프로젝트별 `.nvim.lua`를 심볼릭 링크로 공유할 수 있는 단순 템플릿입니다. macOS/Linux는 `java_home` 결과를, Windows는 사전 지정한 환경 변수를 사용합니다.
- `scripts/*/generate-nvim-java.*`: 현재 디렉터리에 `require("config.java-env").setup()` 호출을 포함한 `.nvim.lua`를 생성합니다.

## 작동 방식

1. nvim 시작 시 `init.lua`에서 `require("config.java-env").setup()` 호출
2. OS 자동 감지 (Windows/macOS/Linux)
3. Java 경로 자동 탐색 후 환경변수 설정:
   - `JDTLS_JAVA_HOME` - jdtls 실행용 (기본: Java 21)
   - `GRADLE_JAVA_HOME` - Gradle 빌드용 (기본: Java 11)

## 사용법

### 기본 (대부분의 프로젝트)

프로젝트별 설정 필요 없음. nvim 시작 시 자동 설정됨.

### 프로젝트별 커스텀 버전

`.nvim.lua` 파일 생성:

```lua
-- jdtls=21, gradle=17 사용
require("config.java-env").setup({ jdtls = "21", gradle = "17" })
```

동일한 내용을 자동으로 작성하고 싶다면 프로젝트 루트에서 다음 스크립트를 실행하세요.

```bash
~/dotfiles/nvim/opt/generate-nvim-java.sh 21 17
```

```powershell
~/dotfiles/nvim/opt/generate-nvim-java.ps1 -Jdtls 21 -Gradle 17
```

## .nvim.lua 템플릿 & 스크립트

| 목적 | macOS/Linux | Windows | 결과 |
| --- | --- | --- | --- |
| `config.java-env` 기반 `.nvim.lua` 생성 | `~/dotfiles/nvim/opt/generate-nvim-java.sh [JDTLS] [GRADLE]` | `~/dotfiles/nvim/opt/generate-nvim-java.ps1 [-Jdtls <ver>] [-Gradle <ver>]` | `.nvim.lua`에 `require("config.java-env").setup()` 호출이 작성되고, 전달한 버전 값이 옵션으로 들어갑니다. |
| OS별 템플릿을 링크 | `~/dotfiles/nvim-lua/nvim-lua.sh` | `~/dotfiles/nvim-lua/nvim-lua.ps1` | 현재 디렉터리의 `.nvim.lua`가 `nvim-lua/unix.lua` 또는 `nvim-lua/windows.lua`와 연결되어 `vim.env.*` 값을 직접 설정합니다. |

- 스크립트는 프로젝트 루트에서 실행하세요. 기존 `.nvim.lua`가 있다면 덮어씌워집니다.
- 템플릿 링크 방식은 간단하지만 버전 전환 시 템플릿 파일을 직접 수정해야 합니다. 다양한 프로젝트에서 서로 다른 버전을 쓴다면 `config.java-env` 호출 방식을 권장합니다.
- `nvim-lua/unix.lua`는 `/usr/libexec/java_home -v 21`·`-v 11` 결과를 읽고, `nvim-lua/windows.lua`는 `JAVA21_HOME`·`JAVA11_HOME` 환경 변수를 사용합니다. 시스템 단위 기본값을 관리할 때 유용합니다.

## Java 경로 탐색 순서

### Windows
1. `C:\Program Files\Eclipse Adoptium\jdk-{version}*`
2. `C:\Program Files\Java\jdk-{version}*`
3. `C:\Program Files\Microsoft\jdk-{version}*`
4. `%USERPROFILE%\scoop\apps\openjdk{version}\current`

### macOS
1. `jenv prefix {version}` (jenv 사용 시)
2. `/usr/libexec/java_home -v {version}`

### Linux
1. `/usr/lib/jvm/java-{version}-openjdk`
2. `/usr/lib/jvm/java-{version}-openjdk-amd64`
3. `/usr/lib/jvm/jdk-{version}`
4. `~/.sdkman/candidates/java/{version}*`

## Java 트러블슈팅

### jdtls가 시작되지 않음

1. Java 경로 확인:
```vim
:lua print(vim.env.JDTLS_JAVA_HOME)
:lua print(vim.env.GRADLE_JAVA_HOME)
```

2. jdtls 상태 확인:
```vim
:LspInfo
```

### "psd-RidEx does not exist" 등 프로젝트 인식 에러

**jdtls 캐시 삭제:**

```powershell
# Windows
rm -r -Force "$env:APPDATA\jdtls"
```

```bash
# macOS
rm -rf ~/Library/Caches/jdtls

# Linux
rm -rf ~/.cache/jdtls
```

그 후 nvim 재시작.

### Python 관련 에러

jdtls wrapper가 Python 필요:

```powershell
scoop install python
```

### QueryDSL Q-클래스 인식 안 됨

Q-클래스가 생성되지 않았거나 jdtls가 generated 소스 경로를 못 찾는 경우.

**1. Q-클래스 생성:**

```powershell
# Windows
cd C:\Users\planit\Desktop\workspace\{project}
.\gradlew compileQuerydsl
# 또는
.\gradlew compileJava
```

```bash
# macOS/Linux
./gradlew compileQuerydsl
```

**2. nvim에서 LSP 재시작:**

```vim
:LspRestart
```

**3. 여전히 안 되면:**

```powershell
# 1. build 폴더 삭제 후 재빌드
.\gradlew clean build

# 2. jdtls 캐시 삭제
rm -r -Force "$env:APPDATA\jdtls"

# 3. .classpath, .project 삭제 (jdtls가 새로 생성)
rm .classpath, .project -ErrorAction SilentlyContinue
```

```bash
# macOS/Linux
./gradlew clean build
rm -rf ~/Library/Caches/jdtls  # macOS
rm -rf ~/.cache/jdtls          # Linux
rm -f .classpath .project
```

그 후 nvim 재시작.

**4. generated 소스 경로 확인 (build.gradle):**

```groovy
sourceSets {
    main {
        java {
            srcDirs = ['src/main/java', 'build/generated/querydsl']
        }
    }
}
```

## 레거시: nvim/exrc/

`nvim/exrc/`는 Java 경로를 OS별로 하드코딩하는 고전적 방식. `setup.sh`에서 `exrc-unix.lua`를 `~/.exrc.lua`로 심링크한다.
현재는 `java-env.lua`가 OS/버전매니저(jenv, sdkman 등)를 자동 탐지하며, `init.lua`에서 항상 호출되므로 `~/.exrc.lua`는 중복이다. 정리 대상.

## 관련 파일

- `nvim/lazy/lua/config/java-env.lua` - 메인 모듈
- `nvim/lazy/lua/plugins/java.lua` - nvim-jdtls 플러그인 설정
- `nvim/opt/generate-nvim-java.ps1` - Windows 스크립트
- `nvim/opt/generate-nvim-java.sh` - Unix 스크립트
- `nvim-lua/` - OS별 `.nvim.lua` 템플릿과 링크 스크립트
