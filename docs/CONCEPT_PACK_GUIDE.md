# 게임 콘셉트·리소스 교체 가이드

이 프로젝트는 전투 규칙을 유지한 채 세계관, 용어, 색상, 이미지, 사운드, 스테이지와 콘텐츠 카탈로그를 교체할 수 있도록 두 계층으로 나눕니다.

```text
project.godot
  └─ game/concept_profile
       └─ GameConceptData (.tres)
            ├─ 브랜드·용어·색상
            ├─ GameTextCatalogData
            ├─ GameAssetCatalogData
            │    ├─ 그래픽 루트·ID별 오버라이드
            │    ├─ 필수 배경·폴백·발사체
            │    └─ 역할별 효과음
            ├─ 기본 StageData·StageRewardData
            ├─ 선택적 ElectionCampaignData
            └─ 선택적 ContentPackData
                 ├─ 핵·목표지점
                 ├─ 타워·편대·분기·특화·모듈
                 └─ 일반 적·보스
```

## 빠른 리스킨

1. [`formation_defense.tres`](../data/concepts/formation_defense.tres), [`formation_defense_texts.tres`](../data/concepts/formation_defense_texts.tres), [`formation_defense_assets.tres`](../data/concepts/formation_defense_assets.tres)를 각각 복제합니다.
2. 새 프로필의 `text_catalog`와 `assets`를 복제한 카탈로그에 연결합니다.
3. 프로필의 `Identity`, `Terminology`, `Palette`, `Stage`와 텍스트 카탈로그 문구를 바꾸고 에셋 카탈로그의 그래픽·오디오를 교체합니다.
4. [`project.godot`](../project.godot)의 `game/concept_profile`을 새 프로필 경로로 바꿉니다.
5. Godot을 다시 실행합니다.

[`example_arcane_reskin.tres`](../data/concepts/example_arcane_reskin.tres)는 동일한 게임 규칙과 리소스를 사용하면서 브랜드, 한국어 역할명과 색상만 판타지 콘셉트로 바꾼 예시입니다.
[`demon_election_vertical_slice.tres`](../data/concepts/demon_election_vertical_slice.tres)는 후보·심복·진영 5종과 선거 UI, 지지도·칙령·통치 정산을 연결한 GDD v0.10 기본 실행 프로필입니다. 캠페인이 없는 일반 Formation Defense 프로필은 명시적으로 선택할 수 있는 대체 콘셉트로 유지됩니다.

프로필에서 바꿀 수 있는 주요 항목은 다음과 같습니다.

| 그룹 | 적용 범위 |
|---|---|
| Identity | 창 제목, 메인 메뉴 브랜드, 챕터명, 히어로 문구, 준비 상태 |
| Terminology | 핵, 목표지점, 타워, 편대, 적, 재화, 스테이지 명칭 |
| Text | 메뉴·출격·HUD·결과의 필수 키 기반 문구와 `{core}` 같은 용어 토큰 |
| Palette | 메뉴 강조색, 배경 틴트·오버레이, 전장 바탕색 |
| Assets | 별도 `GameAssetCatalogData`에 연결된 그래픽·오디오 묶음 |
| Stage | 기본 스테이지 진행표와 해당 스테이지 보상표 |
| Optional campaign | 전투 Core/Cursor/Enemy/Boss ID와 연결되는 후보·심복·진영 메타 데이터 |

내보내기 아이콘과 앱 표시 이름처럼 실행 전 빌드에 결정되는 항목은 `project.godot`과 Export Preset에서 별도로 바꿔야 합니다.

## ID 기반 그래픽 교체

기본 내장 카탈로그는 에셋 카탈로그의 `graphics_root` 아래에서 ID와 같은 PNG를 먼저 찾습니다.

```text
my_pack/graphics/
  cores/emerald.png
  cursors/iron.png
  towers/rapid.png
  defenders/rapid.png
  defender_icons/rapid.png
  enemies/normal.png
  candidates/partason.png
  retainers/kanda.png
  factions/partason_faction.png
  emblems/partason_crown.png
```

