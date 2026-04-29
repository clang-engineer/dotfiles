현재 대화에서 다룬 기술적 내용을 문서로 정리해서
$TOOLBOX_DIR/docs/{프로젝트명} 디렉토리에 마크다운 파일로 작성해줘.

만약 $TOOLBOX_DIR 환경변수가 설정되어 있지 않다면, 파일을 작성하지 말고
사용자에게 다음과 같이 안내해줘:
"`TOOLBOX_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export TOOLBOX_DIR=~/your-toolbox-repo` 를 추가한 뒤 셸을 재시작해주세요."

작성 전 확인사항:
- 대화 내용 중 문서화할 만한 내용이 없으면 사용자에게 알려줘
- 저장 대상 디렉토리가 없으면 생성

저장 규칙:
- 경로: $TOOLBOX_DIR/docs/{프로젝트명}/{날짜}-{제목}.md
- 프로젝트명: 현재 작업 디렉토리의 basename
- 날짜: YYYY-MM-DD (오늘 날짜)

요구사항:
- Front matter 포함 (layout: doc, title, date, categories, tags)
- TIL보다 상세하게, 아키텍처/설계/동작 원리 등을 체계적으로 정리
- 구조: 개요 → 핵심 구조/흐름 (다이어그램, 표 활용) → 상세 설명 (코드 포함) → (선택) 참고사항
- 코드 블록에 언어 지정
- 한국어로 작성

추가 인자가 있으면 주제/범위 힌트로 사용: $ARGUMENTS
