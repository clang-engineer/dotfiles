# vim-dadbod / dadbod-ui 사용법

## 개요

LazyVim의 `lang.sql` extra가 활성화되어 있어 다음 세 플러그인이 자동으로 설치된다:

| 플러그인 | 역할 |
|----------|------|
| `tpope/vim-dadbod` | DB 어댑터 (`postgres`, `mysql`, `sqlite`, `mongodb` 등 호출) |
| `kristijanhusak/vim-dadbod-ui` | 사이드바 UI (`:DBUIToggle`) |
| `kristijanhusak/vim-dadbod-completion` | SQL 자동완성 |

연결 정의는 `nvim/lazy/lua/config/options/dbui.lua`의 `vim.g.dbs` 테이블에서 관리한다.

## 어댑터 한계

vim-dadbod 내장 어댑터: `postgres`, `mysql`, `sqlite`, `sqlserver`, `mongodb`, `redis`, `oracle`, `bigquery`, `clickhouse`, `duckdb` 등.

**JDBC URL은 지원하지 않는다.**

| 잘못된 URL | 결과 |
|-----------|------|
| `jdbc:postgresql://...` | `E605: no adapter for jdbc` |
| `jdbc:h2:file:...` | `E605: no adapter for jdbc` |

→ JDBC 접두어를 떼고 dadbod이 인식하는 스킴(`postgres://`, `postgresql://` 등)으로 써야 한다. **H2는 어댑터가 없으므로 dadbod 대신 H2 Web Console 또는 IntelliJ Database 툴 사용**.

## URL 형식

```lua
vim.g.dbs = {
  {
    name = "docker postgres",
    url = "postgres://snuheras@localhost:5432/eras",
  },
  {
    name = "순천향 ridex postgres meta",
    url = "postgresql://172.22.101.134:5432/psd_sch?connect_timeout=5",
  },
}
```

- `name`은 사이드바에 표시되는 라벨 (한국어 OK)
- URL에 **비밀번호를 절대 박지 않는다** — 이 파일은 git에 올라간다
- 원격/VPN 의존 항목엔 `?connect_timeout=5`를 붙여 fail-fast (libpq 기본 timeout이 매우 길어서 nvim이 멈칫함)

## 인증 셋업 (`.pgpass`)

dadbod은 비대화식으로 `psql`을 호출하므로 비밀번호 프롬프트가 동작하지 않는다. 셋업 방법은 두 가지가 있는데:

| 방식 | 다중 DB 지원 | 권장 |
|------|------------|------|
| `$PGUSER` / `$PGPASSWORD` 환경변수 | ❌ 세션 전역이라 DB별로 다른 비번 처리 불가 | 사용 X |
| `~/.pgpass` 파일 | ✅ host:port:db 단위로 분리 | ⭕ |

### 셋업 절차

```sh
./scripts/setup-pgpass.sh
```

처음 실행 시 `~/.pgpass`(Windows: `%APPDATA%\postgresql\pgpass.conf`)가 템플릿으로부터 생성되고 퍼미션 600이 적용된다. 이후 파일을 편집해 placeholder를 실제 값으로 교체:

```
localhost:5432:eras:snuheras:실제비번
172.22.101.134:5432:psd_sch:실제유저:실제비번
```

스크립트는 멱등이라 두 번째 실행부터는 기존 파일을 건드리지 않는다.

## 사용법

| 명령 | 설명 |
|------|------|
| `:DBUIToggle` | 사이드바 토글 |
| `:DBUI` | 사이드바 열기 |
| `:DBUIAddConnection` | 연결 추가 (세션 한정, 영속화하려면 `dbui.lua`에 추가) |
| `:DBUIFindBuffer` | 현재 SQL 버퍼를 사이드바에서 찾기 |

사이드바에서 DB 항목 위에 커서를 두고 `<CR>`로 펼치면 스키마/테이블이 로드된다. 테이블 위 `<CR>`은 미리 정의된 쿼리(예: `SELECT * FROM ... LIMIT 200`).

### 직접 쿼리 작성/실행

펼친 DB 트리에 `New query` 항목이 있다. 그 위에서 `<CR>`을 누르면 해당 DB에 묶인 빈 SQL 스크래치 버퍼가 열린다.

| 동작 | 매핑 |
|------|------|
| 전체 쿼리 실행 | `<leader>S` |
| 선택 영역만 실행 | 비주얼 선택 후 `<leader>S` |
| 쿼리 저장 (Saved queries 트리에 추가) | `<leader>W` |
| 결과창 최대화 / 균등화 | `<C-w>_` / `<C-w>=` |

기존 `.sql` 파일을 실행할 때는 `:DBUIFindBuffer`로 사이드바와 연결하거나, `:%DB <url>` 형태로 직접 명령어 실행.

### 결과창 레이아웃

dadbod이 `:split`로 여는 결과창(`dbout` 파일타입)은 가로 분할을 그대로 사용하되, `dbui.lua`의 autocmd가 두 가지를 자동 처리한다:

- **fold 비활성화** (`setlocal nofoldenable`) — vim-dadbod-ui 메인테이너 공식 권장 (PR #203 머지 거부 시 댓글)
- **화면 절반 높이로 리사이즈** (`resize lines/2`) — 기본 분할이 좁아 결과 행이 잘림

답답하면 `<C-w>_`(높이 max), 균등으로 되돌릴 땐 `<C-w>=`.

## 트러블슈팅

| 증상 | 원인 / 해결 |
|------|-------------|
| `E605: no adapter for jdbc` | URL이 `jdbc:postgresql://`로 시작 → `jdbc:` 접두어 제거 |
| `fe_sendauth: no password supplied` | `.pgpass`에 해당 host:port:db 줄 없음 또는 퍼미션이 600이 아님 |
| 연결 시 nvim이 한참 멈춤 | URL에 `?connect_timeout=5` 추가 |
| 원격 DB 연결 timeout | VPN/방화벽 확인. `psql -h <host> -U <user> -d <db>`로 직접 테스트해 dbui 외부 문제인지 분리 |
| `.pgpass` 안 읽힘 | Unix는 `chmod 600 ~/.pgpass` 필수. Windows는 `%APPDATA%\postgresql\pgpass.conf` 위치 확인 |

## 다른 DB (mysql / oracle / mssql) 추가 시

`.pgpass`는 PostgreSQL 전용이다. 다른 DB는 각자 표준 인증 파일을 사용:

| DB | 표준 인증 파일 / 방법 |
|----|----------------------|
| MySQL | `~/.my.cnf` (`[client]` 섹션) 또는 `~/.mylogin.cnf` (mysql_config_editor) |
| Oracle | Oracle Wallet (`mkstore`) + `tnsnames.ora` |
| SQL Server | 표준 파일 없음 — `SQLCMDPASSWORD` 환경변수 또는 Windows 인증 (`-E`) |

각 DB별 셋업 스크립트는 실제 추가 시점에 `scripts/setup-<db>-auth.sh` 형태로 동일 컨벤션으로 추가한다.

## 참고

- vim-dadbod: <https://github.com/tpope/vim-dadbod>
- vim-dadbod-ui: <https://github.com/kristijanhusak/vim-dadbod-ui>
- libpq pgpass 문서: <https://www.postgresql.org/docs/current/libpq-pgpass.html>
