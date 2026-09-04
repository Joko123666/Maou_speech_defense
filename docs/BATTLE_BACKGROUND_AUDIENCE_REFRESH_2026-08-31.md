# 전장 배경·동적 관중 연출 갱신

- 기준일: 2026-08-31
- 기준 콘셉트: `res://data/concepts/demon_election_vertical_slice.tres`
- 아트 기준: `godot_formation_defense_gdd_v0_19.md`의 플랫 카툰, 굵고 선명한 실루엣, 팩션 팔레트
- 판정: 구현 및 자동 검증 완료, Android 실기기 시각·발열 승인은 보류

## 문제와 결정

활성 선거 프로필은 세부 묘사가 많은 구형 `demon_election_rally_plaza.png`를, 호환 편대 프로필은 SF 성격이 남은 `battlefield_background.png`를 사용하고 있었다. 두 배경은 현재 캐릭터의 플랫 카툰 스타일과 시각 언어가 달랐고, 관중이 배경에 고정되어 게임 상황에 반응할 수 없었다.

두 프로필의 배경을 새 버전 파일로 교체하고 관중은 투명 리본과 런타임 연출 노드로 분리했다. 구형 파일은 런타임·테스트 참조가 0임을 재확인한 뒤 2026-08-31 저장소에서 제거했다.

## 최종 리소스

| 용도 | 최종 경로 | 규격 |
|---|---|---|
| 선거 캠페인 전장 | `assets/graphics/backgrounds/demon_election_campaign_arena_v019.png` | 1280×720, 불투명 RGB |
| 호환 편대 전장 | `assets/graphics/backgrounds/formation_campaign_arena_v019.png` | 1280×720, 불투명 RGB |
| 관중 리본 | `assets/graphics/audience/demon_spectator_ribbon_v019.png` | 1672×189, RGBA·투명 모서리 |

내장 ImageGen을 사용했다. 최종 프롬프트 세트는 다음 의도를 고정했다.

- 선거 전장: 16:9 플랫 카툰 지옥 선거 유세장, 중앙 전투 영역은 조용하게, 상단은 어두운 HUD 여백, 하단 10%는 비어 있는 관람석, 왼쪽 후보 연단과 오른쪽 적 관문, 인물·문자·그리드 없음.
- 호환 전장: 같은 구도와 여백의 중립 판타지 훈련장, 석재·청록·금색, SF 요소·인물·문자 없음.
- 관중: 투명 배경의 초광폭 얕은 한 줄, 작은 악마 관중 18명과 머리·손·깃발만 사용, 자주·버건디·금색, 환경·문자·체커보드 없음.

배경 두 장은 하단 관람석 높이를 줄이는 정밀 편집을 한 번 거쳤다. 관중 후보 중 체커보드가 실제 픽셀로 들어가 알파가 없던 변형은 폐기했고, 최종본은 알파 채널과 투명 상단 모서리를 직접 검사한 뒤 잘라 사용했다.

## 런타임 구성

`AudienceReactionStage`를 `Battlefield` 뒤, 적·후보 앞에 배치했다. 기존 전장 계약 `Rect2(150, 105, 1060, 540)`은 바꾸지 않았으며 관중은 전장 아래의 75px 밴드만 사용한다. 따라서 4×6 보드 좌표, 공격 범위, 적 이동 경로와 입력 판정은 그대로다.

| 상황 | 관중 반응 |
|---|---|
| 평상시 | 낮은 진폭의 호흡·상하 움직임 |
| 적이 후보에 접근 | 42% 이내 경고색·움직임 강화, 24% 이내 적색 떨림·위험 표식 |
| 스킬 시전 시작 | 후보 팩션색 펄스 |
| 스킬 해방 | 금색/팩션색 점프, 광선·다이아몬드 환호 표식 |
| 보스 경고 | 보라색 긴장 펄스 |
| 후보 피격 | 적색 충격 반응 |
| 보스 격파·승리 | 강한 금색 환호 |
| 패배 | 움직임 억제와 저채도 처리 |

접근성의 `reduced_motion_enabled`가 켜지면 bob·jitter·jump와 반응 표식을 끄고 의미를 전달하는 정적 색·광도 변화만 남긴다. 위협 거리는 0.12 게임초마다 가장 가까운 활성 적을 표본화해 불필요한 매 프레임 전체 순회를 피한다.

## 변경 경계

