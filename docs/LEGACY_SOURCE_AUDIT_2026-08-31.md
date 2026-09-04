# 오래된·미참조 소스 잔존 감사

- 기준일: 2026-08-31
- 범위: `autoload/`, `scripts/`, `resources/`, `scenes/`, `data/`, `assets/`, `reference/`, `tmp/`, Android APK
- 방식: 런타임 진입점·리소스 경로·`class_name` 사용처 전수 검색, 활성 씬의 과도기 노드 확인, APK ZIP 항목 역검사
- 변경: 감사 뒤 참조 0 후보를 삭제하고 Android 비런타임 제외 경계를 갱신했다.

## 판정

확정된 미사용 원본과 임시 작업물은 정리됐다. 현재 게임 동작과 Android 빌드에 구형 런타임 참조는 없으며, 디자인 원본·검수 메타데이터·감사 코드처럼 저장소에 남겨야 하는 개발 자료도 Android 패키지에서는 제외된다.

## 삭제 완료

| 항목 | 처리 | 회수/영향 |
|---|---|---|
| 구형 배경 `battlefield_background.png`, `demon_election_rally_plaza.png`와 import 2개 | 삭제 | 4.54MiB, 활성 v0.19 배경 2종만 유지 |
| `feature_gate_data.gd`, `unlockable_content_data.gd`와 UID | 삭제 | v0.6 미사용 Resource 스키마 2개 제거 |
| `scenes/battlefield/tower_column.tscn` | 삭제 | 실제 `TowerColumn.new()` 생성 경로만 유지 |
| 탈락 SD `given.png`, `jeomujeom.png`와 import 2개 | 삭제 | 2.83MiB, 승인 `given_v2.png`·`jeomujeom_v2.png` 유지 |
| `tmp/` | 177개 파일 전체 삭제 | 136.58MiB 작업 잔재 제거 |
| 삭제 원본의 `.godot/imported` CTEX·MD5 | 활성 import 해시와 대조 후 10개 삭제 | 7.14MiB 생성 캐시 제거 |

소스·작업 잔재 150,943,031 bytes와 생성 캐시 7,486,445 bytes, 총 158,429,476 bytes(151.09MiB)를 작업공간에서 제거했다. 저장소가 Git이 아니므로 외부 백업이 없다면 소스·작업 잔재 삭제는 작업공간에서 복구할 수 없다. `.godot` 캐시는 필요할 때 Godot이 다시 생성한다.

## 저장소 보존·Android 제외

- `reference/`의 UIUX 3장·char 13장은 디자인 원본이므로 보존하고 Android 내보내기에서 제외했다. APK의 이전 import+CTEX 32항목은 0항목이 됐다.
- `scenes/ui/components/icon_chip.tscn`/`.gd`는 공용 컴포넌트 계약이 사용하므로 보존하고 Android에서만 제외했다.
- `scripts/game/balance_audit_summary.gd`, `scripts/meta/first_five_run_economy_audit.gd`는 감사 테스트가 사용하므로 보존하고 Android에서만 제외했다.
- `data/art/character_style_refresh_manifest_v1.json`, `character_style_refresh_m6_review_catalog.json`은 검수 provenance이므로 보존하고 Android에서만 제외했다.
- `data/concepts/example_arcane_reskin.tres`, `formation_defense.tres`: 시작 프로필에서는 사용하지 않고 테스트에서만 직접 전환한다. 다만 전자는 콘셉트 교체 예시, 후자는 명시적 호환 프로필이라는 프로젝트 계약이 있으므로 제품이 단일 선거 콘셉트만 배포한다는 결정 전에는 삭제하지 않는다.

## 과도기 UI 소스

아티팩트 교체, 전투 결과, 일시정지/전투 옵션은 2026-09-03에 공용 `ModalShell` 상속 씬으로 직접 이관했다. 세 화면은 이제 구형 `Dim`/`Dimmer`/`Center`/`Panel`/`Result*` 껍데기를 만들지 않고, `_ready()`의 `reparent()`나 `queue_free()` 없이 처음부터 공용 본문과 고정 푸터에 콘텐츠를 둔다. 기존 신호·포커스·확인 절차와 85개 Forward Mobile 화면은 유지된다.

