# 개발 도구 패키지 랭킹 계획

## Context

- 개인 블로그에 Pi·Neovim·tmux 등 dotfiles 기반 생태계의 패키지 순위·추세 화면을 제공한다.
- ‘사용 중’ 배지는 제외한다. dotfiles는 카테고리 선정 참고 자료이지 수집 대상 제한이 아니다.
- npm 다운로드와 GitHub stars 등 서로 다른 지표를 합산한 종합 순위는 만들지 않는다.
- 계획만 작성하며 코드·설정·설치·배포는 변경하지 않는다.

## 후속 범위 논의 — 조사 후보, 구현 지원 확정 아님

- Python의 **PyPI**를 조사 대상에 포함한다(사용자 요청).
- 추가 조사 후보: npm(JS/TS), Maven Central(Java/Kotlin), crates.io(Rust), Go Modules/pkg.go.dev(Go), Conan Center/vcpkg(C++), Homebrew Formulae/Casks(macOS 앱·CLI).
- Pi는 npm 안의 플러그인 생태계로 구분하고 Neovim·tmux는 별도 플러그인 카탈로그의 확보 가능성을 조사한다. npm 전체 통계 도구 재사용 가능성과 생태계별 수집 범위를 혼동하지 않는다.
- 위 저장소의 존재만으로 전체 목록·주간/월간/누적 다운로드·API가 제공된다고 가정하지 않는다. Go·C++의 분산/복수 채널도 단일 중앙 저장소로 취급하지 않는다.
- 사용자 제안 표시 항목: 주간 / 월간 / 총 / star. 기간과 지표를 구분해 주간 다운로드·월간 다운로드·누적 다운로드·총 GitHub stars의 제공 가능성을 검토한다. 미지원 지표는 대체값을 같은 이름으로 표시하지 않는다.
- 누적 다운로드의 시작일·포괄 범위가 검증되지 않으면 ‘전체 누적’으로 표시하지 않는다. 생태계 간 서로 다른 지표를 합산하거나 직접 비교하지 않는다.
- 범위 확대는 조사 후보 추가이며, 기존 승인 조사 단계의 완료나 구현 승인을 뜻하지 않는다.

## 방향 합의 (후속 대화)

- 일차 목표는 독립 탐색 사이트가 아니라 블로그에서 랭킹을 표시하는 것이다.
- 사용자 동의: 저장소별 통계 수집 → 정규화 → 순위 계산 → JSON 출력 모듈을 중심으로 구상한다.
- JSON에는 수집 대상 범위·지표·실제 집계 기간·갱신 시각을 포함한다. UI는 JSON 소비자로 분리한다.
- 초기에는 정기 실행으로 정적 JSON을 갱신하는 방식을 우선 검토하며, 실시간 API 서버를 전제하지 않는다.
- 이 합의는 방향에 대한 동의이며, 신규 repo 생성·기술 스택·첫 지원 저장소·구현 착수 승인은 별도다. 기존 조사 단계는 완료 처리하지 않는다.

## 구현 초안으로 범위 변경 (사용자 후속 승인)

- 사용자 선택: 별도 `/Users/clang/Desktop/_zero/private/package-rankings`, TypeScript, 첫 대상 Pi 패키지.
- 첫 초안: npm `pi-package` 키워드 탐색 → 주간/월간 다운로드 → 기간·수집 범위가 명시된 JSON. 이는 Pi 확장만 검증한 목록이 아닌 Pi 패키지 후보 목록이다.
- 검색 페이지 제한과 검색 API의 색인 한계를 표시하고 전체 Pi 생태계 순위라고 주장하지 않는다.
- 주간/월간은 npm 공식 문서의 최근 이용 가능한 7일/30일이며 달력 주·월이 아니다. 동일 기준일의 명시적 날짜 구간을 사용한다.
- 누적 다운로드·GitHub stars·타 저장소·UI·배포·정기 실행·git init/commit/push는 이번 구현 제외.
- 기존 6개 조사 체크리스트는 완료되지 않았다. 아래 별도 초안 체크리스트는 후속 사용자 요청에 따른 작업이며 조사 완료로 표시하지 않는다.

