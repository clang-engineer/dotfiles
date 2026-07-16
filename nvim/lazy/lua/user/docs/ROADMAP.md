# docs — 로드맵 / 설계 메모

`user.docs`의 향후 확장 방향과, 지금까지 내린 결정·보류 사유를 적어둔다.
(코드는 현재 동작, 이 문서는 "왜 이렇게 두었나 + 다음에 뭘 할까".)

## 이 모듈의 정체성 — reference lane

note-*taker*가 아니라 **작업 중 내 문서·치트시트를 상시 참조하는 read-only 뷰어**다.
Dash / DevDocs의 "내 디렉토리 버전"에 가깝고, note 관리(obsidian·telekasten·dotmd)와는 lane이 다르다.

- 검색 대상(roots)은 env로 지정: `VAULT_DIR`, `DEVKIT_DIR`, `BLOG_DIR`(grep 전용).
- `:Docs` = 파일 피커 → 열면 md는 float, 나머지는 버퍼. `:DocsGrep` = 전 roots grep.
- float은 read-only 뷰어라 tmux pane 이동 후 돌아오면 refocus(그 lane의 핵심 ergonomic).

## 렌더 확장 — "md를 더 완전하게" (핵심 로드맵)

현재 float은 render-markdown을 **버퍼 스코프로만** 켠다(전역은 off — 편집 중 노이즈라). render-markdown은
진짜 렌더러가 아니라 extmark/conceal "분장"이라 구조적으로 이미지·mermaid·완전한 표·KaTeX를 못 그린다.

"완전함"은 3-layer로 쌓인다 (either/or 아님):

| Layer | 도구 | 상태 |
| --- | --- | --- |
| 1. 버퍼 분장 (텍스트·코드·리스트) | render-markdown *(사용 중)* / markview.nvim(더 많은 블록) | 완료 |
| 2. **진짜 인라인 이미지** | **Snacks.image** *(이미 설치, 미활성)* — Ghostty=Kitty 그래픽 프로토콜 지원 | **후보** |
| 3. 풀 피델리티 (mermaid·KaTeX·GitHub CSS) | markdown-preview.nvim *(보유)* → 브라우저, flow 벗어남 | escape hatch |

### Layer 2 착수 조건 & 리스크

- **트리거**: vault/devkit의 md가 실제로 이미지·mermaid-heavy로 판단되면 착수. 대부분 텍스트·코드(치트시트)면
  render-markdown이 이미 ~90% 커버라 실익 낮음 — 이게 미확인 결정 조건.
- **필요조건**: tmux `set -g allow-passthrough on` (현재 미설정).
- **리스크**: tmux 안 이미지는 pane 전환·스크롤 시 잔상/깨짐 리포트 흔함. 하필 이 모듈이 float+tmux
  pane 이동+refocus 동선이라 janky할 위험이 큼. 안 되면 되돌리기 쉬우니 실험 후 판단.

## 네이밍 결정 (검토 완료)

- **`:Docs` 유지.** "documents"는 렌더 방식에 중립적이라 rich 뷰어로 커져도 안 터진다. 오히려 image/mermaid로
  확장할수록 "문서 뷰어"(Dash/DevDocs 카테고리)라는 정체성이 또렷해져 이름이 더 맞아진다.
  경계선: 확장이 "문서가 아닌 것"(코드 실행·위젯·DB)까지 가면 그때 좁아짐 — 현 로드맵은 그 선 안.
- **명령은 flat 유지 (`:Docs` / `:DocsGrep`).** 2개짜리에 subcommand 디스패처(nargs+완성함수)는 YAGNI.
  충돌 관점에서도 subcommand는 안전한 `:DocsGrep`을 없애고 위험한 generic `:Docs`를 남길 뿐이라 이득 작다.
  → **작업이 3개+로 늘 때** subcommand(`:Docs open/grep …`)로 접는다.

## 스코핑 arg (구현 완료)

`:Docs [name]` / `:DocsGrep [name]` — arg 없으면 지금처럼 전 roots, 이름 주면 그 root **하나로 한정**.
문서가 많을 때 애초에 좁혀서 브라우징/grep하려는 동선. tab 완성으로 root 이름 제공.

- **subcommand 디스패처와 다른 축**이라 "flat 유지" 결정과 안 충돌 — 새 *작업*을 추가한 게 아니라
  기존 작업에 옵셔널 스코프를 얹은 것. 작업이 3개+로 늘 때 subcommand로 접는 결정은 그대로.
- **경로 표기 통일**: root spec은 `dir` 한 필드. `$VAR`·`$VAR/하위`·`~/절대` 모두 `vim.fs.normalize`가
  확장하고, 안 풀리는 root(미설정 env 등)는 조용히 스킵. env/dir/sub 3필드를 이걸로 합침
  (`vim.fn.expand`는 미설정 var를 `/x`로 뭉개서 탈락 — normalize라야 원문 유지 → isdirectory=0 스킵).
- **하위폴더 alias**: `{ name = "analysis", dir = "$VAULT_DIR/analysis", scoped = true }`. `analysis/`처럼
  프로젝트가 계속 늘어 full 리스트를 잡아먹는 폴더를 `:Docs analysis`로 미리 좁혀 본다.
- **함정(처리됨)**: 하위폴더 alias는 부모 root와 겹쳐서, 기본 전체 검색에 포함되면 중복으로 뜬다.
  그래서 `scoped=true`로 표시해 **arg 없는 "전체"에선 빠지고 이름으로 부를 때만** 걸린다.
- **`subdirs=true` (2-단계 브라우징, 구현 완료)**: 하위폴더 alias를 flat 파일 리스트가 아니라
  **폴더 고르기 → 그 폴더 안 브라우징**으로 연다. `analysis/<project>/…`처럼 자식이 각각 별개 주제인
  컨테이너용. **동작이 범용 플래그이고 `name`은 임의 alias** — `analysis`든 `projects`든 폴더 성격에 맞게
  붙이고, 같은 형태를 다른 폴더에 다른 이름으로 얼마든지 등록한다. `:DocsGrep <name>`은 그대로 전 하위
  재귀 grep이라, 루트 직속 loose 파일(`순천향 인수인계.md` 등 subdirs 리스트에 안 뜨는 것)은 grep으로 잡힌다.

## 배포 (보류)

- 별도 repo로 추출·공개는 **보류**, 현재 위치(dotfiles 안)에서만 작업.
- reference lane엔 실제 gap이 있으나(glow.nvim 아카이브됨, devdocs는 남의 문서, cheatsheet.nvim은 자체 포맷),
  핵심이 Snacks `dirs` 조합이라 스타 천장은 낮다. 가치는 플러그인보다 "이 조립법"이라 블로그 글이 더 맞는 채널.
- **배포하게 되면**: generic `:Docs` → 구별되는 고유명으로 rename(관행: `:Telekasten`·`:RenderMarkdown`처럼
  브랜드명을 명령으로). "docs"는 그때 subcommand·설명문으로 내려보낸다.