남은 과도기 경계는 `main_menu.tscn/.gd` 하나다. 출격·상점·업적·도감 콘텐츠를 구형 `Center/Panel`에 작성한 뒤 런타임 `PageShell`로 옮기고 구형 컨테이너를 숨긴다. 씬 자체가 처음부터 공용 `PageShell` 구조를 갖도록 별도 이관해야 하며, 현재 게임 기능 오류는 아니다.

## 유지해야 하는 호환 코드

다음 `legacy` 표기는 오래된 찌꺼기가 아니라 저장·체크포인트·외부 콘텐츠 호환 경계이므로 현재는 유지한다.

- `SaveManager`의 구버전 세이브 정규화, `legacy_full_unlock`, 이전 모듈 ID 제거와 적 조우 이관
- `EnemyCatalogV015.LEGACY_REFERENCE_MIGRATION`
- `ElectionFactionData.LEGACY_MARKER_ALIASES`
- 심복의 `legacy_cursor_id`와 체크포인트 상태 import
- 폐기된 `global_upgrade`의 읽기·거부 경계와 기존 결과/체크포인트 필드

또한 `demon_election_campaign_v0_8.tres`, `tutorial_v0_17.tres`, `artifact_catalog_v0_19.tres`처럼 파일명에 과거 버전이 붙은 데이터는 활성 프로필이나 현재 서비스가 직접 로드하므로 이름만 보고 삭제하면 안 된다.

## 남은 별도 개선

1. `IconChip`을 실제 UI에 적용할지 테스트 지원 컴포넌트로 유지할지 다음 UI 개편에서 결정한다.
2. `main_menu.tscn/.gd`의 출격·상점·업적·도감 런타임 reparent와 구형 `Center/Panel`을 제거하고 85개 Forward Mobile 스냅샷과 전체 품질 게이트를 다시 승인한다.

## 재검증 결과

- Godot 4.7 헤드리스 편집기 파싱: 종료 코드 0.
- 7단계 헤드리스 품질 게이트: 최신 소스 재검증 7/7 통과, `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_113753_269_13384\summary.json`.
- Android arm64 디버그 APK: 65,278,805 bytes(62.25MiB), 이전 82.34MiB 대비 20.08MiB·24.39% 감소.
- APK SHA-256: `82224C8840E4282FB4994F70595FDE91064DAC9387B01CEED57D42811C46954B`.
- `reference/`, `data/art/`, 검수 원본, 테스트·도구, 감사 코드, `IconChip`, 삭제된 구형 리소스는 모두 APK 0항목이다. 활성 배경 2종과 관중 리본은 각 import+CTEX 2항목으로 유지된다.
- zipalign, arm64 단일 ABI, 패키지 `com.example.td_survival`, v2/v3 서명을 통과했다. 연결된 승인 Android 기기는 0대이므로 설치·부팅 검증은 별도 남는다.

### 2026-09-03 모달 구조 정리 재검증

- `artifact_resolution_panel`, `pause_menu`, `combat_result_overlay`가 공용 `ModalShell`을 씬 기준으로 직접 상속하며 세 스크립트의 `.reparent()`와 구형 shell 노드는 0건이다.
- `UiUxM6ModalFlowsContractTest`가 런타임 reparent 금지와 구형 모달 노드 부재를 회귀 계약으로 검사한다.
- Forward Mobile 스냅샷 85개를 재생성하고 `artifact_replacement`, `pause_menu`, `pause_options`, `result_screen`, `result_screen_details`, `result_screen_defeat`를 직접 확인했다.
- 7단계 헤드리스 품질 게이트 7/7 통과: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260903_215936_690_20928\summary.json`.
- 런타임 리소스 추가가 없어 Android APK는 다시 만들지 않았다. 최신 패키지 판정은 공유 컨텍스트의 공식 난입 M4 APK 기록을 유지한다.
