# Neovim DAP (Debug Adapter Protocol) 사용법

## 기본 명령어

| 명령 | 설명 |
|------|------|
| `:lua require("dap").continue()` | 디버깅 시작 / 재개 |
| `:lua require("dap").toggle_breakpoint()` | breakpoint 토글 |
| `:lua require("dap").step_over()` | step over |
| `:lua require("dap").step_into()` | step into |
| `:lua require("dap").step_out()` | step out |
| `:lua require("dap").terminate()` | 디버깅 종료 |
| `:lua require("dapui").toggle()` | DAP UI 열기/닫기 |

> DAP은 lazy-load 되어 있어 Java/Kotlin 파일을 연 상태에서만 `:Dap*` 명령이 활성화됨.
> 안 보이면 `:lua require("dap").continue()` 로 직접 호출.

## LazyVim 기본 키맵

LazyVim extras (`lang.java`, `dap.core`) 활성화 시:

| 키 | 설명 |
|----|------|
| `<leader>db` | breakpoint 토글 |
| `<leader>dB` | 조건부 breakpoint |
| `<leader>dc` | continue |
| `<leader>dC` | run to cursor |
| `<leader>di` | step into |
| `<leader>do` | step over |
| `<leader>dO` | step out |
| `<leader>dt` | terminate |
| `<leader>du` | DAP UI 토글 |

## Java 디버깅 (jdtls launch 방식)

### 설정

LazyVim `lang.java` extra가 DAP을 자동 활성화함 (별도 설정 불필요).

### 사용법

1. Java 파일 열기
2. breakpoint 설정 (`<leader>db`)
3. `:lua require("dap").continue()` 또는 `<leader>dc`
4. 설정 목록에서 launch 선택

jdtls가 직접 JVM을 debug 모드로 실행해줌. 별도 Gradle 실행 불필요.

## Java/Kotlin 디버깅 (Gradle attach 방식)

수동으로 JVM을 debug 모드로 띄운 뒤 attach 하는 전통적 방식.

### 1단계: Gradle을 debug 모드로 실행

```bash
# 테스트 디버깅
./gradlew test --debug-jvm

# Spring Boot 디버깅
./gradlew bootRun --debug-jvm
```

`Listening for transport dt_socket at address: 5005` 메시지가 나오면 준비 완료.

### 2단계: nvim에서 attach

1. breakpoint 설정 (`<leader>db`)
2. `:lua require("dap").continue()` 또는 `<leader>dc`
3. 설정 목록에서 "Attach to debugging session" 선택

### 3단계: UI 열기

```
:lua require("dapui").toggle()
```

또는 `<leader>du`

### 이미 실행 중인 JVM에 attach

JVM 옵션에 아래를 추가하면 5005 포트로 debug attach 가능:

```
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

`suspend=y`로 바꾸면 debugger 연결까지 JVM이 대기함.

## Kotlin DAP 설정

`kotlin-dap.lua` 참고. kotlin-debug-adapter 사용.

- **launch**: 현재 파일의 `main()` 직접 실행 (단일 파일용)
- **attach**: Gradle `--debug-jvm`으로 띄운 JVM에 연결 (Spring Boot 등)
- **console**: `integratedTerminal` — 프로그램 출력이 nvim 내장 터미널 버퍼에 표시되어 세션 종료 후에도 확인 가능
- **dapui 자동 닫힘 비활성화**: 디버깅 실패/종료 시 dapui가 자동으로 닫히지 않음. 수동으로 닫으려면 `<leader>du` 또는 `:lua require("dapui").toggle()`

## 추천 workflow

| 상황 | 방식 |
|------|------|
| Java 단위 테스트 | jdtls launch (가장 편함) |
| Spring Boot | jdtls launch 또는 Gradle attach |
| Kotlin | Gradle attach (`--debug-jvm`) |
| 원격 JVM | attach (포트 지정) |
