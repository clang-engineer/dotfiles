$TOOLBOX_DIR/til 디렉토리에 누적된 TIL 파일들을 분류해서
cheatsheet/doc/blog post 중 적절한 형식으로 재배치해줘.
toolbox는 보관용이 아니므로 처리된 til은 삭제한다.

만약 $TOOLBOX_DIR 환경변수가 설정되어 있지 않다면, 작업하지 말고 사용자에게 안내:
"`TOOLBOX_DIR` 환경변수가 설정되지 않았습니다."

## 분류 카테고리

1. **CHEATSHEET** — 명령어/단축키/옵션/문법 모음
   → `$TOOLBOX_DIR/cheatsheets/` 의 **기존 파일**에 섹션 추가 (없으면 새 파일 생성 자제, 기존 가장 가까운 파일 우선)
2. **DOC** — 아키텍처/설계/원리/개념 설명
   → `$TOOLBOX_DIR/docs/{프로젝트명}/` 에 layout: doc 형식으로 작성
3. **POST** — 이슈→원인→해결 형식의 트러블슈팅
   → `$BLOG_DIR/_posts/dev/{카테고리}/` 에 Jekyll 형식으로 작성
4. **DELETE** — 가치가 낮거나 이미 다른 곳에 같은 내용이 있는 것

## 작업 흐름 (이 순서를 반드시 지킨다)

### 1단계: 사전 점검

- til 디렉토리 ls로 파일 목록 확인
- 기존 cheatsheets/, docs/, _posts/dev/ 디렉토리 구조 파악
- 같은 이름/주제의 파일이 이미 다른 곳에 있는지 확인 (중복 변환 방지)
- $BLOG_DIR 미설정 시 POST 분류된 파일은 til에 남겨두기

### 2단계: 분류표 작성

각 파일에 대해 분류 결정. 표 형식으로:

```
| 파일명 | 분류 | 대상 경로/파일 | 한 줄 요약 |
```

판단 기준:
- 명령어/단축키 위주 → CHEATSHEET
- 설계/원리/구조 설명 → DOC
- "어떤 상황에서 안 됐고 어떻게 해결했다" → POST
- 이미 cheatsheet/doc/blog에 있는 내용 → DELETE

중복 그룹도 별도 식별 (같은 주제 둘 이상이면 병합/하나만 남길 전략 명시).

### 3단계: 사용자 승인 (필수)

분류표를 보여주고 다음을 물어 승인 받는다 — **이 단계 없이 절대 실행 금지**:
- 분류표가 맞는지
- 의심스러운 분류 1~3개 짚어주고 사용자 의견 받기
- 중복 병합 vs 별도 유지 결정
- 진행 방식 (일괄 vs 단계별)

### 4단계: 실행

승인 후 다음을 수행:

**CHEATSHEET 통합**
- 기존 cheatsheet 파일 Read → til 정보 중 새로운 것만 정밀하게 Edit으로 섹션 추가
- 이미 있는 키맵/명령은 중복 추가 X
- cheatsheet 본연의 톤 유지 (빠른 키 참조, 비교/설명은 최소화)

**DOC 작성**
- `layout: doc` front matter 추가 (categories/tags 유지 또는 보강)
- 본문은 til 그대로 유지 (압축/요약 X)
- 파일명: `YYYY-MM-DD-{프로젝트}-{주제}.md`

**POST 변환 (Jekyll Chirpy 형식)**
- Front matter 변환:
  ```yaml
  ---
  title       : "..."
  description : "본문 핵심 한 줄 요약 (50-100자)"
  date        : YYYY-MM-DD HH:MM:SS +0900
  updated     : YYYY-MM-DD HH:MM:SS +0900
  categories  : [dev, {카테고리}]
  tags        : [...]
  pin         : false
  hidden      : false
  ---
  ```
- 같은 날짜 여러 파일이면 시간 분산 (10:00, 11:00, 12:00... 정렬 안정성)
- 파일명에 한국어가 있으면 영문으로 변환 (URL 친화)
- 본문의 `# 제목` 헤딩은 제거 (front matter title과 중복)
- 본문 내용 무가공 유지

### 5단계: til 정리

- 처리 완료된 til 파일은 모두 삭제 (`rm`, git이 deleted로 인식)
- `til/README.md`와 분류 후 새로 추가된 최신 til은 보존
- til 디렉토리에 어떤 파일이 남았는지 보고

### 6단계: 마무리

- toolbox repo와 blog repo의 `git status -s` 보여주기
- 사용자가 검토 후 커밋할 수 있도록 staged 상태로 두기 (자동 커밋 X)
- 작업 요약 보고: 변환 수, 디렉토리별 분포, 발견한 이슈

## 효율 가이드

- 파일 30개 이상이면 분류표 작성은 Agent에게 위임 (general-purpose) — 컨텍스트 절약
- POST 변환도 분량 많으면 Agent에 위임 (명확한 매핑표/규칙 전달)
- CHEATSHEET 통합과 DOC 작성은 직접 처리 (기존 파일에 정밀 편집 필요)

## 절대 하지 말 것

- 분류표 승인 없이 파일 이동/삭제
- til 본문 내용 임의 축약
- 자동 git commit (사용자 검토 후 진행)
- 매핑되지 않은 위치에 파일 작성

추가 인자가 있으면 작업 범위 힌트로 사용: $ARGUMENTS
(예: "cheatsheet만" "drafts/만 제외" "blog 변환 건너뛰기" 등)
