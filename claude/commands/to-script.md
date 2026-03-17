현재 대화에서 다룬 명령어/자동화 작업을 셸 스크립트로 만들어서
$TOOLBOX_DIR/scripts 디렉토리에 저장해줘.

만약 $TOOLBOX_DIR 환경변수가 설정되어 있지 않다면, 스크립트를 작성하지 말고
사용자에게 다음과 같이 안내해줘:
"`TOOLBOX_DIR` 환경변수가 설정되지 않았습니다. `.bashrc` 또는 `.zshrc`에
`export TOOLBOX_DIR=~/your-toolbox-repo` 를 추가한 뒤 셸을 재시작해주세요."

작성 전 확인사항:
- 기존 스크립트 목록을 확인하고, 같은 기능의 스크립트가 이미 있으면 새로 만들지 말고 기존 파일을 업데이트
- 대화 내용 중 스크립트화할 만한 내용이 없으면 사용자에게 알려줘

요구사항:
- 파일명: 기능을 설명하는 이름.sh (소문자, 하이픈 구분. 예: cleanup-branches.sh)
- shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` 포함
- 상단에 주석으로 설명과 Usage 포함
- 인자가 필요하면 기본값 설정 및 usage 함수 포함
- 주요 동작 전에 echo로 상태 출력
- 위험한 동작(삭제, 덮어쓰기 등)은 --dry-run 또는 확인 프롬프트 포함
- 실행 권한 부여 (chmod +x)
- 한국어 주석

추가 인자가 있으면 스크립트 주제/범위 힌트로 사용: $ARGUMENTS
