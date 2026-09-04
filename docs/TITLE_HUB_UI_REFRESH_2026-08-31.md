# 타이틀·유세 본부 UI 갱신 기록

- 기준일: 2026-08-31
- 활성 프로필: `res://data/concepts/demon_election_vertical_slice.tres`
- 기준 화면: 1280×720, Godot 4.7 Forward Mobile

## 변경 결과

- `demon_election_title_citadel_v019.png`: 마계 선거 성채 외부와 중앙 진입 광장을 사용하는 전용 타이틀 배경
- `demon_election_campaign_hq_v019.png`: 작전 지도·봉인 상자가 좌우에 있고 중앙 UI 여백이 열린 유세 본부 배경
- 타이틀 진입 화면과 기존 메뉴 허브를 분리했습니다. 타이틀은 한 개의 명확한 입장 행동을 사용하고, 유세 본부는 현재 후보 초상·수석 심복·지지도·선거 자금과 출격/상점/업적/도감 행동을 표시합니다.
- 하위 메뉴는 유세 본부 배경을 공유하고 자체 `PageShell` 헤더를 사용합니다. 중복 전역 브랜드·푸터는 접어 720p에서 긴 도감·업적·출격 내용을 위한 세로 공간을 확보했습니다.
- `Esc`는 하위 메뉴→유세 본부→타이틀 순서로 이동하며, 허브로 돌아오면 원래 메뉴 버튼에 포커스를 복원합니다.

## 이미지 생성 사양

두 배경은 내장 ImageGen의 `stylized-concept` 모드로 제작했습니다. 기존 v0.19 전장 배경을 스타일 참조로 사용했고, 이미지 안에는 문자·로고·버튼·HUD를 넣지 않았습니다.

- 타이틀 핵심 프롬프트: 16:9 마계 선거 성채 외부, 중앙 58%의 낮은 대비 진입 광장, 가장자리의 금색·마젠타 장식, 플랫 카툰, 환경 전용, 문자·UI·인물 없음
- 유세 본부 핵심 프롬프트: 16:9 마계 선거 캠페인 본부 내부, 좌측 작전 지도와 우측 봉인 상자, 중앙의 넓고 차분한 UI 여백, 플랫 카툰, 환경 전용, 문자·UI·인물 없음
- 생성 원본 1672×941을 고품질 결정론 리샘플로 1280×720에 맞췄습니다.

## 계약·검증

- `GameAssetCatalogData`에 `title_background`, `main_hub_background` 역할을 추가했습니다. 별도 자산이 없는 호환 프로필은 기존 `menu_background`으로 안전하게 폴백합니다.
- `UiUxM5MetaPagesContractTest`가 초기 타이틀 상태, 48px 이상 입장 행동, 타이틀→허브 배경 전환, 기존 5개 `PageShell`, 하위 메뉴 chrome 접기, 포커스 복원과 탐색 중 세이브 불변을 검사합니다.
- Forward Mobile 스냅샷 85개를 종료 코드 0으로 생성했고 `title_screen`, `main_menu`, `game_setup`, `shop`, `achievements`, `codex`를 원본 해상도로 직접 확인했습니다. 잘림·겹침·중복 헤더는 없습니다.
- 7단계 헤드리스 품질 게이트 7/7 통과: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_121048_942_26072\summary.json`
- Android arm64 디버그 APK 빌드·v2/v3 서명 통과: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_title_hub_ui_debug.apk`, 67,200,363 bytes, SHA-256 `181713618DE064888BB3AF714DCABC76424A5A1BD07FEABB5D7B5DBB03A4AC10`. APK에는 두 신규 배경의 import/CTEX가 포함되고 `tests/`, `reference/`, 다른 ABI는 없습니다.
- 연결된 승인 Android 기기가 없어 실제 설치·안전영역·터치·발열 검증은 계속 보류합니다.

## 2026-08-31 후속 저디테일 본부 재생성

