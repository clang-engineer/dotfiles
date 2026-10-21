# Pi packages

`settings.json` is strict JSON, so package notes live here instead of inline comments.

## Installed

- `npm:@plannotator/pi-extension` — ⭐9096 — Plan/code review에 주석을 달고 피드백하는 리뷰 워크플로우. 기존 로컬 `plan-mode`와 `--plan` 플래그가 충돌하므로 둘 중 하나만 사용.
- `npm:pi-web-access` — ⭐1568 — 웹 검색, URL fetch, GitHub repo, PDF, YouTube/영상 분석. 외부 문서 확인용.
- `npm:pi-memory` — ⭐178 — semantic memory/daily log/long-term memory 검색.
- `npm:pi-jev` — ⭐60 — Jev 판단/분류 보조 도구. `jev_find_tools`, `jev_evaluate` 등.
- `npm:@eko24ive/pi-ask` — ⭐52 — 모델이 TUI에서 single/multi/preview 선택지를 구조화해서 물어볼 수 있게 하는 `ask_user` 도구.
- `npm:@henryqw/pi-add-dir` — ⭐10 — 작업 디렉토리 밖 폴더를 세션에 추가해 읽기/작업 가능하게 함.

## Other candidates found on npm

### Popular extensions by npm downloads

- `npm:pi-acp` — 379k/mo — ACP adapter for Pi coding agent.
- `npm:@langfuse/pi-observability-plugin` — 269k/mo — Langfuse observability/tracing.
- `npm:pi-mcp-extension` — 145k/mo — MCP client extension. 현재 Pi 내장 `builtin:mcp`와 역할 중복 가능.
- `npm:pi-powerline-footer` — 87k/mo — Powerline-style TUI footer/status bar.
- `npm:@langchain/langsmith-pi-extension` — 75k/mo — LangSmith tracing/observability.
- `npm:billion-context-pi` — 64k/mo — context management. 저성숙/UX 리스크가 있을 수 있어 기본 장착은 보류.
- `npm:@gotgenes/pi-permission-system` — 53k/mo — permission enforcement.
- `npm:@raindrop-ai/pi-agent` — 41k/mo — Raindrop observability.
- `npm:pi-prompt-template-model` — 24k/mo — prompt template model selector.
- `npm:@agegr/pi-web` — 23k/mo — Web UI for Pi.
- `npm:pi-interview` — 19k/mo — interactive interview form tool.
- `npm:pi-antigravity` — 15k/mo — Antigravity / Cloud Code Assist provider.
- `npm:pi-lmstudio` — 9k/mo — LM Studio model provider.
- `npm:@remnic/plugin-pi` — 6k/mo — Remnic memory extension.

### Weekly download snapshot (2026-10-20 확인)

