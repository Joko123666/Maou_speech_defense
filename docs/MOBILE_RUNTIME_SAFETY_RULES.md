# 모바일 런타임 구조 안전 규칙

- 적용 범위: `autoload/`, `resources/`, `scripts/`, `scenes/`, `project.godot`, `export_presets.cfg`, Android 빌드 도구
- 목적: 편집기·PC 소스 실행에서는 정상이나 압축 export·터치 환경에서만 실패하는 구조적 결함 방지
- 규범어: **금지**는 예외 승인 없이 사용하지 않으며, **필수**는 작업 완료 전에 증거를 남긴다.

## 1. 리소스 경계

### 금지

- 런타임 검증에서 `res://`에 `ProjectSettings.globalize_path()`를 적용해 디렉터리나 파일의 물리 존재를 판정하는 행위
- `DirAccess.dir_exists_absolute()` 결과로 콘셉트, 콘텐츠 팩, 스테이지 또는 필수 자산의 플레이 가능성을 판정하는 행위
- export 실패를 일반 기본값이나 레거시 UI로 숨겨 사용자가 정상 상태로 오인하게 하는 행위

### 필수

- export 리소스는 `ResourceLoader.exists(path, type_hint)`, `load(path)`, preload 또는 Resource의 타입 지정 필드로 검증합니다.
- 안전 경로 검사는 `res://` prefix, `..` 금지, 허용 ID/카테고리처럼 어휘적 규칙만 담당합니다.
- 실제 소스 폴더 구조 검사는 `get_authoring_validation_errors()` 같은 명시적 저작 감사로 분리합니다.
- 필수 프로필 로드 실패 시 마지막 검증 오류를 보존하고 진행 버튼을 비활성화합니다.

허용 예외는 `user://` 저장·백업·임시 파일의 원자 교체와 편집기/빌드 전용 감사뿐입니다. 예외 코드는 함수명이나 주석으로 실행 경계를 드러내야 합니다.

## 2. 입력 방식 경계

입력 방식은 다음 상태 전이를 사용합니다.

| 마지막 유효 입력 | 포커스 정책 | 시각 결과 |
|---|---|---|
| 터치 press 또는 마우스 button press | 현재 GUI focus 해제, 페이지 자동 focus 금지 | 특정 버튼이 선택된 것처럼 계속 밝지 않음 |
| 키보드 key press | 페이지의 유효한 첫/기억 focus 복원 | 방향키·Tab·확정 사용 가능 |
| 게임패드 button 또는 임계값 이상의 axis | 키보드와 동일 | 순환·복귀 focus 유지 |
| 마우스 이동만 발생 | 입력 방식 변경 없음 | 우발적 포커스 모드 전환 없음 |

모달이 열릴 때의 접근성 포커스도 동일한 입력 방식 정책을 따라야 합니다. 포인터로 연 모달에 무조건 `grab_focus()`를 추가하려면 실제 터치 화면에서 잔류 강조가 없음을 별도 검증해야 합니다.

## 3. 스크롤 이벤트 경계

- passive `PanelContainer`, `Label`, `ProgressBar`, 장식 Control은 `MOUSE_FILTER_PASS` 또는 `IGNORE`를 사용해 상위 `ScrollContainer`의 drag를 막지 않습니다.
- 클릭 가능한 자식의 `STOP`은 허용하지만 tap과 drag가 충돌하지 않는 실제 제스처 테스트가 필수입니다.
- 스크롤 방향, `SCROLL_MODE_AUTO`, deadzone을 코드/씬에 명시합니다.
- 회귀 테스트는 최소한 카드 상단·본문·진행 표시 영역에서 drag를 시작하고 `scroll_vertical > before`를 확인합니다. 상태 복원용 직접 값 대입은 별도 테스트일 뿐 제스처 검증이 아닙니다.

## 4. 실패 전파 경계

필수 데이터 실패는 다음 순서로 처리합니다.

1. 하위 서비스가 구체적인 오류를 보존합니다.
2. 호출자는 관련 행동을 비활성화합니다.
3. 사용자 화면에는 안정 오류 코드와 build ID를 표시합니다.
4. 로그에는 안정 오류 코드, build ID, 원본 오류를 기록합니다.
5. 정상처럼 보이는 호환 화면으로 자동 전환하지 않습니다.

권장 오류 코드 영역:

- `CONTENT-*`: 프로필·카탈로그·필수 Resource
- `RUN-SELECTION`: 후보·심복 등 출격 선택
- `RUN-SCENE-*`: Godot 장면 전환 반환 오류
- `RUN-STARTUP`: Game 장면 진입 후 시작 계획 실패
- `RUN-CHECKPOINT`: 저장/복구 경계 실패

## 5. 변경 영향별 필수 검증

| 변경 범위 | 최소 검증 |
|---|---|
| 순수 계산·전투 로직 | 관련 계약 + `run_headless_quality_gate.ps1 -Mode full` |
| `res://` 경로, Resource, Autoload, 콘셉트/스테이지 | 위 항목 + `run_packed_export_runtime_gate.ps1` |
| 메뉴, 포커스, ScrollContainer, 터치 입력 | 위 항목 + `run_mobile_input_runtime_gate.ps1` |
| 장면 전환, export 설정, Android 산출물 | `run_mobile_release_quality_gate.ps1` 전체 |
| 배포 APK 생성 | `build_android_debug.ps1` + 옆 manifest + 서명/ABI/SDK 감사 |
| 모바일 완료 선언 | 신규 설치와 업그레이드 실기기 검사까지 완료 |

`run_mobile_release_quality_gate.ps1`는 리소스/입력/장면/export 변경의 기본 단일 진입점입니다. packed probe는 반드시 저장소와 무관한 빈 cwd에서 실행해야 합니다.

## 6. 코드 리뷰 체크리스트

- [ ] 소스 폴더 존재 여부가 런타임 플레이 가능성에 영향을 주지 않는가?
- [ ] 필수 데이터 누락이 정상처럼 보이는 레거시 UI로 숨겨지지 않는가?
- [ ] 터치 진입 뒤 focus owner가 남지 않는가?
- [ ] ScrollContainer의 모든 passive 자식이 drag를 전달하는가?
- [ ] 장면 전환 반환값과 장면 내부 시작 실패가 구분되는가?
- [ ] 실제 입력 이벤트와 packed export를 각각 실행했는가?
- [ ] 화면 버전, Android 버전, build ID, APK manifest가 같은 산출물을 가리키는가?
- [ ] 실기기를 실행하지 않았다면 그 사실과 남은 검증을 명시했는가?

## 7. 예외 승인

규칙 예외가 필요하면 구현 전에 다음 내용을 `docs/SHARED_CONTEXT.md`에 기록합니다.

1. 적용할 수 없는 규칙과 기술적 이유
2. 영향을 받는 플랫폼·씬·데이터
3. 대체 검증과 실패 시 사용자에게 보이는 상태
4. 예외 제거 조건과 담당 후속 작업

기록되지 않은 예외는 허용하지 않습니다.