- 요청 범위를 `main_hub_background`으로 한정해 타이틀 성채는 보존하고 유세 본부만 다시 생성했습니다.
- 내장 ImageGen `stylized-concept`로 굵은 남색 외곽선, 2단 셀 셰이딩, 짙은 자주·절제된 버건디/금색, 작은 마젠타 불꽃을 사용했습니다. 좌측 작전 탁자와 우측 봉인함 외에는 큰 무광 면으로 정리하고 중앙 65%와 상단 UI 밴드의 대비를 낮췄습니다. 미세 균열·반복 장식·천 주름·문자·인물·UI는 제외했습니다.
- 생성 원본은 결정론적 중앙 cover crop과 고품질 bicubic으로 1280×720 불투명 RGB로 정규화했습니다. 활성본과 `assets/graphics/style_refresh_v019/backgrounds/` 보관본의 SHA-256은 `ACE7252DEEA7E052369A1949EF2990AA035C0D27DBA499AAFDAB84519A8A55EF`로 일치합니다.
- Forward Mobile 85개를 재생성하고 `main_menu`, `game_setup`을 원본 해상도로 확인했습니다. 전체 품질 게이트 7/7 보고서는 `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_224113_129_29272\summary.json`입니다.
- 최신 Android arm64 디버그 APK는 `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_minimal_backgrounds_debug.apk`, 68,462,376 bytes, SHA-256 `40B3160E97674567E39A1292FFF3C8F8B2ECF86196B23C85CD7F644CE3FF2376`입니다. zipalign·v2/v3 서명, 활성 본부 import/CTEX 포함, staging/tests/tools/reference/data-art 제외를 확인했습니다.

## 2026-09-01 후속 허브 레이아웃 통합

- 허브의 전역 브랜드 헤더, 최고 기록 요약, 키 힌트, 프로토타입 버전과 타이틀의 선거관리위원회 보조 문구를 제거했습니다. 최고 기록은 출격 설정, 상세 기능 설명은 각 행동의 툴팁에 유지합니다.
- 본부는 반투명 자주색 후보 카드와 같은 색상 언어의 금색 테두리 행동 버튼을 사용합니다. 전역 배경 오버레이는 허브에서 0.18로 낮추고 하위 메뉴에서는 0.48로 유지해 중앙 문장·좌측 작전 책상·우측 투표함이 UI 무대의 일부로 보이게 했습니다.
- 후보 카드와 행동 영역은 동일한 확장 비율·최소 폭을 사용합니다. 1280×720 기준 양쪽 바깥 여백은 각각 80px, 두 열은 각각 548px, 중앙 간격은 24px이며 네 행동 행을 균등 분배해 마지막 버튼과 후보 카드의 하단선을 맞췄습니다.
- 후보 요약은 후보·심복·지지도·선거 자금만 표시하고, 네 행동은 번호와 두 번째 설명 행 없이 단일 행으로 통일했습니다. `행동 선택` 표제도 제거하고 역할은 형태로 구분합니다. 좌측 정보는 낮은 대비의 연속된 비상호작용 표면, 우측 행동은 굵은 시작선·포인터 커서·상태 변화가 있는 네 독립 표면이며 `출격 준비`만 같은 크기 안에서 채도 높은 기본 행동으로 표시합니다. 잠긴 행동은 색상 외에 `잠김` 문구를 함께 표시합니다.
- 근거: 로컬 `UIUX_002`의 정보 본문/고대비 선택 버튼과 `UIUX_003`의 연속 정보 패널을 따랐습니다. [Material 3 canonical layout](https://m3.material.io/foundations/layout/canonical-examples/overview)의 supporting pane처럼 역할별 영역을 분리하고, [Apple UI Design Tips](https://developer.apple.com/design/tips/)의 정렬·근접성 및 [Apple Buttons HIG](https://developer.apple.com/design/human-interface-guidelines/buttons)의 동일 크기 버튼군 지침에 맞춰 추가 표제 없이도 정적 정보와 상호작용 대상을 구별합니다.
- Godot 4.7 파싱과 일반 스모크가 종료 코드 0, Forward Mobile 85개 생성이 종료 코드 0입니다. `title_screen`, `main_menu`, `game_setup`, `shop`, `achievements`, `codex`를 1280×720 원본으로 확인했고 전체 품질 게이트 7/7 보고서는 `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260901_170647_133_33532\summary.json`입니다. Android APK는 이번 범위에서 재빌드하지 않았습니다.
