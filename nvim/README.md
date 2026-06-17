# Neovim 구성 안내

LazyVim 기반 단일 구성. `nvim/lazy/lua/` 이하에 플러그인과 설정이 모듈화되어 있습니다.

> 옛 Vimscript 기반 설정은 최상위 [`vim/`](../vim/README.md)으로 분리되었습니다 (legacy, 수동 링크).

## 설치

### macOS / Linux

- 전체 부트스트랩: `./bootstrap.sh`.
- 수동 링크가 필요하다면:

  ```bash
  mkdir -p ~/.config
  ln -snf "$PWD/nvim/lazy" ~/.config/nvim
  ```

- 변경 직후 `nvim --headless "+Lazy sync" +qa`를 실행하면 플러그인이 최신 상태인지 확인할 수 있습니다.

### Windows

- PowerShell에서 `./scripts/windows/setup-nvim.ps1`를 실행하면 `%LOCALAPPDATA%/nvim`에 Junction으로 연결됩니다.

## 추천 흐름

- `nvim/lazy/init.lua`에서 필요한 플러그인을 선언하고 `nvim/lazy/lua/plugins/`에 세부 구성을 분리합니다. 개별 기능 문서는 각 모듈 폴더의 README에 추가합니다.

## 체크리스트

1. 기존 `~/.config/nvim` 또는 `%LOCALAPPDATA%/nvim` 링크를 제거합니다.
2. 새 링크를 생성합니다.
3. `nvim --headless "+Lazy! sync" +qa`로 플러그인 메타데이터를 갱신합니다.
4. tmux/IDE에서 `nvim`을 다시 열고 `:checkhealth`로 상태를 확인합니다.
5. Java나 언어별 설정이 필요한 프로젝트라면 `.nvim.lua`를 생성하고 아래 Java Environment Setup 섹션을 참고합니다.

## 문제 해결

- `:checkhealth` 출력에서 LuaRocks, node, python3 등 의존성이 없으면 Brew/Scoop로 설치한 뒤 다시 실행합니다.
- 플러그인 설치 중 오류가 발생하면 `rm -rf ~/.local/share/nvim`(또는 Windows `%LOCALAPPDATA%\nvim-data`) 후 `nvim --headless "+Lazy sync" +qa`를 재실행합니다.

---

# Java Environment Setup

JDK 환경변수 주입은 외부 플러그인 [clang-engineer/jvm-env.nvim](https://github.com/clang-engineer/jvm-env.nvim) 이 담당합니다. dotfiles 안에는 lazy spec(`lazy/lua/plugins/jvm-env.lua`)만 두고 GitHub 에서 받아 씁니다.

## 구조

```
dotfiles/nvim/
├── lazy/lua/plugins/
│   ├── jvm-env.lua                   # 외부 플러그인 spec (옵션: jdtls/gradle 메이저 버전)
│   └── java.lua                      # nvim-jdtls 와 jvm-env 환경변수 연결
└── opt/
    ├── generate-nvim-java.sh         # require("jvm-env").setup() 호출하는 .nvim.lua 생성
    └── generate-nvim-java.ps1        # PowerShell 버전
```

## 작동 방식

1. lazy.nvim 이 시작 시점에 `jvm-env.nvim` 의 `setup(opts)` 자동 호출 (`lazy = false, priority = 100`)
2. OS 자동 감지 (Windows/macOS/Linux)
3. JDK 경로 자동 탐색 후 환경변수 설정:
   - `JDTLS_JAVA_HOME` — jdtls 실행용 (기본: Java 21)
   - `GRADLE_JAVA_HOME` — Gradle 빌드용 (기본: Java 11)

## 사용법

### 기본

프로젝트별 설정 필요 없음. nvim 시작 시 자동 설정됨.

### 프로젝트별 커스텀 버전

`.nvim.lua` 파일 생성:

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

자동 생성 스크립트:

```bash
~/dotfiles/nvim/opt/generate-nvim-java.sh 21 17
```

```powershell
~/dotfiles/nvim/opt/generate-nvim-java.ps1 -Jdtls 21 -Gradle 17
```

`.nvim.lua`는 Neovim 0.9+ `exrc` 룰로 디렉토리별 로드됩니다. `vim.o.exrc = true`는 `lazy/lua/config/options/default.lua`에서 이미 켜져 있으므로 해당 디렉토리에서 nvim을 처음 열 때 `:trust`만 해주면 됩니다.

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

## 관련 파일

- [`clang-engineer/jvm-env.nvim`](https://github.com/clang-engineer/jvm-env.nvim) — JDK 탐지/환경변수 주입 외부 플러그인 (소스·README·vimdoc)
- `nvim/lazy/lua/plugins/jvm-env.lua` — 외부 플러그인 lazy spec
- `nvim/lazy/lua/plugins/java.lua` — nvim-jdtls 와 jvm-env 환경변수 연결
- `nvim/opt/generate-nvim-java.sh` — Unix `.nvim.lua` 생성 스크립트
- `nvim/opt/generate-nvim-java.ps1` — Windows `.nvim.lua` 생성 스크립트