일반 수비병력의 전신 전투 아트는 `defenders/{tower_id}.png`, 레벨업·편대 정보용 얼굴 아이콘은 `defender_icons/{tower_id}.png`를 사용합니다. 후보 전용 친위대는 `towers/{unique_tower_id}.png`의 전용 전신 아트를 사용합니다. 얼굴 아이콘이 없으면 해당 병력의 전신 아트로 안전하게 대체됩니다. 그 밖의 파일이 없으면 역할에 맞는 코어·커서·타워·적 폴백을 사용합니다. PNG 규칙을 쓰기 어렵거나 특정 ID만 별도 파일을 사용하려면 `content_texture_overrides`에 `cores/emerald`, `candidates/partason` 형식의 키와 `Texture2D`를 등록합니다. 오버라이드가 경로 규칙보다 우선합니다. 의도적으로 같은 분류의 다른 이미지를 재사용할 때만 `approved_content_aliases`에 `enemies/zigzag = enemies/shifter`처럼 안정 ID 간 관계를 명시합니다. 별칭은 같은 분류의 실제 리소스만 한 단계로 가리킬 수 있으며, 누락 폴백과 별도로 감사됩니다. `audio_overrides`는 핵 5종의 `core_skill_{core_id}`와 타워 공격군 `tower_rapid/blast/energy/saw/arcane`을 필수로 제공합니다. 후보 대사나 보스별 등장음은 같은 안전한 이름 키 규칙으로 추가할 수 있습니다.

조회는 `ConceptService`가 프로필별로 캐시합니다. 프로필을 교체하면 캐시와 누락 기록이 함께 초기화되며, 누락된 ID별 그래픽은 `get_missing_content_assets()`로 진단할 수 있습니다. 콘텐츠 ID는 영문 소문자·숫자·`_`·`-`만 허용하므로 `../` 같은 경로 탈출 문자열은 파일 경로로 조합되지 않습니다.

## 에셋 카탈로그의 시작 전 검증

`GameAssetCatalogData.get_validation_errors()`는 다음 문제를 프로필 활성화 전에 차단합니다.

- 비어 있는 카탈로그 ID
- `res://` 밖의 그래픽 루트, `..`가 포함된 경로, 존재하지 않는 디렉터리
- `cores`, `cursors`, `towers`, `enemies` 필수 하위 디렉터리 누락
- 메뉴·전장·4종 역할 폴백·2종 발사체 텍스처 누락
- 핵 액티브 5종과 타워 공격군 5종 필수 오디오 변형 누락
- UI·레벨업·보스·핵 스킬·피격·승리·패배의 10개 필수 오디오 누락
- 잘못된 `content_texture_overrides` 키 또는 `Texture2D`가 아닌 값
- 안전하지 않은 키, 교차 분류, 자기 참조, 연쇄 또는 없는 대상을 사용하는 `approved_content_aliases`
- 잘못된 `audio_overrides` 키 또는 `AudioStream`이 아닌 값

프로필과 에셋 카탈로그를 분리했기 때문에 같은 아트·사운드 묶음을 여러 용어·팔레트 프로필이 공유할 수 있고, 아트 팩만 교체할 때 스테이지나 전투 데이터까지 복제할 필요가 없습니다.

## 전체 콘텐츠 팩 교체

공격 수치와 명칭까지 바꾸려면 `ContentPackData` 리소스를 만들고 프로필의 `content_pack`에 연결합니다. 다음 8개 카탈로그는 모두 필요합니다.

- `cores`, `cursors`, `towers`, `formations`
- `tower_branches`, `specialization_branches`
- `enemies`, `bosses`

각 배열에는 대응하는 `CoreData`, `CursorData`, `TowerData`, `TowerFormationData`, `TowerBranchData`, `SpecializationBranchData`, `EnemyData` 리소스를 넣습니다. 외부 콘텐츠의 개별 이미지에는 각 데이터 리소스의 `texture`를 지정하고, 비워 두면 프로필 폴백이 사용됩니다.

