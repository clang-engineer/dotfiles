$VAULT_DIR/notes 디렉토리에 누적된 Notes 파일들을 분류해서
cheatsheet / doc / blog post 중 적절한 형식·위치로 재배치해줘.
vault/notes는 보관용이 아니므로 처리된 notes 파일은 삭제한다.
단 **참고용으로 남길 노트(NOTE)와 개인·비공개 노트는 vault에 남긴다** (삭제 X).

만약 $VAULT_DIR 환경변수가 설정되어 있지 않다면, 작업하지 말고 사용자에게 안내:
"`VAULT_DIR` 환경변수가 설정되지 않았습니다."
CHEATSHEET/POST(공개 대상)를 다루면 `$DEVKIT_DIR`·`$BLOG_DIR`도 확인.

## 대상 저장소 (공개 여부가 분류의 1차 기준)

| 저장소 | 공개 | 담는 것 |
|---|:-:|---|
| devkit (`$DEVKIT_DIR`) | **공개** | `cheatsheets/` — 범용 명령 레퍼런스 |
| vault (`$VAULT_DIR`) | 비공개 | `notes/`(참고 노트·개인), `analysis/`(설계 문서) |
| blog (`$BLOG_DIR`) | **공개** | `_posts/` — 트러블슈팅 글 |

> **노트 자체는 공개하지 않는다.** 개인 학습 기록은 vault(private)에 남기고, 공개 가치가 있으면 raw 노트가 아니라 **블로그 글(POST)로 큐레이션**해 내보낸다. 공개 채널은 블로그가 담당.

## 🔴 공개 안전 게이트 (devkit·blog 行 전 필수)

공개 repo로 보내는 **모든** 파일(CHEATSHEET, POST)은 반영 전 아래를 스캔해 익명화한다:
- 실 IP → 문서용 대역(`203.0.113.x`, `198.51.100.x`, `192.0.2.x`)
- 내부 도메인/호스트 (`*.ac.kr`, `*.co.kr`, `*.local`, 사내 FQDN) → `example.com` / `myhost`
- 시스템·프로젝트 코드명 (예: proj-a, proj-b, proj-c, proj-d, proj-e) → 일반명
- 고객사·병원·조직명 → 익명화

**파일명·주제가 순수 기술이어도 본문에 내부명이 박혀 있을 수 있다 — 반드시 본문을 스캔한다.** 깔끔히 익명화하면 내용이 무너지는 노트는 공개하지 말고 vault(private)에 남긴다. 확실치 않으면 비공개.

## 분류 카테고리

1. **CHEATSHEET** — 명령어/단축키/옵션/문법 모음
   → `$DEVKIT_DIR/cheatsheets/` (공개 · 게이트 통과). **기존 파일**에 섹션 추가 우선.
   새 파일 생성 시 `cheatsheets/_index.yml`에 항목 추가 + `cheatsheets/README.md`·블로그 `_tabs/cheatsheet.md`에 해당 링크 수동 반영.
2. **DOC** — 프로젝트 아키텍처/설계/원리 설명 (내 환경 특정)
   → `$VAULT_DIR/analysis/{프로젝트명}/` 에 `layout: doc` 형식 (비공개)
3. **NOTE** — cheatsheet/doc/post 아닌 참고 노트 (범용 개념이든 개인이든)
   → `$VAULT_DIR/notes/` 유지 (비공개, **삭제 X**). 공개 가치가 크면 POST 승격 검토.
4. **POST** — 이슈→원인→해결 형식의 트러블슈팅 **이면서 공개 가치를 통과한 것**
   → `$BLOG_DIR/_posts/{카테고리}/` 에 Jekyll 형식 (공개 · 게이트 통과)
   - 형식만으로 POST 확정 X. 아래 **공개 가치 게이트**를 같이 통과해야 한다.
   - **공개 가치 게이트** (아래 중 최소 하나 Yes면 통과):
     · 일반화 가능한가? (남도 만날 문제인가, 내 특수 환경만의 문제 아닌가)
     · 검색해도 답 찾기 어려웠나? (이미 널린 정보면 탈락)
     · 원인이 비자명했나? (삽질/통찰이 있었나)
   - 게이트 **탈락** 시: 참고 값이면 가까운 cheatsheet/doc/note에 흡수, 아니면 DELETE.
5. **DELETE** — 가치가 낮거나 이미 다른 곳에 같은 내용이 있는 것

## 작업 흐름 (이 순서를 반드시 지킨다)

### 1단계: 사전 점검

- notes 디렉토리 ls로 파일 목록 확인
- 기존 `$DEVKIT_DIR/cheatsheets/`, `$VAULT_DIR/analysis/`, `$BLOG_DIR/_posts/` 구조 파악
- 같은 이름/주제의 파일이 이미 다른 곳에 있는지 확인 (중복 변환 방지)
- $DEVKIT_DIR 미설정 시 CHEATSHEET 분류 파일은 notes에 남겨두기
- $BLOG_DIR 미설정 시 POST 분류 파일은 notes에 남겨두기

