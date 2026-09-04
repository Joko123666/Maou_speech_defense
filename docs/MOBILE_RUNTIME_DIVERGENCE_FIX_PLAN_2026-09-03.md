# 모바일 런타임 차이 원인 및 수정 계획

- 작성일: 2026-09-03 (Asia/Seoul)
- 대상: Android 실기기에서 PC 실행과 달라지는 메인 메뉴·업적·출격 설정·전투 진입
- 범위: 원인 규명, 수정 구현, 자동 검증과 Android 실기기 승인 경계
- 구현 상태: P0~P2 완료, P3 실기기 승인 대기

## 구현 결과

- 런타임 자산 검증에서 `ProjectSettings.globalize_path(res://...)`와 물리 디렉터리 존재 검사를 제거하고, 물리 폴더 검사는 명시적 authoring audit로 분리했다.
- 콘셉트 로드 오류를 보존하며 `[CONTENT-PROFILE]`, `[RUN-SELECTION]`, `[RUN-SCENE-*]`, `[RUN-STARTUP]`, `[RUN-CHECKPOINT]` 오류를 화면·로그에서 구분한다. 콘셉트 또는 기본 스테이지가 없으면 출격을 비활성화한다.
- 업적 카드의 비상호작용 Control 트리가 스크롤 컨테이너로 이벤트를 전달하고, 세로 AUTO 및 12px deadzone을 명시했다.
- 메인 메뉴는 터치/마우스 입력 후 포커스를 해제하고 키보드/게임패드 입력 후에만 포커스를 복원한다.
- `run_mobile_release_quality_gate.ps1`가 기존 7단계 헤드리스 게이트, 실제 창의 touch-emulated drag/focus 게이트, 빈 cwd의 Android packed-export 게이트를 묶는다.
- 프로젝트/화면/Android `versionName`을 `0.04`, Android `versionCode`를 `4`로 통일하고 APK 옆 JSON manifest 생성 도구를 추가했다.

## 결론

보고된 네 증상은 세 원인으로 나뉜다.

1. 출격 준비 버튼이 계속 밝은 현상은 페이지 전환 때 버튼에 키보드/게임패드 포커스를 무조건 주는 코드 때문이다.
2. 업적 드래그 스크롤 실패는 각 업적 카드의 `PanelContainer`가 포인터 이벤트를 중단해 상위 `ScrollContainer`가 터치에서 변환된 드래그를 받지 못하기 때문이다.
3. 구형 목록형 출격 설정과 시작 직후 타이틀 복귀는 하나의 export 전용 결함이다. 자산 카탈로그 검증이 `res://` 경로를 OS 절대경로로 변환해 디렉터리 존재를 검사하며, 압축된 export 실행에서는 이 검사가 실패한다. 그 결과 `ConceptService.active`가 `null`이 되고 선거 캠페인 UI가 구형 목록 폴백으로 내려가며, 전투 시작 시 기본 스테이지도 찾지 못해 의도된 오류 복귀 경로가 실행된다.

최신 `TD_survival_0.04.apk` 안에는 선거 캠페인 리소스와 후보/심복 이미지가 실제로 포함되어 있다. 누락 패키징이 아니라 런타임 검증 방식이 문제다.

## 증상별 근거

### 1. 출격 준비 버튼의 상시 밝은 상태

- `scripts/ui/main_menu.gd`의 `show_page()`는 타이틀 허브를 열 때 `GameMenuButton.grab_focus.call_deferred()`를 실행한다.
- 패키지 리소스 기반 런타임 프로브에서도 허브 진입 직후 포커스 소유자가 `.../Navigation/GameMenuButton`으로 확인됐다.
- PC에서는 마우스 hover 이동으로 상태 차이를 알아채기 어렵지만, 커서가 없는 터치 환경에서는 focus 스타일이 계속 남아 선택된 버튼처럼 보인다.

### 2. 업적 드래그 스크롤 실패

- `scripts/ui/achievement_browser.gd`는 세로 `ScrollContainer`를 만들지만 실제 터치 제스처 회귀 테스트가 없다. 현재 계약은 `scroll_vertical` 값을 코드로 넣고 복원하는 기능만 검사한다.
- 런타임에서 업적 목록은 viewport 높이 약 332px, 콘텐츠 높이 1,620px로 실제 스크롤 가능한 상태였다.
- 드래그 시작점의 이벤트 경로에서 업적 카드 `PanelContainer.mouse_filter`가 `MOUSE_FILTER_STOP`이었다.
- Forward Mobile 창에서 touch emulation을 켠 드래그 프로브 결과는 기존 트리에서 `scroll_vertical=0`, 비상호작용 카드 트리를 `MOUSE_FILTER_PASS`로 바꾼 뒤 `scroll_vertical=299`였다.
- 따라서 목록 길이나 스크롤바 계산 문제가 아니라 자식 Control의 이벤트 전파 문제다.

