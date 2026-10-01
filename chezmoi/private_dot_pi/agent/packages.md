# Pi packages

`settings.json` is strict JSON, so package notes live here instead of inline comments.

## Installed

- `npm:pi-jev` — ⭐59 — Jev 판단/분류 보조 도구. `jev_find_tools`, `jev_evaluate` 등.
- `npm:@eko24ive/pi-ask` — ⭐52 — 모델이 TUI에서 single/multi/preview 선택지를 구조화해서 물어볼 수 있게 하는 `ask_user` 도구.
- `npm:@zigai/pi-response-renderer` — ⭐14 — 응답 렌더링/표시 개선.
- `npm:@henryqw/pi-add-dir` — ⭐9 — 작업 디렉토리 밖 폴더를 세션에 추가해 읽기/작업 가능하게 함.
- `npm:pi-spark` — ⭐5 — Pi 사용성/UX 보정용 패키지.

## High-star candidates

- `npm:@plannotator/pi-extension` — ⭐9083 — Plan/code review에 주석을 달고 피드백하는 리뷰 워크플로우. Auto mode 대체는 아님.
- `npm:pi-mcp-adapter` — ⭐1570 — MCP 서버를 Pi에 연결. MCP를 적극적으로 쓸 때만 설치 후보.
- `npm:pi-web-access` — ⭐1565 — 웹 검색, URL fetch, GitHub repo, PDF, YouTube/영상 분석. 외부 문서 확인이 필요하면 가장 체감이 큰 후보.
- `npm:billion-context` — ⭐421 — 컨텍스트 압축/장기 세션 보조. 관심 후보지만 신뢰도 기준상 보류.

## Other candidates found on npm

- `npm:@cortexkit/aft-pi` — ⭐314 — tree-sitter/LSP 기반 코드 분석 도구.
- `npm:pi-memory` — ⭐178 — semantic memory/daily log/long-term memory 검색.
- `npm:pi-claude-cli` — ⭐105 — LLM 호출을 Claude Code CLI로 라우팅.
- `npm:@demigodmode/pi-web-agent` — ⭐91 — 검색/fetch/headless 경계가 명확한 웹 접근 패키지.
- `npm:pi-cmux` — ⭐44 — cmux 기반 터미널 통합.
- `npm:pi-docparser` — ⭐36 — 로컬 문서 parse/search/screenshot 도구.
- `npm:pi-skillful` — ⭐28 — skill 호출/가시성 개선.
- `npm:@gtrabanco/pi-agentic-workflow` — ⭐21 — agentic workflow skills/commands/model routing.
- `npm:pi-claude-auth` — ⭐19 — Claude Code credentials 사용.
- `npm:pi-subagents-j0k3r` — ⭐15 — markdown-defined subagents.
- `npm:@zigai/pi-ui-tweaks` — ⭐14 — UI tweak 모음.
- `npm:@zigai/pi-mention-project` — ⭐14 — 프로젝트 디렉토리 fuzzy mention.
- `npm:@zigai/pi-mention-skill` — ⭐14 — skill discovery를 `$` mention으로 이동.

## Notes

- Star 수는 대략적인 GitHub repository 기준이며 시점에 따라 변할 수 있음.
- Pi 생태계는 아직 작아서, stars가 낮아도 실용적인 단일 기능 패키지가 많음.
- `settings.json`의 `packages`는 npm/git/local package 로드용.
- 로컬 `.ts` extension은 `~/.pi/agent/extensions/` 또는 package 디렉토리로 둘 수 있음.
