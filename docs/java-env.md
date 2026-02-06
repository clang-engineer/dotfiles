# Java Environment Setup for Neovim

## 구조

```
dotfiles/
└── nvim/lazy/
    ├── init.lua                      # 시작 시 java-env.setup() 호출
    └── lua/config/java-env.lua       # Java 환경 설정 모듈
```

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

### 스크립트로 .nvim.lua 생성

```powershell
# Windows
~/dotfiles/scripts/windows/nvim-java.ps1                    # 기본값
~/dotfiles/scripts/windows/nvim-java.ps1 -Jdtls 21 -Gradle 17  # 커스텀
```

```bash
# macOS/Linux
~/dotfiles/scripts/unix/nvim-java.sh           # 기본값
~/dotfiles/scripts/unix/nvim-java.sh 21 17     # 커스텀
```

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

## 트러블슈팅

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

- `dotfiles/nvim/lazy/lua/config/java-env.lua` - 메인 모듈
- `dotfiles/nvim/lazy/lua/plugins/java.lua` - nvim-jdtls 플러그인 설정
- `dotfiles/scripts/windows/nvim-java.ps1` - Windows 스크립트
- `dotfiles/scripts/unix/nvim-java.sh` - Unix 스크립트
