현재 대화에서 할 일(TODO)을 추출해서
$BLOG_DIR 환경변수로 지정된 블로그 프로젝트의
_posts/personal/todo/ 디렉토리에 있는 연간 TODO 포스트에 기록해줘.

만약 $BLOG_DIR 환경변수가 설정되어 있지 않다면, 기록하지 말고
사용자에게 다음과 같이 안내해줘:
"`BLOG_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export BLOG_DIR=~/your-blog-repo` 를 추가한 뒤 셸을 재시작해주세요."

## 모드 구분

인자의 첫 단어가 `project`이면 프로젝트 모드, 그 외에는 daily 모드로 동작한다.

### daily 모드 (기본)
1. $BLOG_DIR/_posts/personal/todo/ 에서 올해 연도의 파일을 찾는다 (예: 2026-01-01-todo.md)
2. 파일이 없으면 새로 생성한다:
   - 파일명: YYYY-01-01-todo.md (올해 1월 1일)
   - front matter:
     ```
     ---
     title       : YYYY TODO
     description : >-
         YYYY년 할 일 기록
     date        : YYYY-01-01 00:00:00 +0900
     updated     : (현재 시각)
     categories  : [personal, todo]
     tags        : [todo]
     pin         : false
     hidden      : false
     ---
     ```
3. 오늘 날짜 섹션(`## YYYY-MM-DD (요일)`)이 이미 있으면 그 섹션 끝에 항목을 추가한다
4. 없으면 front matter 바로 아래(기존 내용 위)에 오늘 날짜 섹션을 새로 만들고 항목을 기록한다
   (최신 날짜가 위로 오도록)

### project 모드 (`/todo-add project [프로젝트명]`)
1. $BLOG_DIR/_posts/personal/todo/ 에서 `프로젝트명-todo.md` 파일을 찾는다
2. 파일이 없으면 새로 생성한다:
   - 파일명: 프로젝트명-todo.md (예: es-search-todo.md)
   - front matter:
     ```
     ---
     title       : 프로젝트명
     description : >-
         프로젝트명 할 일 기록
     date        : (현재 시각)
     updated     : (현재 시각)
     categories  : [personal, todo]
     tags        : [todo]
     pin         : false
     hidden      : false
     ---
     ```
3. 대화 맥락에서 카테고리/소주제가 구분되면 `### 소주제` 소섹션으로 나누어 항목을 추가한다
4. 이미 같은 소섹션이 있으면 그 섹션 끝에 항목을 추가한다
5. 프로젝트명은 인자에서 `project` 다음 단어들을 사용한다. 없으면 대화 맥락에서 적절히 추출한다

### 공통
- front matter의 updated 필드를 현재 시각으로 갱신한다

## TODO 항목 형식
- `- [ ] 할 일 내용` (체크박스 형식)
- 대화 맥락에서 구체적이고 실행 가능한 형태로 작성
- 한국어로 작성

추가 인자가 있으면 TODO 내용 힌트로 사용, 없으면 대화에서 추출: $ARGUMENTS
