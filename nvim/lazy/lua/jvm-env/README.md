# jvm-env.nvim

> **Status**: experimental (v0.1.x) — actively used by the author on macOS,
> partially tested on Linux/Windows. Feedback and issues welcome.

**OS별로 설치된 JDK를 자동 탐지해서 Neovim 환경변수에 주입.**
jdtls 실행 JDK와 Gradle 빌드 JDK를 **분리해서** 설정 가능.

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
-- → vim.env.JDTLS_JAVA_HOME  = <JDK 21 경로>
-- → vim.env.GRADLE_JAVA_HOME = <JDK 17 경로>
```

## 무엇을 하는가

- `jenv prefix` / `/usr/libexec/java_home` / `~/.sdkman` / `/usr/lib/jvm/*` / Windows JDK 표준 경로 / scoop을 **OS별로 순서대로 시도**해서 지정한 메이저 버전의 JDK 홈 경로를 찾음
- 찾은 경로를 `vim.env.JDTLS_JAVA_HOME`, `vim.env.GRADLE_JAVA_HOME` 에 주입
- 못 찾으면 `vim.notify` 로 경고만 (실패해도 다른 동작 막지 않음)

## 무엇을 안 하는가

- **LSP·DAP 띄우지 않음.** jdtls 설정·실행은 본인 spec(nvim-jdtls·LazyVim Java extras 등) 그대로.
- **JDK 설치하지 않음.** 이미 설치된 JDK를 찾기만 함. 설치는 jEnv·SDKMAN·brew·apt·scoop 같은 셸 매니저로.
- **JAVA_HOME(표준) 안 건드림.** 셸의 `JAVA_HOME` 은 그대로 두고, 별도 변수 두 개만 추가. 의도적으로 표준 변수를 피해 충돌 차단.

## 왜 만들었나

Java 개발 시 흔한 시나리오:
- jdtls 는 최신 JDK (예: 21)로 실행해야 안정적
- 프로젝트는 LTS JDK (예: 17)로 빌드해야 함 (Spring Boot 3.x, Android 등)

이걸 매번 셸 `JAVA_HOME` 으로 토글하기엔 번거롭고, `nvim-jdtls` README가 권하는 `cmd = { '/usr/lib/jvm/...' }` 같은 hardcoded 경로는 크로스 플랫폼·다버전 환경에 안 맞음. jvm-env 는 **메이저 버전 문자열만 알려주면 OS에 맞춰 알아서 경로를 찾아주는 가벼운 도우미**.

## 인접 도구와의 관계

| 도구 | 영역 |
|---|---|
| **mason.nvim** | jdtls 같은 LSP 서버 install. JDK 자체는 install 안 함. |
| **nvim-jdtls** | jdtls Neovim 통합. JDK 경로는 사용자 책임. |
| **nvim-java** | 풀스택 (LSP+DAP+테스트). mason으로 JDK 직접 install 옵션 있음. |
| **LazyVim java extras** | jdtls spec 자동. `vim.env.JAVA_HOME = ...` hardcoded 권장. |
| **jvm-env (이 플러그인)** | **OS·매니저 통합 + jdtls/gradle 분리 환경변수**. LSP 띄우지 않음. |

다른 도구들과 **상호 보완**. 풀스택 솔루션(`nvim-java`)을 쓸 거라면 굳이 필요 없음. 본인이 `nvim-jdtls` 또는 LazyVim Java extras 위에 가벼운 자동화만 얹고 싶을 때 적합.

## 설치

[lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "clang-engineer/jvm-env.nvim",
  lazy = false,            -- jdtls 시작 전에 vim.env 가 채워져야 함
  priority = 100,          -- LSP·jdtls 관련 plugin 보다 먼저 로드
  opts = {
    jdtls = "21",
    gradle = "11",
  },
}
```

`opts` 비워두면 기본값 (`jdtls = "21"`, `gradle = "11"`) 사용.

## 사용

### 기본
```lua
require("jvm-env").setup()
-- jdtls=21, gradle=11 기본값으로 두 환경변수 채움
```

### 버전 지정
```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

### jdtls 와 연결 (LazyVim · nvim-jdtls 통합 예제)

`lua/plugins/java.lua`:
```lua
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local function present(v) return v ~= nil and v ~= "" end

      -- jvm-env 가 아직 setup 안 됐다면 (.nvim.lua 가 trust 안 받았을 때 등)
      -- 여기서 fallback 으로 호출
      if not present(vim.env.JDTLS_JAVA_HOME) then
        require("jvm-env").setup()
      end

      local jdtls_home = vim.env.JDTLS_JAVA_HOME
      local gradle_home = vim.env.GRADLE_JAVA_HOME
      if not present(jdtls_home) then return opts end

      local cmd = { vim.fn.exepath("jdtls") }
      table.insert(cmd, "--java-executable")
      table.insert(cmd, jdtls_home .. "/bin/java")

      opts.jdtls = vim.tbl_deep_extend("force", opts.jdtls or {}, {
        cmd = cmd,
        cmd_env = present(gradle_home) and {
          JAVA_HOME = gradle_home,
          GRADLE_OPTS = "-Dorg.gradle.java.home=" .. gradle_home,
        } or nil,
      })
    end,
  },
}
```

핵심:
- `cmd` 에 `--java-executable` 로 jdtls 실행 JDK를 명시 → `JDTLS_JAVA_HOME` 활용
- `cmd_env.JAVA_HOME` 으로 jdtls 가 spawn 하는 Gradle 프로세스의 JDK 분리 → `GRADLE_JAVA_HOME` 활용

### 프로젝트별 버전 — `.nvim.lua` 활용

`.nvim.lua` (Neovim 0.9+ 의 `exrc` 룰로 디렉토리별 로드):
```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

`vim.o.exrc = true` 또는 `:trust` 명령으로 활성화 후 해당 디렉토리에서 `nvim` 켜면 프로젝트 전용 버전으로 자동 전환.

## 동작 원리 — OS별 탐지 순서

| OS | 탐지 순서 |
|---|---|
| **macOS** | 1. `jenv prefix <ver>` 메이저 매칭 → 2. `jenv versions --bare \| grep '^<ver>\\.'` exact fallback → 3. `/usr/libexec/java_home -v <ver>` |
| **Linux** | 1. `/usr/lib/jvm/java-<ver>-openjdk` → 2. `/usr/lib/jvm/java-<ver>-openjdk-amd64` → 3. `/usr/lib/jvm/jdk-<ver>` → 4. `~/.sdkman/candidates/java/<ver>*` |
| **Windows** | 1. Eclipse Adoptium `jdk-<ver>*` → 2. Java `jdk-<ver>*` → 3. Microsoft `jdk-<ver>*` → 4. scoop `openjdk<ver>/current` |

순서는 "더 정확한 버전 매칭이 가능한 것 → 일반적인 표준 경로 → 매니저별 fallback".

## 환경변수 이름 정책

`JDTLS_JAVA_HOME`·`GRADLE_JAVA_HOME` 은 jdtls/Gradle 의 표준 환경변수가 **아니다**. 이 플러그인의 컨벤션이고, **본인 `nvim-jdtls` 설정에서 이 변수를 읽어 cmd 와 cmd_env 에 연결**해야 동작이 완성됨 (위 jdtls 연결 예제 참고).

왜 표준 `JAVA_HOME` 안 쓰나:
- `JAVA_HOME` 한 개로는 jdtls·Gradle 분리가 안 됨
- 셸의 `JAVA_HOME` 을 덮어쓰면 외부 도구가 영향받음

향후 옵션:
- 환경변수 이름 override (`setup({ env = { jdtls = "MY_HOME" } })`) — 필요하다는 피드백 오면 추가

## API

### `setup(opts)`

| 키 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `jdtls` | string | `"21"` | jdtls 실행에 사용할 JDK 메이저 버전 |
| `gradle` | string | `"11"` | Gradle 빌드에 사용할 JDK 메이저 버전 |

JDK 버전 문자열은 메이저 버전만 지정 (예: `"21"`). 마이너·패치 버전이 있는 정확한 버전(예: `"21.0.1"`)도 jenv·java_home 이 매칭하면 동작하나, 일반적으로 메이저로 충분.

## 마이그레이션 (기존 `config.java-env` 사용자)

기존 호출:
```lua
require("config.java-env").setup({ jdtls = "21", gradle = "17" })
```

신규:
```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

기존 `.nvim.lua` 들은 위 패턴으로 수동 수정 또는 `generate-nvim-java.sh / .ps1` 재실행.

## 라이선스

MIT
