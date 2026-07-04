현재 대화에서 새로 알게 된 핵심 내용을 짧은 학습 메모(Notes) 형식으로 정리해서
$TOOLBOX_DIR/notes 디렉토리에 마크다운 파일로 작성해줘.

만약 $TOOLBOX_DIR 환경변수가 설정되어 있지 않다면, 파일을 작성하지 말고
사용자에게 다음과 같이 안내해줘:
"`TOOLBOX_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export TOOLBOX_DIR=~/your-toolbox-repo` 를 추가한 뒤 셸을 재시작해주세요."

다른 명령어와 구분:
- 외부 발신용 공개 글 → /blog

명령어 모음(cheatsheet)·프로젝트 분석(analysis)도 일단 notes로 캡처한다.
/notes-cleanup이 나중에 cheatsheet/analysis/blog로 분류·재배치한다. 즉 notes는 개인용 캡처의 단일 정문.

notes 디렉토리는 자동 적재 작업 흐름 파일(`flow-<도구>-<작업>.md`)과 통합 누적된다. 사용자 명시 notes 파일은 `note-` 접두어 필수.

작성 전 확인사항:
- 대화 내용 중 Notes로 정리할 만한 내용이 없으면 사용자에게 알려줘
- 기존 notes 목록 확인. 같은 주제의 파일이 있으면 **새 파일 만들지 말고 기존 파일에 추가**:
  - 본문 끝에 `## YYYY-MM-DD 추가` 섹션으로 신규 내용만 덧붙임 (기존 내용은 건드리지 않음)
  - 같은 내용이면 추가 안 함 (사용자에게 알림)
- notes 디렉토리가 없으면 생성

요구사항:
- 파일명: `note-제목.md` (`note-` 접두어 필수. 발견 일자는 frontmatter `date:`에 기록)
- Front matter 포함 (layout: notes, title, date, categories, tags)
- Notes 특성에 맞게 짧고 핵심적으로 작성 (블로그 포스트보다 훨씬 간결하게)
- 구조: 한 줄 요약 → 핵심 내용 (코드/명령어 포함) → (선택) 참고 링크
- 코드 블록에 언어 지정
- 한국어로 작성

추가 인자가 있으면 주제/범위 힌트로 사용: $ARGUMENTS
