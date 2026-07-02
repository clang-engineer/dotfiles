# 💤 LazyVim

[LazyVim](https://github.com/LazyVim/LazyVim) 기반 Neovim 설정. starter 템플릿은 [공식 문서](https://lazyvim.github.io/installation) 참고.

## 로드 구조 — 무엇이 "자동"으로 로드되나

매번 헷갈리는 지점. **자동 로드 트리거는 3종류뿐이고, 나머지는 전부 직접 `require` 해야 산다.**

| 무엇이 자동 로드되나 | 주체 | 메커니즘 |
| --- | --- | --- |
| `lua/plugins/` **폴더 전체** | lazy.nvim | `lazy.lua`의 `{ import = "plugins" }`가 폴더 스캔 |
| `lua/config/{options,keymaps,autocmds}.lua` **세 파일명** | LazyVim | 라이프사이클이 이 이름들을 콕 집어 require |
| `init.lua` | Neovim | 시작 시 읽는 유일한 진입점 (이 파일명만 강제) |

> **폴더째 스캔되는 건 `lua/plugins/` 하나뿐.** `config/`는 폴더가 아니라 정해진 세 파일명만 자동 require 된다 (`config/foo.lua`를 새로 둬도 안 불린다). `lua/` 아래 나머지는 전부 누군가 `require` 해야 실행된다.

`config/{options,keymaps,autocmds}.lua` 세 파일은 **필수가 아니라 선택적 override 훅**이다. LazyVim 로더가 파일이 존재할 때만 require 하므로(`lazyvim/config/init.lua`의 `_load`), 없으면 에러 없이 LazyVim 기본값만 적용된다. 진짜 강제되는 건 `init.lua`(Neovim) 하나뿐이고, `config/lazy.lua`는 그 `init.lua`가 `require("config.lazy")`로 가리켜서 사실상 필요한 부트스트랩일 뿐 — 이름·위치는 자유다.

### 실제 로드 체인

```
init.lua                              ← [Neovim] 시작점
 ├─ require("config.lazy")            ← 직접 require
 │   └─ lazy.setup():
 │        ├─ { import = "plugins" }   → lua/plugins/* 폴더 자동 스캔   [lazy.nvim]
 │        └─ LazyVim 로드 → 라이프사이클이 자동 require:
 │             ├─ config/options.lua  (즉시, UI 전)
 │             ├─ config/keymaps.lua  (VeryLazy)
 │             └─ config/autocmds.lua (VeryLazy)
 ├─ require("user.toolbox").setup()   ← 직접 require
 └─ require("user.quicklinks").setup()← 직접 require
```

`lua/` 최상위는 셋뿐이다 — `config/`(LazyVim 룰), `plugins/`(lazy.nvim 스펙), `user/`(내가 쓴 코드 전부). 개인 모듈을 `user/`로 묶어 전역 네임스페이스 충돌(특히 `db` 같은 일반명)을 피하고, 프레임워크 것과 내 것을 한눈에 가른다.

LazyVim·lazy.nvim이 전혀 모르는, **순수하게 require 체인으로만 사는** 모듈:

| 모듈 | 누가 로드하나 |
| --- | --- |
| `config/options/*.lua` | `config/options.lua`가 직접 require |
| `config/autocmds/*.lua` | `config/autocmds.lua`가 직접 require |
| `user/db/` (init + connections) | `plugins/dadbod.lua`의 `init`이 `require("user.db")` |
| `user/toolbox/`, `user/quicklinks/` | `init.lua`가 `require(...).setup()` |

`user/db/connections/`에 파일 추가하면 자동 포함되는 건 LazyVim 폴더 스캔이 아니라 **`user/db/init.lua`가 직접 runtime glob을 돌리기 때문**이다.

### 함정

- `config/options/`에 서브파일을 새로 만들면 `options.lua`에 `require` 한 줄을 직접 넣어야 한다. 깜빡하면 에러도 없이 조용히 무시된다.
- `config/`의 같은 이름 폴더(`options/`, `autocmds/`)는 LazyVim 룰이 아니라 개인 분리다. 룰은 `options.lua`·`autocmds.lua` 파일까지.

더 깊은 원리(runtimepath, 강제 vs 관례)는 블로그 [Neovim 플러그인 작성 규칙](https://clang-engineer.github.io/posts/neovim/2026-06-12-neovim-plugin-conventions/) 참고.