### 3. 출격 설정이 구형 목록으로 표시됨

- 신형 카드/초상 UI는 `ConceptService.get_election_campaign()`이 유효할 때만 표시된다. 캠페인이 없으면 `CoreOption`/`CursorOption` 목록이 보이는 호환 폴백이 작동한다.
- `resources/game_asset_catalog_data.gd`는 `_is_safe_resource_root()`와 필수 카테고리 검사에서 `ProjectSettings.globalize_path(res://...)` 결과를 `DirAccess.dir_exists_absolute()`에 넘긴다.
- Godot 공식 문서상 `globalize_path()`의 `res://` 사용은 export에서 동작하지 않으며, export 후 `DirAccess`의 `res://` 디렉터리 결과도 편집기와 달라질 수 있다.
- Android preset으로 만든 PCK를 빈 작업 디렉터리에서 실행하자 다음이 재현됐다.
  - `Concept profile is not playable: assets: asset catalog graphics root must be an existing res:// directory...`
  - 설정 제목 `방어 프로토콜 설정`
  - 캠페인 섹션 숨김
  - `CoreOption`/`CursorOption` 표시
  - 후보/심복 카드 수 0

### 4. 10분 방어 시작 후 타이틀 복귀

- 같은 압축 export 재현에서 `RunStartupService`가 기본 스테이지를 얻지 못해 `GameController is missing required data or scenes.`를 출력했다.
- `GameController._abort_run_startup()`은 이 실패를 받으면 메인 메뉴로 되돌아가도록 구현돼 있다.
- 따라서 이 증상은 3번의 콘셉트 비활성화가 전투 진입 단계까지 전파된 결과다.

## 수정 계획

### P0 — export에서 콘셉트가 무효화되는 결함 제거

1. `GameAssetCatalogData`의 경로 안전성 검사와 실제 존재 검사를 분리한다.
   - 런타임 공통 경로 안전성은 `res://` 시작, 빈 경로 금지, `..` 금지만 검사한다.
   - import/remap 대상의 존재 여부는 `ResourceLoader.exists()`와 이미 역직렬화된 필수 `Texture2D`/`AudioStream` 필드로 검사한다.
   - 원본 디렉터리 존재/목록 검사는 편집기 또는 빌드 전용 감사로 이동하며 플레이 가능성 판정에 사용하지 않는다.
2. `ConceptService`가 기본 프로필까지 읽지 못했을 때 구형 UI로 조용히 폴백하지 않도록 한다.
   - 최근 검증 오류를 보존하고 메인 메뉴에 명시적인 빌드 오류 상태를 표시한다.
   - 콘셉트·기본 스테이지가 없으면 출격 버튼을 비활성화하고 원인을 로그와 화면에 함께 남긴다.
3. `change_scene_to_file()` 반환 오류와 `GameController` 시작 실패 사유를 build ID와 함께 기록해 다음 실기기 보고에서 원인을 즉시 식별할 수 있게 한다.

완료 조건:

- 빈 작업 디렉터리에서 Android export pack을 실행해 `ConceptService.active.id == demon_election_vertical_slice`가 성립한다.
- 후보/심복 카드가 각각 5개이고 두 구형 OptionButton은 숨겨진다.
- Start 버튼 후 현재 씬이 `Game`이며 초기 친위대 준비 단계가 표시된다.
- `Concept profile is not playable` 및 `missing required data or scenes` 로그가 없다.

### P1 — 터치 입력과 포커스 수정

1. 업적 카드의 비상호작용 Control 트리에 `MOUSE_FILTER_PASS` 정책을 적용한다.
   - 카드 전체를 무차별 `IGNORE`로 바꾸지 않고, 향후 상호작용 컨트롤이 생기면 예외를 명시한다.
   - `ScrollContainer.vertical_scroll_mode=AUTO`, 적절한 `scroll_deadzone`, 스크롤 가능 표시도 명시적으로 고정한다.
2. 포커스 복원을 입력 방식에 따라 분기한다.
   - 키보드/게임패드로 진입하면 현재의 명시적 순환 포커스를 유지한다.
   - 터치/마우스로 진입하면 자동 `grab_focus()`를 하지 않고 잔류 포커스를 해제한다.
   - 입력 방식 추적은 페이지마다 중복 구현하지 않고 공용 정책으로 둔다.
