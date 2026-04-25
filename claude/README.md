# Claude Code 설정 가이드

Claude Code의 주요 설정 파일과 활용법을 정리한다.

---

## 설정 파일 위치 및 우선순위

높은 순서대로 적용된다 (위가 우선):

| 우선순위 | 파일 | 용도 |
|---------|------|------|
| 1 | Managed Policy | 조직 관리자가 설정 (enterprise) |
| 2 | `.claude/settings.local.json` | 프로젝트 로컬 (gitignore 대상) |
| 3 | `.claude/settings.json` | 프로젝트 공유 설정 |
| 4 | `~/.claude/settings.json` | 사용자 전역 설정 |

---

## settings.json 주요 옵션

### hooks

이벤트 발생 시 자동으로 실행되는 명령을 정의한다.

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"작업 완료\" with title \"Claude Code\"'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c '... 민감 파일 차단 스크립트 ...'"
          }
        ]
      }
    ]
  }
}
```

**Hook 이벤트 종류:**

| 이벤트 | 시점 | 용도 |
|--------|------|------|
| `PreToolUse` | 도구 실행 전 | 파일 보호, 명령 차단 |
| `PostToolUse` | 도구 실행 후 | 린트, 포맷팅 자동 실행 |
| `Notification` | 사용자 입력 대기 시 | 알림 전송 |
| `Stop` | 응답 완료 후 | 후처리 작업 |

**종료 코드:**
- `0` — 통과
- `2` — 차단 (stderr 메시지가 Claude에게 전달됨)

### permissions

도구 사용 허용/차단 규칙. `allow`와 `deny` 배열로 구성한다.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git status:*)",
      "WebSearch"
    ],
    "deny": [
      "Bash(rm -rf:*)"
    ]
  }
}
```

패턴 문법: `ToolName(args:*)` 형태로 와일드카드를 쓸 수 있다.

---

## keybindings.json

키보드 단축키를 커스터마이즈한다. 위치: `~/.claude/keybindings.json` 또는 `.claude/keybindings.json`

```json
{
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+enter": "chat:submit",
        "ctrl+e": "chat:externalEditor",
        "ctrl+s": "chat:stash"
      }
    },
    {
      "context": "Global",
      "bindings": {
        "ctrl+t": "app:toggleTodos",
        "ctrl+o": "app:toggleTranscript"
      }
    }
  ]
}
```

### 주요 액션 목록

**Chat 컨텍스트:**
- `chat:submit` — 메시지 전송
- `chat:cancel` — 취소
- `chat:externalEditor` — 외부 에디터에서 편집
- `chat:stash` — 입력 임시 저장
- `chat:cycleMode` — 모드 전환
- `chat:modelPicker` — 모델 선택
- `chat:thinkingToggle` — 사고 모드 토글

**Global 컨텍스트:**
- `app:interrupt` — 중단
- `app:exit` — 종료
- `app:toggleTodos` — 태스크 패널 토글
- `app:toggleTranscript` — 트랜스크립트 토글
- `history:search` — 히스토리 검색

**키 문법:**
- 수식키: `ctrl`, `alt`, `shift`, `meta`/`cmd`
- 특수키: `escape`, `enter`, `tab`, `space`, `up`, `down`
- 코드키: `ctrl+k ctrl+s` (연속 입력)
- `null` 할당 시 기본 바인딩 해제

---

## CLAUDE.md / .claude/rules/

프로젝트별 지시사항을 Claude Code에 전달하는 방법.

### CLAUDE.md (레포 루트)

프로젝트 개요, 빌드 명령, 코딩 컨벤션을 작성한다. 대화 시작 시 자동으로 로드된다.

```markdown
# 프로젝트명

## 빌드 명령
npm run build

## 코딩 컨벤션
- TypeScript strict mode 사용
- 함수명은 camelCase
```

### .claude/rules/

특정 주제별 규칙을 개별 파일로 분리할 수 있다.

```
.claude/rules/
├── testing.md      # 테스트 작성 규칙
├── security.md     # 보안 관련 규칙
└── naming.md       # 네이밍 규칙
```

`CLAUDE.md`와 동일하게 자동 로드된다.

---

## MCP 서버 설정 (mcp.json)

외부 도구 서버를 Claude Code에 연결한다. 위치: `.claude/mcp.json`

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["serena"],
      "env": {
        "SERENA_PROJECT_DIR": "/path/to/project"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-filesystem", "/path/to/dir"]
    }
  }
}
```

**설정 위치별 범위:**
- `~/.claude/mcp.json` — 전역 (모든 프로젝트)
- `.claude/mcp.json` — 프로젝트 전용

---

## 슬래시 커맨드 만들기

`.claude/commands/` 디렉터리에 마크다운 파일을 만들면 `/명령어`로 사용할 수 있다.

```
.claude/commands/
├── review.md       →  /review
├── test.md         →  /test
└── deploy.md       →  /deploy
```

**파일 내용 예시** (`.claude/commands/review.md`):

```markdown
코드를 리뷰해줘. 다음 관점에서 확인:
- 보안 취약점
- 성능 문제
- 코딩 컨벤션 위반

$ARGUMENTS 파일을 중심으로 검토해줘.
```

- `$ARGUMENTS` — 슬래시 커맨드 뒤에 입력한 텍스트로 치환된다
- 전역 커맨드: `~/.claude/commands/`에 배치

---

## 환경변수

Claude Code 동작을 제어하는 주요 환경변수:

| 변수 | 설명 | 예시 |
|------|------|------|
| `ANTHROPIC_MODEL` | 사용할 모델 지정 | `claude-sonnet-4-6` |
| `CLAUDE_CODE_USE_BEDROCK` | AWS Bedrock 사용 | `1` |
| `CLAUDE_CODE_USE_VERTEX` | GCP Vertex 사용 | `1` |
| `ANTHROPIC_API_KEY` | API 키 (직접 지정 시) | `sk-ant-...` |
| `CLAUDE_CODE_MAX_TURNS` | 비대화형 모드 최대 턴 수 | `10` |
| `DISABLE_PROMPT_CACHING` | 프롬프트 캐싱 비활성화 | `1` |

---

## 팁

- **설정 확인**: Claude Code 내에서 `/config` 명령으로 현재 설정을 확인할 수 있다
- **Hook 디버깅**: stderr 출력이 Claude에게 전달되므로 `echo "debug info" >&2`로 디버깅
- **권한 관리**: `settings.local.json`은 git에 포함하지 않으므로 머신별 권한을 분리할 수 있다
- **슬래시 커맨드 공유**: `.claude/commands/`를 레포에 커밋하면 팀 전체가 사용 가능
