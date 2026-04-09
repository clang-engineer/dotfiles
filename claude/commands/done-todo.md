$BLOG_DIR 환경변수로 지정된 블로그 프로젝트의
_posts/personal/todo/ 디렉토리에 있는 연간 TODO 포스트에서
특정 날짜의 TODO 항목을 모두 완료 처리해줘.

만약 $BLOG_DIR 환경변수가 설정되어 있지 않다면, 처리하지 말고
사용자에게 다음과 같이 안내해줘:
"`BLOG_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export BLOG_DIR=~/your-blog-repo` 를 추가한 뒤 셸을 재시작해주세요."

동작 방식:
1. $BLOG_DIR/_posts/personal/todo/ 에서 올해 연도의 파일을 찾는다 (예: 2026-01-01-todo.md)
2. 대상 날짜 섹션(`## YYYY-MM-DD (요일)`)을 찾는다
3. 해당 섹션의 `- [ ]` 항목을 모두 `- [x]`로 변경한다
4. front matter의 updated 필드를 현재 시각으로 갱신한다
5. 변경 결과를 사용자에게 간단히 보여준다

대상 날짜:
- 인자가 없으면 오늘 날짜
- 인자가 있으면 해당 날짜 (예: 04-07, 2026-04-07 등 유연하게 파싱)

추가 인자: $ARGUMENTS
