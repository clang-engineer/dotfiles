# LazyVim Java LSP notes

## 목적
- jdtls는 Java 21 이상으로 실행
- Gradle/빌드는 프로젝트 요구 JDK로 분리

## 권장 — jvm-env 사용

### 프로젝트별 `.nvim.lua` (한 줄)
```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

`generate-nvim-java.sh 21 17` 또는 `generate-nvim-java.ps1 21 17` 로 자동 생성 가능.

### 전역 자동 탐지
`nvim/lazy/init.lua` 가 시작 시 `require("jvm-env").setup()` 호출 — 기본값 `jdtls=21`, `gradle=11` 로 `vim.env.JDTLS_JAVA_HOME` / `vim.env.GRADLE_JAVA_HOME` 자동 채움.

### jdtls 연결
`nvim/lazy/lua/plugins/java.lua` 에서 두 환경변수를 읽어 jdtls `cmd` 와 `cmd_env` 에 연결.
- `cmd` 에 `--java-executable $JDTLS_JAVA_HOME/bin/java` 추가
- `cmd_env.JAVA_HOME = $GRADLE_JAVA_HOME` + `GRADLE_OPTS=-Dorg.gradle.java.home=...`
- Lombok jar 있으면 `--jvm-arg=-javaagent:...` 로 자동 추가

## env 템플릿 (셸에서 export)
```bash
export JDTLS_JAVA_HOME="/path/to/jdk-21"
export GRADLE_JAVA_HOME="/path/to/jdk-17"
```
이 경우 `jvm-env.setup` 호출 없이 셸 값이 그대로 사용됨.

## 참고 — jvm-env 없이 수동 작성 시 (OS별 스니펫)

`.nvim.lua` 안에서 직접 환경변수를 채우는 옛 방식. jvm-env 가 이 모든 분기를 흡수.

### macOS
```lua
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21"))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 17"))
```

### Linux (배포판에 따라 경로 다름)
```lua
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system("readlink -f /usr/lib/jvm/java-21-openjdk"))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system("readlink -f /usr/lib/jvm/java-17-openjdk"))
```

### Windows (env에서 읽기)
```lua
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system(
  "powershell -NoProfile -Command \"[Environment]::GetEnvironmentVariable('JDTLS_JAVA_HOME','User')\""
))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system(
  "powershell -NoProfile -Command \"[Environment]::GetEnvironmentVariable('GRADLE_JAVA_HOME','User')\""
))
```