- `data/concepts/demon_election_assets.tres`, `formation_defense_assets.tres`: 새 배경 연결
- `scenes/game/game.tscn`: `AudienceStage`와 투명 관중 리본 연결, actor z 순서 명시
- `scripts/presentation/audience_reaction_stage.gd`: 레이아웃·반응·감소 모션 표현 소유
- `scripts/game/game_controller.gd`: 적 거리 표본과 기존 스킬/보스/피격/종료 이벤트 전달
- `tests/contracts/audience_presentation_contract_test.gd`: 해상도·알파·안전 영역·상태·연결·내보내기 계약
- `tests/ui_snapshot_runner.gd`, `data/ui/ui_snapshot_manifest_v1.json`: 스킬·위험·감소 모션 3상태 추가, 총 84개
- `export_presets.cfg`: 검수·참조·감사 전용 소스의 Android 패키지 제외

## 검증 결과

- Godot 4.7 헤드리스 편집기 파싱·리소스 임포트: 종료 코드 0.
- 전체 스모크: `SMOKE TEST PASS`, 신규 관중 계약 포함.
- 7단계 헤드리스 품질 게이트: 7/7 통과. 요약은 `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_004249_464_27980\summary.json`.
- Forward Mobile UI 스냅샷: 84개 생성, 종료 코드 0. 일반 전투·스킬·보스 경고와 신규 `audience_skill_release`, `audience_enemy_danger`, `audience_reduced_motion_skill`을 원본 해상도로 직접 확인했다.
- 3× 120초 실제 창 감사: 평균 5.582ms, 최악 16.667ms, 16ms/33ms 초과 0프레임, 코어 스킬 6회, 최대 활성 적 10·효과 26·투사체 4.
- Android arm64 디버그 APK: 오래된 리소스 삭제·비런타임 경계 정리 뒤 2026-08-31 재빌드 종료 코드 0, 65,278,805 bytes(62.25MiB), SHA-256 `82224C8840E4282FB4994F70595FDE91064DAC9387B01CEED57D42811C46954B`. 패키지 `com.example.td_survival`, min SDK 24/target SDK 36, arm64 전용, landscape, 앱 권한 0개, zipalign과 v2/v3 서명을 통과했다. APK 목록에 새 배경 2종과 관중 리본이 있으며 구형 배경·tests·tools·검수 원본·`reference/`·감사 전용 코드는 없다.

## 남은 외부 검증

연결된 승인 Android 기기가 0대이고 로컬 Android 에뮬레이터도 설치되어 있지 않아 설치·부팅은 실행하지 못했다. 따라서 실제 기기의 안전영역, 손가락 입력, 장시간 프레임·메모리·발열·배터리와 화면 판독성은 아직 승인하지 않았다. 설치 가능한 최신 APK는 `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_minimal_backgrounds_debug.apk`이다.

## 2026-08-31 후속 저디테일 선거 전장 재생성

- 호환 편대 전장과 동적 관중 리본은 보존하고 활성 선거 전장만 다시 생성했습니다. `Battlefield`의 `Rect2(150, 105, 1060, 540)`과 하단 75px 관중 영역도 바꾸지 않았습니다.
- 내장 ImageGen `stylized-concept`에 현재 후보 SD를 톤 참조로 주고 굵은 남색 외곽선, 2단 셀 셰이딩, 넓고 연속된 짙은 자주 바닥을 고정했습니다. 연단은 화면 왼쪽 12% 이내로 줄이고 오른쪽 관문·모서리 불꽃만 남겼으며 타일·균열·격자·장식 조각·문자·인물·관중은 제외했습니다.
- 생성 원본을 1280×720 불투명 RGB로 정규화했습니다. 활성본과 `assets/graphics/style_refresh_v019/backgrounds/` 보관본의 SHA-256은 `005976E816417ED9AC23B2378867540481D36AE029731F2BD5865F1FA35E4B49`로 일치합니다.
- Forward Mobile 85개를 재생성하고 `demon_election_vanguard_squad`, `candidate_skill_cast_judaginda`, `audience_enemy_danger`, `audience_skill_release`를 원본 해상도로 확인했습니다. 유닛·격자·상태 효과와 관중보다 배경 대비가 낮고 정보 가림이 없습니다.
- 전체 품질 게이트 7/7 보고서는 `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_224113_129_29272\summary.json`입니다. 최신 APK는 68,462,376 bytes, SHA-256 `40B3160E97674567E39A1292FFF3C8F8B2ECF86196B23C85CD7F644CE3FF2376`이며 활성 전장 import/CTEX 포함과 비런타임 경로 0항목을 확인했습니다.
