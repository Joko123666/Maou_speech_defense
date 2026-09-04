# 메인 허브·활성 전장 저디테일 배경 갱신

- 기준일: 2026-08-31
- 기준 프로필: `res://data/concepts/demon_election_vertical_slice.tres`
- 기준 화면: 1280×720, Godot 4.7 Forward Mobile
- 판정: 활성 적용·자동 검증·Android 패키징 완료, 승인 실기기 검증 보류

## 범위와 결과

활성 메인 허브와 선거 전장을 현재 캐릭터·UI의 굵은 남색 외곽선, 2단 셀 셰이딩, 큰 무광 색면 톤으로 다시 제작했다. 타이틀 전용 성채, 호환 편대 프로필 전장, 별도 동적 관중 리본은 요청 범위와 런타임 역할이 달라 보존했다. 파일명과 카탈로그 역할을 유지했으므로 메뉴·전투 코드나 저장 데이터는 바뀌지 않는다.

| 역할 | 활성 경로 | SHA-256 |
|---|---|---|
| 메인 허브 | `assets/graphics/backgrounds/demon_election_campaign_hq_v019.png` | `ACE7252DEEA7E052369A1949EF2990AA035C0D27DBA499AAFDAB84519A8A55EF` |
| 선거 전장 | `assets/graphics/backgrounds/demon_election_campaign_arena_v019.png` | `005976E816417ED9AC23B2378867540481D36AE029731F2BD5865F1FA35E4B49` |

두 파일은 1280×720 불투명 RGB이며 `assets/graphics/style_refresh_v019/backgrounds/`의 승인 보관본과 byte 단위로 같다. 교체 전 활성 PNG 2장은 `C:\Users\USER\Documents\GodotGames\Output\background_backup_20260831_pre_minimal`에 복구용으로 보존했다.

## 생성·후처리 계약

내장 ImageGen `stylized-concept`를 사용했다. 현재 배경은 배치 참조로만, `judaginda`·`partason` 전투 SD는 선·팔레트 참조로 사용했다.

- 공통 프롬프트: 16:9 모바일 전략 게임 환경, 굵은 deep-navy 외곽선, 정확히 2단 셀 셰이딩, 최대 5개 큰 색면, 짙은 eggplant/charcoal-blue와 절제된 burgundy/gold, 작은 magenta 강조, 캐릭터·HUD보다 약 35% 낮은 대비.
- 허브: 단순한 마계 유세 본부, 왼쪽 작은 작전 탁자와 오른쪽 봉인함, 중앙 65%와 상단 UI 밴드는 조용하고 저대비.
- 전장: 끊김 없는 넓은 자주 바닥, 왼쪽 12% 안의 작은 연단, 오른쪽 단순 관문, 성긴 상·하단 벽과 작은 모서리 불꽃.
- 금지: 인물·관중·문자·로고·버튼·HUD, 타일·균열·격자·반복 장식·세밀 석조·천 주름·체인·필리그리, gradient·painterly texture·bloom·fog·vignette·watermark.

생성 원본 1672×941은 `tools/prepare_background_style_refresh.ps1`의 중앙 cover crop·고품질 bicubic으로 1280×720 불투명 RGB에 정규화했다. 전장은 첫 생성본의 연단이 전투 영역에 가까워 정밀 편집으로 왼쪽 12% 안까지 축소한 변형을 최종 채택했다. 세부 사양과 활성/보관 경로는 `data/art/background_style_refresh_manifest_v2.json`이 소유한다.

## 검증

- 계약: 허브·전장 1280×720 디코드, 활성/보관본 byte 동일성, 활성 콘셉트 경로와 기존 전장·관중 안전 영역을 검사한다.
- Forward Mobile: UI 스냅샷 85개 생성 종료 코드 0. `main_menu`, `game_setup`, `demon_election_vanguard_squad`, `candidate_skill_cast_judaginda`, `audience_enemy_danger`, `audience_skill_release`를 원본 해상도로 직접 확인했다.
- 품질 게이트: 7/7 통과, `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_224113_129_29272\summary.json`.
- Android: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_minimal_backgrounds_debug.apk`, 68,462,376 bytes, SHA-256 `40B3160E97674567E39A1292FFF3C8F8B2ECF86196B23C85CD7F644CE3FF2376`.
- 패키지: `com.example.td_survival`, min SDK 24, target SDK 36, arm64-v8a 전용, 권한 0개, zipalign·v2/v3 서명 통과. 활성 배경 2종의 import/CTEX가 각각 1개이며 staging/tests/tools/reference/data-art는 0항목이다.

승인 Android 기기와 로컬 에뮬레이터가 없어 실제 설치·안전영역·터치·프레임·메모리·발열·배터리 검증은 이번 작업에 포함하지 못했다.