npm API `last-week` 응답 기준 집계 기간: **2026-10-12 ~ 2026-10-18**.
[Pi 카탈로그](https://pi.dev/packages)의 주요 확장 및 기존 추천 후보 **21개만 비교**한 결과이며, 전체 생태계 전수 순위는 아님.
위 월간 수치와는 집계 시점·기간이 다르므로 직접 비교하지 않음.

| 비교 후보 내 순위 | Package | 주간 다운로드 | 용도 / 현재 환경과의 관계 |
|---:|---|---:|---|
| 1 | `pi-mcp-adapter` | 206,106 | MCP 연결. 내장 `builtin:mcp` 우선, 중복 로드 보류 |
| 2 | `pi-web-access` | 154,978 | 웹 검색·콘텐츠 조회. 설치됨 |
| 3 | `pi-mcp-extension` | 104,764 | MCP 연결. 내장 MCP 및 adapter와 역할 중복 |
| 4 | `pi-subagents` | 70,472 | 하위 에이전트 위임·병렬 작업 |
| 5 | `@juicesharp/rpiv-ask-user-question` | 33,063 | 구조화 질문. 현재 `pi-ask`와 역할 중복 |
| 6 | `@juicesharp/rpiv-todo` | 19,887 | 작업 목록 오버레이 |
| 7 | `@plannotator/pi-extension` | 14,933 | 계획·코드 리뷰. 설치됨 |
| 8 | `pi-claude-bridge` | 11,637 | Claude Code 기반 모델 연결 |
| 9 | `pi-lens` | 11,436 | LSP·린터·포매터·타입 검사 피드백 |
| 10 | `pi-advisor-flow` | 9,922 | 실행자·검토자 워크플로 |
| 11 | `@gotgenes/pi-permission-system` | 9,542 | 권한 제어 |
| 12 | `pi-powerline-footer` | 8,334 | TUI 상태 표시줄 |
| 13 | `pi-cc-extensions` | 7,660 | Claude Code 스타일 TUI·유틸리티 |
| 14 | `pi-btw` | 6,578 | 병렬 보조 대화 |
| 15 | `@narumitw/pi-usage` | 6,501 | 제공자별 사용량·한도 표시 |
| 16 | `pi-simplify` | 6,300 | 변경 코드의 명료성·유지보수성 검토 |
| 17 | `pi-goal-x` | 3,002 | 목표 계획·진행 추적·완료 검토 |
| 18 | `pi-background-tasks` | 2,676 | 백그라운드 셸 작업·위임 실행 |
| 19 | `@langfuse/pi-observability-plugin` | 1,162 | Langfuse 추적 |
| 20 | `pi-interactive-shell` | 748 | 대화형 CLI 실행·관찰·직접 조작 |
| 21 | `pi-safety-git-operations` | 4 | 파괴적 Git 작업 승인 |

추가 검토 우선 후보는 **`pi-subagents` → `pi-lens`**. MCP 확장은 인기도와 별개로
내장 기능으로 부족한 실제 요구가 생길 때만 검토한다. 이 목록은 기록용이며 설치 승인은 아님.
다운로드에는 CI·자동 설치가 포함되므로 사용자 수·품질·호환성을 보장하지 않는다.
설치 전 소스와 현재 Pi 버전 호환성을 별도로 확인한다.

출처: [npm downloads API](https://api.npmjs.org/downloads/point/last-week/pi-subagents)
(다른 패키지도 URL 끝의 패키지명 교체; scoped 이름은 URL 인코딩).
`last-week`는 이동 구간이므로 이후 조회 시 위 스냅샷과 달라진다.

### Star-checked candidates

- `npm:@cortexkit/aft-pi` — ⭐315 — tree-sitter/LSP 기반 코드 분석 도구.
- `npm:pi-claude-cli` — ⭐105 — LLM 호출을 Claude Code CLI로 라우팅.
- `npm:@demigodmode/pi-web-agent` — ⭐92 — 검색/fetch/headless 경계가 명확한 웹 접근 패키지.
- `npm:pi-cmux` — ⭐44 — cmux 기반 터미널 통합.
- `npm:pi-docparser` — ⭐36 — 로컬 문서 parse/search/screenshot 도구.
- `npm:pi-skillful` — ⭐28 — skill 호출/가시성 개선.
- `npm:@gtrabanco/pi-agentic-workflow` — ⭐21 — agentic workflow skills/commands/model routing.
- `npm:pi-claude-auth` — ⭐19 — Claude Code credentials 사용.
- `npm:pi-subagents-j0k3r` — ⭐15 — markdown-defined subagents.
- `npm:@zigai/pi-ui-tweaks` — ⭐14 — UI tweak 모음.
- `npm:@zigai/pi-mention-project` — ⭐14 — 프로젝트 디렉토리 fuzzy mention.
- `npm:@zigai/pi-mention-skill` — ⭐14 — skill discovery를 `$` mention으로 이동.
- `npm:@zigai/pi-response-renderer` — ⭐14 — 응답 렌더링/표시 개선. UI 취향 패키지라 제거함.
- `npm:pi-spark` — ⭐5 — Pi 사용성/UX 보정용 패키지. 낮은 star/체감 불확실로 제거함.

## Notes

- Star 수는 대략적인 GitHub repository 기준이며 시점에 따라 변할 수 있음.
- npm download 수는 `npm downloads last-month` 기준으로 반올림한 대략값이며 시점에 따라 변할 수 있음.
- Pi 생태계는 아직 작아서, stars/downloads가 낮아도 실용적인 단일 기능 패키지가 많지만, K 단위 stars가 아닌 패키지는 기본 장착을 보수적으로 판단함.
- `settings.json`의 `packages`는 npm/git/local package 로드용.
- Pi 1.1.0+에서는 MCP는 기본적으로 내장 `builtin:mcp`를 사용하고, `/mcp` 명령 충돌을 피하려면 `pi-mcp-adapter` 같은 외부 MCP 확장은 같이 로드하지 않음.
- 로컬 `.ts` extension은 `~/.pi/agent/extensions/` 또는 package 디렉토리로 둘 수 있음.
