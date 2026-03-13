현재 대화에서 다룬 이슈와 해결 방법을 정리해서
$BLOG_DIR 환경변수로 지정된 블로그 프로젝트의 _posts 디렉토리에
Jekyll 블로그 포스트 형식의 md 파일로 작성해줘.

만약 $BLOG_DIR 환경변수가 설정되어 있지 않다면, 포스트를 작성하지 말고
사용자에게 다음과 같이 안내해줘:
"`BLOG_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export BLOG_DIR=~/your-blog-repo` 를 추가한 뒤 셸을 재시작해주세요."

요구사항:
- 파일명: YYYY-MM-DD-제목.md (오늘 날짜 사용)
- Front matter 포함 (layout, title, date, categories, tags)
- 이슈 상황, 원인 분석, 해결 방법을 구조화해서 정리
- 코드 블록에 언어 지정
- 한국어로 작성

추가 인자가 있으면 제목/카테고리 힌트로 사용: $ARGUMENTS
