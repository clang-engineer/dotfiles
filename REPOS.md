# _zero — 저장소 지도

개인 인프라 저장소들을 한 부모 디렉토리에 모아둔 곳. 이 파일은 **"무엇이 어디로 가는가"**
결정 규칙과 저장소 간 참조 관계를 기록한다. (`_zero/` 자체는 git repo가 아님 — 이 지도는 로컬 인덱스.)

## 인프라 5종 — 두 축으로 나뉜다

`(설정 vs 지식) × (공개 vs 비공개)` + 블로그.

| | 공개 | 비공개 |
|---|---|---|
| **설정** (머신이 어떻게 세팅됐나) | `dotfiles` | `secrets` |
| **지식** (무엇을 배웠나) | `devkit` | `vault` |
| **글** | `clang-engineer.github.io` (블로그) | — |

- **dotfiles** — 셸·에디터·도구 환경설정. 심링크로 배포. Claude 스킬 정의(`claude/`) 포함.
- **secrets** — dotfiles의 비공개 짝. 실제 SSH 호스트·DB 접속 등 공개 불가 config. `setup.sh`가 심링크로 배포.
- **devkit** — 공개 레퍼런스. 치트시트·템플릿·개념노트. 재사용 가능한 generic 조각만.
- **vault** — 비공개 개인 지식베이스. 학습 메모(`note-*`)·작업 흐름(`flow-*`)·분석. Claude 스킬이 자동 적재.
- **clang-engineer.github.io** — 기술 블로그 (Jekyll + Chirpy, GitHub Pages).

## 무엇이 어디로 가는가 (결정 규칙)

| 대상 | 위치 |
|---|---|
| 셸/에디터/도구 설정 (공개 가능) | **dotfiles** |
| 실제 크레덴셜·SSH 호스트·DB 접속 | **secrets** |
| 학습 메모·분석 노트 (개인) | **vault** |
| 재사용 가능한 공개 레퍼런스 (치트시트·템플릿·개념) | **devkit** |
| 글·포스트 | **blog** |
| 머신별 경로 env 포인터 (`~/.secrets` 파일) | dotfiles `scripts/setup-secrets.sh` (repo 아님) |

경계 판단 원칙:
- **공개/비공개가 최우선 축.** repo는 반쪽만 공개할 수 없다 → 크레덴셜은 무조건 secrets/vault.
- **vault엔 크레덴셜 금지.** Claude가 자동으로 쓰는 곳이라 secrets와 분리 (blast radius 격리).
- "이름이 비슷하다"로 옮기지 말 것 — `~/.secrets`(경로 포인터, dotfiles 부트스트랩)와 `secrets` repo(실제 민감 데이터)는 **다른 레이어**다.

## 저장소 간 참조 (이동 시 안 깨지게)

- **secrets → 시스템**: `secrets/setup.sh`가 self-locating(`$0` 기준). ssh config·nvim db-connections를 심링크. **repo를 옮기면 `setup.sh` 재실행**하면 전부 새 경로로 재연결.
- **vault**: `$VAULT_DIR` 환경변수로 Claude 스킬이 찾음. 값은 `~/.secrets`에 설정.
- **경로 env 전반**: `~/.secrets` 파일 (`VAULT_DIR`·`DOTFILES_DIR`·`DEVKIT_DIR`·`BLOG_DIR`·`WORKSPACE_DIR`). `dotfiles/scripts/setup-secrets.sh`가 대화형으로 생성.
- **devkit**: vault README에서 공개 레퍼런스로 링크.

## 그 외 (_zero/ 안에 있지만 인프라 아님)

- **clang-engineer/** — GitHub 프로필 README 저장소 (`username/username`).
- **workspace/** — 실제 프로젝트·nvim 플러그인 모음 (repo 아닌 폴더, 하위에 개별 repo들).
- **zmk-config-agar-mini-ble/** — 키보드 펌웨어(ZMK) 설정.