### 2단계: 분류표 작성

각 파일에 대해 분류 결정. 표 형식으로:

```
| 파일명 | 분류 | 공개대상? | 게이트(공개값/익명화) | 대상 경로/파일 | 한 줄 요약 |
```

판단 기준:
- 명령어/단축키 위주 → CHEATSHEET
- 프로젝트 설계/원리/구조 → DOC
- 참고용 개념/개인 노트 → NOTE (vault 유지)
- "어떤 상황에서 안 됐고 어떻게 해결했다" → POST **후보** (공개 가치 게이트 통과해야 확정)
- 이미 있는 내용 → DELETE

**공개대상? 열이 Yes(devkit·blog)인 행은 공개 안전 게이트를 반드시 표기** — 익명화할 항목 또는 "익명화 불가 → 비공개 유지"를 명시.

중복 그룹도 별도 식별 (병합/하나만 남길 전략 명시).

### 3단계: 사용자 승인 (필수)

분류표를 보여주고 다음을 물어 승인 받는다 — **이 단계 없이 절대 실행 금지**:
- 분류표가 맞는지
- 의심스러운 분류 1~3개 짚어주고 사용자 의견 받기
- **공개 안전 게이트에 걸린 파일**(익명화 필요 / 비공개 유지)을 따로 짚어 확인받기
- 공개 가치 게이트를 턱걸이한 POST 후보를 따로 짚어 최종 확인 (블로그行 여부는 애매하면 사람이 결정)
- 중복 병합 vs 별도 유지 결정
- 진행 방식 (일괄 vs 단계별)

### 4단계: 실행

승인 후 다음을 수행. **공개 대상 파일은 반드시 익명화 게이트를 먼저 적용.**

**CHEATSHEET 통합** (→ devkit, 공개)
- 기존 cheatsheet 파일 Read → notes 정보 중 새로운 것만 정밀하게 Edit으로 섹션 추가
- 이미 있는 키맵/명령은 중복 추가 X, cheatsheet 톤 유지(빠른 키 참조)
- 새 파일이면 `_index.yml` 항목 추가 + `cheatsheets/README.md`·블로그 탭에 링크 수동 반영

**DOC 작성** (→ vault, 비공개)
- `layout: doc` front matter 추가 (categories/tags 유지 또는 보강)
- 본문은 원본 그대로 유지(압축/요약 X), 파일명 `YYYY-MM-DD-{프로젝트}-{주제}.md`

**NOTE 유지** (→ vault)
- vault/notes에 그대로 둔다. 처리 완료로 삭제하지 않는다.

**POST 변환** (→ blog, 공개 · Jekyll Chirpy)
- 익명화 게이트 먼저. Front matter 변환:
  ```yaml
  ---
  title       : "..."
  description : "본문 핵심 한 줄 요약 (50-100자)"
  date        : YYYY-MM-DD HH:MM:SS +0900
  updated     : YYYY-MM-DD HH:MM:SS +0900
  categories  : [{카테고리}]
  tags        : [...]
  pin         : false
  hidden      : false
  ---
  ```
- 같은 날짜 여러 파일이면 시간 분산 (10:00, 11:00...)
- 파일명 한국어는 영문으로 (URL 친화), 본문 `# 제목` 헤딩 제거(front matter title과 중복), 본문 무가공 유지

### 5단계: notes 정리

- CHEATSHEET/POST로 반영 완료된 notes 파일은 삭제 (`rm`, git이 deleted로 인식)
- **NOTE 분류 파일, `notes/README.md`, 분류 후 새로 추가된 최신 notes는 보존**
- notes 디렉토리에 어떤 파일이 남았는지 보고

### 6단계: 마무리

- 관련 repo(`$VAULT_DIR`·`$DEVKIT_DIR`·`$BLOG_DIR`)의 `git status -s` 보여주기
- 사용자가 검토 후 커밋하도록 staged 상태로 두기 (자동 커밋 X)
- 작업 요약 보고: 변환 수, 대상별 분포, 익명화한 항목, 발견한 이슈

## 효율 가이드

- 파일 30개 이상이면 분류표 작성은 Agent에게 위임 (general-purpose) — 컨텍스트 절약
- POST 변환도 분량 많으면 Agent에 위임 (명확한 매핑표/규칙 전달)
- CHEATSHEET 통합·DOC 작성은 직접 처리 (기존 파일 정밀 편집 필요)

## 절대 하지 말 것

- 분류표 승인 없이 파일 이동/삭제
- **익명화 게이트 없이 공개 repo(devkit·blog)에 파일 작성**
- **raw 노트를 공개 repo에 발행** (공개는 블로그 POST로만)
- NOTE 분류 파일 삭제
- notes 본문 내용 임의 축약
- 자동 git commit (사용자 검토 후 진행)
- 매핑되지 않은 위치에 파일 작성

추가 인자가 있으면 작업 범위 힌트로 사용: $ARGUMENTS
(예: "cheatsheet만" "blog 변환 건너뛰기" 등)
