# 상태·사신·죽음교 대원 전투 비주얼 갱신

- 날짜: 2026-08-31
- 기준: `godot_formation_defense_gdd_v0_19.md`
- 상태: 리소스 생성·활성 연결·Forward Mobile 시각 검수·전체 품질 게이트·Android 디버그 export 완료

## 변경 범위

단순 CanvasItem 도형으로만 표시되던 16종 상태 시각, 주다긴다의 사신 소환 본체, 죽음교 돌격부대 인원 스택을 v0.19의 `비비드 카툰 × 굵은 외곽선 × 마계 선거 포스터` 방향으로 갱신했다. 모두 내장 ImageGen `stylized-concept` 흐름으로 생성했으며 실제 RGBA 투명 배경, 굵은 딥 네이비 외곽선, 2단 셀 셰이딩과 모바일 축소 실루엣을 공통 계약으로 사용한다.

| 리소스 | 활성 경로 | 원본/임포트 | 런타임 용도 |
|---|---|---|---|
| 상태 아이콘 아틀라스 | `assets/graphics/effects/status_effect_icon_atlas_v019.png` | 1024px RGBA / 512px | 4×4 한 장에서 16종 상태를 선택 표시 |
| 사신 소환 | `assets/graphics/effects/reaper_summon_v019.png` | 1024px RGBA / 512px | 주다긴다 필살 공약의 별도 사신 현현 |
| 죽음교 대원 토큰 | `assets/graphics/effects/death_vanguard_member_token_v019.png` | 512px RGBA / 256px | 돌격부대 현재/최대 인원 스택 |

검수·파생 원본은 같은 파일명으로 `assets/graphics/style_refresh_v019/effects/`에 보존하며 Android export에서는 기존 staging 제외 규칙을 따른다. 생성물의 알파 추출 뒤 잔여 극저알파 후광을 제거하고 정사각 캔버스로 맞추는 과정은 `tools/prepare_combat_visual_style_refresh.ps1`로 재현한다. 상세 매핑과 해시는 `data/art/combat_visual_style_refresh_manifest_v1.json`이 소유한다.

## 상태 표현 정책

- 독·출혈·감전·화상과 기절·빙결·공포·환혹은 아틀라스 아이콘으로 실루엣을 직접 표시한다.
- 둔화 파동, 표식 모서리, 방어 강화 브래킷, 넉백 방향선은 위치·방향·움직임 정보가 중요하므로 절차형 선을 유지하고 같은 아틀라스 아이콘을 함께 표시한다.
- 선고·빙결 중첩은 최대 3개 소형 아이콘, 공통 피해 상태는 종류당 아이콘 1개와 최대 3개 중첩 점으로 제한한다.
- 적마다 텍스처나 자식 노드를 만들지 않는다. 모든 적이 하나의 512px 임포트 아틀라스를 공유하며 파티클·셰이더·전체 화면 광원은 추가하지 않는다.

## 사신·대원 정책

- `ReaperSummon`의 둥근 후드·점눈·도형 낫 본체를 우향 공격 키 포즈의 사신 SD로 교체했다. 시전 부유, 원형 오라와 일격 궤적은 기존 절차형 타이밍을 유지해 스킬 진행 상태를 잃지 않는다.
- `VanguardSquadComponent`의 원·막대기 대원을 후드·상아 마스크·붉은 스카프 흉상 토큰으로 교체했다. 활성 대원은 원색, 소모된 슬롯은 저채도·저알파로 표시하고 충원 펄스·게이지·`부대 x/y` 텍스트는 유지한다.

## 시각 검수

- `tests/visual_reviews/status_effect_visual_review.png`: 16종 개별 형태·색·배치 판독
- `tests/visual_reviews/status_effect_density_review.png`: 40개 적 혼합 상태에서도 체력바·행 경계·본체 식별 유지
- `tests/ui_snapshots/candidate_skill_cast_judaginda.png`: 사신 본체와 일격 궤적, 후보·친위대·적 겹침 확인
- `tests/ui_snapshots/demon_election_vanguard_squad.png`: 2/3 토큰, 충원 게이지와 텍스트 판독 확인

## 자동·Android 검증

- Godot 4.7 전체 품질 게이트: parse, content, meta, preparation, smoke, tutorial, verbose 7/7 통과
- 보고서: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_220408_189_25520\summary.json`
- APK: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_combat_visual_style_debug.apk`
- 크기: 68,970,280 bytes(65.78MiB)
- SHA-256: `C66A45FFF50819F8229B88B659CE6DFF19D189684BCFBDF1C40FA9995E3464C7`
- 패키지 `com.example.td_survival`, min SDK 24, target SDK 36, arm64-v8a 단일 ABI, zipalign과 v2/v3 서명 통과
- APK에는 신규 활성 리소스 3종의 import/CTEX가 포함되고 `style_refresh_v019`, `tests`, `tools`, `reference`, `data/art` 항목은 각각 0개다.

실제 Android 기기의 물리 화면에서 1×·3× 속도 판독성, 터치 가림, 장시간 GPU 비용·발열은 별도 승인 항목이다.