시작 시 `ContentPackData.get_validation_errors()`가 다음을 검사합니다.

- 팩 ID와 필수 카탈로그 누락
- null 항목, 빈 ID, 같은 카탈로그 안의 중복 ID
- 편대의 연결되고 정규화된 2~4셀 구성과 최소 1개 일반 편대
- 편대 → 타워·전용 핵, 핵 → 전용 타워·편대, 타워 분기 → 타워 참조
- 핵·목표지점 특화의 소유자 참조
- `StageData`의 스폰 가중치·그룹, 보스 시간과 `default_boss_ids` 슬롯 수·중복·참조, 명시적 `final_boss_id`
- `StageRewardData`의 스테이지 ID·시간과 보스별 보상 참조

`GameConceptData`도 기본 스테이지와 보상표의 존재·ID·시간 일치를 함께 검사합니다. 불완전한 프로필은 활성화하지 않고 시작 시 기본 프로필로 안전하게 되돌아갑니다.

## 선택적 선거 캠페인

`ElectionCampaignData`는 `CandidateProfileData`, `RetainerProfileData`, `ElectionFactionData`를 전투 데이터와 분리해 소유합니다. 후보의 `core_id`, 심복의 `cursor_id`, 진영의 일반 적·보스 ID는 활성 카탈로그와 교차 검증됩니다. 같은 캠페인을 `GameConceptData.election_campaign` 또는 외부 `ContentPackData.election_campaign` 중 한 곳에만 연결해야 합니다.

현재 `demon_election_campaign_v0_8.tres`는 후보·심복·진영을 각각 5종 연결합니다. 출격 화면은 `candidate.core_id`와 `retainer.cursor_id`를 기준으로 선택 항목과 프로필 카드를 연결하며 후보 구호·진영 색·기본 전투 수치·심복 역할·선호 조합·경쟁 진영을 표시합니다. `demon_election_assets.tres`는 `candidates/{candidate_id}`, `retainers/{retainer_id}`, `emblems/{emblem_id}` 오버라이드로 전용 초상과 SVG 문양을 소유합니다. 전투에서는 `supporter_enemy_ids`로 소속 진영을 해석하고 색상 비의존 외곽 표식, 진영 팔레트와 부활 인장 송환을 적용합니다. 런타임 보스 계획은 선택 후보를 제외한 네 경쟁 진영을 결정적으로 배치하며 스포너·승리 판정·결과·체크포인트가 같은 계획을 사용합니다. 후보별 지지도·당선·칙령과 통치 지지율은 세이브 v9의 `run_id` 원자 정산에 포함됩니다.

## 교체 시 지켜야 할 계약

- 저장 데이터와 메타 해금은 콘텐츠 ID를 사용합니다. 기존 세이브를 이어갈 빌드는 기존 ID를 유지하는 편이 안전합니다.
- 편대의 `cells`는 중복 없는 좌표로 연결된 2~4셀이어야 하며 각 `tower_id`는 팩에 실제로 존재하는 병력 ID여야 합니다.
- 핵의 `unique_tower_id`와 `unique_formation_id`는 서로 대응하는 전용 콘텐츠를 가리켜야 합니다.
- `StageData.spawn_table.weights`와 `groups`의 키는 일반 적 ID와 일치해야 합니다.
- `bosses`는 전체 출현 가능 카탈로그이므로 4개보다 많아도 됩니다. `boss_times`와 `default_boss_ids`는 정확히 같은 수의 기본 슬롯을 가지며 중복 없이 카탈로그를 참조해야 합니다. `StageData.final_boss_id`는 기본 계획의 마지막 ID와 일치하고, 보상표의 `boss_funds_by_id`는 모든 보스 ID를 포함해야 합니다.
- `attack_type`, `skill_type`, `behavior`, `target_rule`, `effect_type` 같은 동작 키는 현재 전투 코드가 지원하는 값을 사용합니다. 새 동작 키를 추가하는 경우에만 전투 전략 코드를 확장합니다.
- 콘텐츠 팩은 `DataRegistry`가 시작할 때 한 번 읽습니다. 팩을 바꾼 뒤에는 게임을 다시 실행해야 합니다. 브랜드 프로필의 런타임 로드는 지원하지만 이미 생성된 모든 노드를 즉시 다시 꾸미는 라이브 테마 편집기는 아닙니다.

