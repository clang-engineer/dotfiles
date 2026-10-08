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