### 초안 체크리스트

- [x] TypeScript 프로젝트·출력 계약·npm 수집기·CLI 구현.
- [x] fixture 기반 테스트·타입 검사·실제 API 소규모 smoke 확인.
- [x] README에 실행법·범위/결측/기간·미지원 지표를 설명하고 결과 보고.

### 초안 결과

- 경로: `/Users/clang/Desktop/_zero/private/package-rankings` (디렉터리만 생성, Git 초기화/원격 생성 없음).
- `src/collector.ts`: 정확한 pi-package 키워드 후보 검색·중복 제거·동일 종료일의 7일/30일 집계·런타임 검증·동률 1/1/3 순위·실패 null.
- `src/http.ts`: 15초 타임아웃·429/5xx 제한 재시도. `src/cli.ts`: 옵션·JSON 원자적 교체·실패 종료 코드.
- `package.json`, `package-lock.json`, `tsconfig.json`, `.gitignore`, `README.md`, fixture/테스트 추가. Node24 네이티브 TS, 런타임 외부 의존성 없음.
- `npm run typecheck` 통과, `npm test` 15개 통과. dev dependency 설치는 `npm install --ignore-scripts` 사용.
- 실제 API smoke는 검색 첫 5개만 실행: 10개 지표 성공, `data/pi-smoke.json` 생성(ignored). 검색 보고 수 12,380, 조회 5, `partial`/`truncated: true`.
- 실제 기간: 주간 2026-10-12~18, 월간 2026-09-19~10-18. npm 검색 키워드 후보이며 전체 Pi 확장 순위가 아님.
- 기존 reference-explorer 변경 없음. UI·누적·stars·타 저장소·배포·스케줄·commit/push 없음.
- 원래 승인된 조사 6단계는 별도 미완료로 유지한다. 후속 구현 초안을 그 조사 완료로 소급 처리하지 않는다.

## Findings

- 대상 후보: `/Users/clang/Desktop/_zero/private/reference-explorer`.
- 기존 패키지는 데이터 소유 없이 호스트가 제공한 catalog/model을 보여주는 Web Component·ES module이다 (`README.md`).
- `package.json`: 외부 런타임 의존성 없는 ES module, Node 내장 test 사용. 공개 export는 mount, element, CSS, devkit adapter.
- `src/core`, `src/ui`, `src/graph`, `src/adapters`로 구분되어 있다.

## Existing solutions 조사 (2026-10-20)

새 UI 구현 결정 전에 기존 서비스/임베드 재사용을 우선 확인한다. 검색 결과만으로 기능·라이선스·호환성을 확정하지 않는다.