## 코드 경계

- [`concept_service.gd`](../autoload/concept_service.gd): 선택된 프로필 로드, 용어·이미지·사운드 접근
- [`game_concept_data.gd`](../resources/game_concept_data.gd): 프레젠테이션, 에셋 카탈로그와 기본 스테이지 계약
- [`game_text_catalog_data.gd`](../resources/game_text_catalog_data.gd): 필수 UI 문구와 토큰 치환 계약
- [`game_asset_catalog_data.gd`](../resources/game_asset_catalog_data.gd): 그래픽·오디오 역할, 안전한 ID 경로와 필수 에셋 검증
- [`content_pack_data.gd`](../resources/content_pack_data.gd): 전체 게임 카탈로그 계약과 참조 검증
- [`election_campaign_data.gd`](../resources/election_campaign_data.gd): 후보·심복·진영 수량, 안정 ID와 전투 카탈로그 교차 검증
- [`stage_runtime_boss_plan.gd`](../resources/stage_runtime_boss_plan.gd): 이번 출격의 보스·진영·시간·최종 보스와 체크포인트용 불변 스냅샷
- [`campaign_stage_resolver.gd`](../scripts/game/campaign_stage_resolver.gd): 게임 RNG를 소비하지 않는 결정적 경쟁 진영 계획과 명시적 고정 폴백
- [`data_registry.gd`](../autoload/data_registry.gd): 외부 팩 우선 로드, 없거나 불완전하면 내장 카탈로그 생성

게임 로직에서는 `res://assets/...`를 직접 읽지 않고 `ConceptService.texture()`, `content_texture()`, `audio()` 또는 데이터 리소스의 `texture`를 사용합니다. 새 UI는 `ConceptService.term()`과 `ui_text()`를 사용해 역할명과 문장 전체를 함께 교체합니다.

## 검증

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . res://tests/smoke_test.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --path . res://tests/ui_snapshot.tscn
```

스모크 테스트는 기본 선거 프로필의 캠페인·스테이지·보상·텍스트·에셋 카탈로그, 그래픽 조회 캐시, 안전하지 않은 ID의 폴백·진단, 잘못된 그래픽 루트 거부, 빈 팩과 잘못된 블록 편대·적 ID·최종 보스 ID 거부, 사용자 정의 최종 보스 ID 승인, 일반/판타지 프로필 전환과 기본 선거 프로필 복귀를 검사합니다. 분리된 `tests/contracts/asset_coverage_contract_test.gd`는 런타임 안정 ID의 전용·승인 별칭·누락 상태를 고정하고 잘못된 별칭 계약을 거부합니다. `tests/contracts/election_campaign_contract_test.gd`는 텍스트 필수 키·문자/숫자 토큰 치환, 후보·심복·진영 교차 참조와 보스 표시 조회, 선거 전용 에셋 카탈로그 ID, 후보·심복 초상 512×512 규격, 진영 문양과 적 팔레트 소유권·중복 거부를 검사합니다. 스모크 통합 검증은 선거 출격 카드의 선택별 초상·문양 교체와 후보별 공약 레벨업·진영 보스 HUD도 검사하며, UI 스냅샷은 판타지 리스킨과 `demon_election_vertical_slice.png`, `demon_election_game_setup.png`, `demon_election_faction_showcase.png`, `demon_election_boss_warning.png`, `demon_election_level_up.png`를 함께 생성합니다. 초상 제작 기준과 재생성용 핵심 프롬프트는 `docs/DEMON_ELECTION_PORTRAIT_PROMPTS.md`에 기록합니다.
