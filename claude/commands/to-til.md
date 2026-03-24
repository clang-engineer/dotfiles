현재 대화에서 새로 알게 된 핵심 내용을 TIL(Today I Learned) 형식으로 정리해서
$BLOG_DIR 환경변수로 지정된 블로그 프로젝트의 _til 디렉토리에
마크다운 파일로 작성해줘.

만약 $BLOG_DIR 환경변수가 설정되어 있지 않다면, 파일을 작성하지 말고
사용자에게 다음과 같이 안내해줘:
"`BLOG_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export BLOG_DIR=~/your-blog-repo` 를 추가한 뒤 셸을 재시작해주세요."

작성 전 확인사항:
- 대화 내용 중 TIL로 정리할 만한 내용이 없으면 사용자에게 알려줘
- _til 디렉토리가 없으면 생성

요구사항:
- 파일명: YYYY-MM-DD-제목.md (오늘 날짜 사용)
- Front matter 포함 (layout: til, title, date, categories, tags)
- TIL 특성에 맞게 짧고 핵심적으로 작성 (블로그 포스트보다 훨씬 간결하게)
- 구조: 한 줄 요약 → 핵심 내용 (코드/명령어 포함) → (선택) 참고 링크
- 코드 블록에 언어 지정
- 한국어로 작성

추가 인자가 있으면 주제/범위 힌트로 사용: $ARGUMENTS