| 후보 | 직접 확인한 범위 | 목표와의 차이 |
|---|---|---|
| [npm-Pulse](https://github.com/evoluteur/npm-pulse) | README: 주/월/년 다운로드, sparkline, 다운로드 순위, 정적 무빌드·무라이브러리 대시보드, MIT 표기 | 기본 수집 범위는 특정 npm maintainer. Pi 생태계 목록·Neovim/tmux·독립 Web Component는 별도 확인/작업 필요 |
| [npm-bet](https://github.com/shaneholloman/npm-bet) | README: npm 비교, 주/월 집계, SVG embed, Next.js/React 앱, MIT 표기 | 차트 임베드는 있으나 생태계별 랭킹 통합 위젯은 확인되지 않음. 앱 전체 도입은 기존 경량 ES module과 성격이 다름 |
| [Dotfyle Trending](https://dotfyle.com/neovim/plugins/trending) | 검색/페이지 조회: 추적된 Neovim 설정의 최근 설치 기반 trending | npm 다운로드/주간 stars와 다른 지표. 정확한 기간, 공개 API·재사용 권한·embed는 확인 필요 |
| [Neovimcraft](https://neovimcraft.com/) | 검색에서 카탈로그·stars 정렬 확인 | 주간/월간 순위·임베드는 확인 필요 |
| [tmux-plugins/list](https://github.com/tmux-plugins/list) | 검색에서 플러그인 디렉터리 확인 | 주간 랭킹 위젯은 확인되지 않음 |

현재 조사 범위에서는 Pi·Neovim·tmux를 함께 다루는 완성형 임베드 랭킹 플러그인을 찾지 못했다.
‘없음’으로 단정하지 않고 후보 소스·API·라이선스와 블로그 통합 비용을 비교한 뒤 구현 여부를 결정한다.

## Approach — 조사 단계만 승인 대상

- 사용자는 통합 방식·별도 모듈 여부를 아직 결정하지 않았다. 구현 방향을 확정하지 않는다.
- 이번 계획의 산출물은 기존 솔루션 재사용 가능성과 reference-explorer 통합 비용을 비교한 조사 문서다. 구현·의존성 추가·배포는 제외한다.
- 후보 소스에서 실제 제공 기능·라이선스·공개 API/임베드·수집 범위를 확인하고 동일 기준으로 비교한다.
- reference-explorer의 모델·UI·테스트를 읽어 기존 뷰 확장/별도 export/외부 임베드 각각의 결합도와 기존 API 영향만 기록한다.
- 수집·집계와 렌더링의 책임은 구분해서 평가하고, 기존 explorer의 데이터 비소유 원칙을 유지할 수 있는지 확인한다.
- 조사 완료 후 권고안과 근거를 제시하고 사용자 결정 전에는 구현하지 않는다.

## Files to modify

- `plans/package-rankings.md` (현재 dotfiles 저장소): 조사 결과·비교표·미결정 사항을 갱신하는 유일한 변경 파일.
- `/Users/clang/Desktop/_zero/private/reference-explorer/README.md`, `package.json`, `src/**`, `tests/**`, `examples/**`: 읽기 전용 조사 대상. 구현 파일 변경 목록은 후속 결정 후 작성한다.

## Reuse

- `src/adapters/devkit.js`, `src/core/catalog.js`, `src/ui/*`, `src/styles/explorer.css` 확인 예정.

## Steps

- [ ] npm-Pulse·npm-bet의 README와 구현·LICENSE를 대조하고 재사용 범위·필요한 수정·의존성을 기록한다.
- [ ] Dotfyle/Neovimcraft/tmux 디렉터리의 공개 데이터·embed/API·이용 조건을 확인한다. 비공개 API나 허가되지 않은 스크레이핑을 전제하지 않는다.
- [ ] reference-explorer의 모델·UI·CSS·테스트·예제를 읽고 공유 가능한 처리와 랭킹 고유 처리를 구체적인 파일 경로와 함께 정리한다.
- [ ] Pi·Neovim·tmux별 수집 대상 정의, 지표, 이력 확보 가능성, 갱신 주기, API 제한, 결측·중복 처리 과제를 비교한다.
- [ ] 재사용/기존 view 확장/별도 모듈을 비교하고 최소 구현 후보와 미해결 사항을 문서화한다.
- [ ] 조사 결과를 사용자에게 제시하고 구현 방향은 별도로 승인받는다.

## Verification

- 조사 표의 기능·제약마다 원문 또는 소스 경로와 확인일을 남긴다. 검색 요약만으로 확인한 사항은 미검증 표시한다.
- 주간·월간 다운로드, 누적 stars, 기간별 stars 증가, 추적 설정 설치 수를 명확히 구분한다.
- 공개 API 유무·라이선스·실제 임베드 가능 여부를 확인하지 못한 후보는 즉시 도입 가능으로 분류하지 않는다.
- 기존 패키지 호환성·번들 의존성·블로그 호스트 제약을 비교하되, 미확인 블로그 구조를 추정하지 않는다.
- 코드·설정·의존성·배포 변경 없이 조사 문서만 수정됐는지 diff로 확인한다.

## Open decisions

- 같은 저장소의 별도 랭킹 모듈로 갈지, 기존 explorer 안의 view로 넣을지.
- 첫 지원 범위와 수집 파이프라인의 소유 위치.