3. 도감·상점·출격 설정의 다른 `ScrollContainer`도 같은 이벤트 전파 위험을 감사한다. 특히 버튼이 든 스크롤은 탭과 드래그를 모두 보존하도록 별도 검증한다.

완료 조건:

- 업적 카드의 상단, 본문, 진행 바에서 시작한 세 드래그가 모두 `scroll_vertical`을 증가시킨다.
- 짧은 탭은 드래그로 오인되지 않고 필터 버튼이 한 번만 동작한다.
- 터치로 허브 진입 시 버튼이 focus 상태로 고정되지 않는다.
- 키보드/게임패드 진입 시 첫 포커스, 순환 이동, 복귀 포커스가 유지된다.

### P2 — 재발 방지용 자동 검증과 배포 식별

1. 현재 품질 게이트에 `packed_export_runtime` 단계를 추가한다.
   - Android preset으로 PCK 또는 APK를 만든다.
   - 저장소와 무관한 빈 작업 디렉터리에서 실행한다.
   - 콘셉트 활성화, 신형 설정 UI, 전투 진입을 블랙박스로 확인한다.
   - 이 단계가 이번 결함을 잡는 핵심이다. 저장소 루트나 압축 해제한 APK 디렉터리에서 실행하면 잘못된 OS 디렉터리가 존재해 결함을 가릴 수 있다.
2. 실제 입력 이벤트 회귀를 추가한다.
   - Forward Mobile 창에서 `emulate_touch_from_mouse`를 켜고 업적 드래그 전후 좌표를 검사한다.
   - 터치와 키보드 입력 각각의 포커스 소유자를 검사한다.
3. export 버전 계약을 정리한다.
   - 현재 파일명은 `0.04`인데 `application/config/version`, Android `version/name`은 `0.03`, `version/code`는 계속 1이다.
   - 파일명·화면 버전·Android versionName을 하나의 원천에서 생성하고 versionCode를 빌드마다 단조 증가시킨다.
   - 빌드 ID와 SHA-256을 배포 산출물 옆 manifest에 기록한다.
4. 실패 메시지 계약을 추가한다.
   - 콘텐츠 오류, 체크포인트 쓰기 오류, 씬 전환 오류를 서로 다른 사용자 메시지와 로그 코드로 구분한다.

### P3 — Android 실기기 승인

최종 승인은 코드/PC 에뮬레이션만으로 대체하지 않는다.

1. 기존 앱 데이터 유지 업그레이드와 앱 데이터 초기화 신규 설치를 각각 검사한다.
2. 타이틀에서 build ID를 촬영하고 배포 manifest와 대조한다.
3. 네 보고 항목을 그대로 재검증한다.
   - 허브 터치 후 상시 focus 없음
   - 업적 카드 여러 위치에서 드래그 가능
   - 후보/심복 5개와 초상 표시, 구형 목록 숨김
   - Start 후 친위대 준비 → 전투 진입
4. `adb logcat`에서 `Concept profile is not playable`, `missing required data or scenes`, script/runtime error가 0건인지 확인한다.
5. 중단/복귀, 화면 회전 잠금, safe area, 10분 런 성능/발열을 기존 모바일 승인 항목과 함께 수집한다.

## 권장 구현 순서

1. P0 리소스 검증 교정과 압축 export 회귀
2. P1 업적 이벤트 전파와 입력 방식별 focus
3. P2 품질 게이트·오류 코드·버전 일원화
4. 새 APK 생성 및 신규 설치/업그레이드 실기기 검증

P0와 packed export 회귀가 통과하기 전에는 새 APK를 정상 빌드로 배포하지 않는다.

## 현재 검증 기록

- 최신 APK: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_0.04.apk`
- 내부 build ID: `20260903.230321`
- APK 크기/SHA-256: 69,096,861 bytes / `1FED1C2692A7AF341DD5A22507F0A166FEA6A5435971494E1BE90D7DA8902156`
- APK 메타데이터: package `com.example.td_survival`, versionName `0.04`, versionCode `4`, minSdk 24, targetSdk 36, arm64, v2/v3 서명 유효
- 통합 모바일 릴리스 게이트: 기존 헤드리스 7/7, 실제 창 touch drag/focus, 빈 cwd Android PCK에서 콘셉트·5후보·5심복·초상·Start→Game 모두 통과
- 품질 게이트 보고서: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260903_230201_951_10900\summary.json`
- 패키지 manifest: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_0.04.apk.manifest.json`
- ADB 연결 기기: 0대. 실제 Android 수정 승인 검증은 수행하지 못했다.
