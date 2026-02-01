# LazyVim Java LSP notes

## 목적
- jdtls는 Java 21 이상으로 실행
- Gradle/빌드는 프로젝트 요구 JDK로 분리

## 설정 요약

### 1) 프로젝트별 .nvim.lua (macOS 자동 탐지)
```lua
-- jdtls runs on Java 21+, Gradle sync stays on Java 17 for Gradle 7.5.
vim.env.JDTLS_JAVA_HOME = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21"))
vim.env.GRADLE_JAVA_HOME = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 17"))
```

### 2) 전역 java.lua (jdtls/Gradle 분리)
`/Users/clang/Desktop/_zero/private/dotfiles/nvim/lazy/lua/plugins/java.lua`
- JDTLS_JAVA_HOME / GRADLE_JAVA_HOME를 읽어 jdtls/Gradle을 분리 실행
- Lombok jar가 있으면 javaagent로 붙음

## env 템플릿
```bash
export JDTLS_JAVA_HOME="/path/to/jdk-21"
export GRADLE_JAVA_HOME="/path/to/jdk-17"
```

## OS별 자동 탐지 스니펫

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
