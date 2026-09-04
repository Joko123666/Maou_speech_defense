# TD Survival 리소스 리스트

- 기준일: 2026-09-03
- 기준 프로필: `res://data/concepts/demon_election_vertical_slice.tres`
- 에셋 카탈로그: `res://data/concepts/demon_election_assets.tres`
- 집계 범위: 런타임 그래픽·오디오, `.tres` 데이터 인스턴스, `.tscn` 씬, `resources/`의 Resource 스키마
- 제외: Godot 생성 파일(`.import`, `.uid`), 테스트 스냅샷, 임시 작업물, 문서 이미지, 검수·파생 원본 `assets/graphics/style_refresh_v019/` 82개

## 1. 요약

| 분류 | 수량 | 기준 경로 |
|---|---:|---|
| 그래픽 | 162 | `res://assets/graphics/` |
| 오디오 | 25 | `res://assets/audio/` |
| 데이터 인스턴스 | 21 | `res://data/` |
| 런타임 씬 | 19 | `res://scenes/` |
| Resource 스키마 | 65 | `res://resources/` |
| 합계 | 292 | 생성 파일·검수 파생 원본·테스트 전용 씬 제외 |

활성 콘셉트 프로필은 배경, 텍스트, 스테이지, 보상, 선거 캠페인과 에셋 카탈로그를 묶습니다. 콘텐츠 이미지는 명시적 오버라이드 → 규칙 경로 → 승인 별칭 → 분류별 폴백 순으로 해석됩니다.

## 2. 그래픽 리소스

### 2.1 배경 — 4개

경로: `res://assets/graphics/backgrounds/`

- `demon_election_title_citadel_v019.png` — 활성 선거 프로필의 전용 타이틀 성채 배경
- `demon_election_campaign_hq_v019.png` — 활성 선거 프로필의 저디테일 유세 본부·하위 메뉴 배경
- `demon_election_campaign_arena_v019.png` — 활성 선거 프로필의 저디테일 플랫 카툰 전장 배경
- `formation_campaign_arena_v019.png` — 대체 콘셉트 프로필용 플랫 카툰 호환 배경

### 2.1-A 동적 관중 — 1개

경로: `res://assets/graphics/audience/`

- `demon_spectator_ribbon_v019.png` — 하단 75px 관중 반응 무대용 투명 악마 관중 리본

### 2.2 후보 초상 — 5개

경로: `res://assets/graphics/candidates/`

- `partason.png` — 파르타손
- `jiane.png` — 지아네
- `kasuha.png` — 카스하
- `irelai.png` — 이레라이
- `judaginda.png` — 주다긴다

### 2.3 심복 초상 — 5개

경로: `res://assets/graphics/retainers/`

- `kanda.png` — 칸다
- `given.png` — 기븐
- `jeomujeom.png` — 저무점
- `jugdied.png` — 주그디에드
- `death_vanguard.png` — 죽음교 돌격부대

### 2.4 후보 전투 SD — 5개

경로: `res://assets/graphics/combat_sd/candidates/`

- `partason.png`
- `jiane.png`
- `kasuha.png`
- `irelai.png`
- `judaginda.png`

### 2.5 심복 전투 SD — 5개

경로: `res://assets/graphics/combat_sd/retainers/`

- `kanda.png`
- `given.png`
- `jeomujeom.png`
- `jugdied.png`
- `death_vanguard.png`

### 2.5-A 후보·심복·대체 간부 공식 난입 SD — 15개

경로: `res://assets/graphics/candidate_intrusion_sd/`, `res://assets/graphics/retainer_intrusion_sd/`, `res://assets/graphics/guard_intrusion_sd/`

- 후보 5개: `partason.png`, `jiane.png`, `kasuha.png`, `irelai.png`, `judaginda.png`
- 심복 5개: `kanda.png`, `given.png`, `jeomujeom.png`, `jugdied.png`, `death_vanguard.png`
- 대체 간부 5개: `partason_faction.png`, `jiane_faction.png`, `kasuha_faction.png`, `irelai_faction.png`, `judaginda_faction.png`

선거 공식 난입에서는 이 15개가 실제 보스 본체 이미지다. 앞 세 슬롯은 심복 또는 선택 심복 중복을 피한 같은 진영 대체 간부, 마지막 슬롯은 미선택 후보 본인을 사용한다.

활성 선거 프로필은 제작된 좌향 난입 SD를 반전 없이 우선 사용합니다. 이 선택 카테고리가 없는 외부 팩은 아군 SD 좌우반전과 팩션 marker로 폴백합니다.

### 2.6 레거시 코어 호환 — 6개

경로: `res://assets/graphics/cores/`

- `emerald.svg` — 에메랄드
- `sapphire.svg` — 사파이어
- `amethyst.svg` — 아메지스트
- `jade.svg` — 제이드
- `obsidian.svg` — 옵시디언
- `core_test.png` — 코어 폴백 텍스처

이 6개는 대체 프로필·세이브·외부 팩 계약용입니다. 활성 선거 프로필의 안정 Core ID는 후보 문장과 후보 전투 SD를 표시하므로 보석 텍스처를 플레이어에게 노출하지 않습니다.

### 2.7 레거시 커서 호환·심복 — 5개

경로: `res://assets/graphics/cursors/`

- `silver.png`
- `iron.png` — 커서 폴백으로도 사용
- `gold.png`
- `platinum.png`
- `vanguard.svg`

### 2.8 일반 수비병력 전신 — 9개

경로: `res://assets/graphics/defenders/`

- `rapid.png` — 고블린 창병
- `area.png` — 해골 척탄병
- `pierce.png` — 오크 궁병
- `slow.png` — 심연의 기둥
- `knockback.png` — 죽음교 자동포교기계 KI-Ⅱ
- `execute.png` — 트롤 스나이퍼
- `mark.png` — 서큐버스 약화주술사
- `chain.png` — 마력 전도탑
- `rubber_golem.png` — 고무골렘

### 2.8-A 일반 수비병력 공격 포즈 — 9개

경로: `res://assets/graphics/defender_attacks/`

- `rapid.png`, `area.png`, `pierce.png`, `slow.png`, `knockback.png`, `execute.png`, `mark.png`, `chain.png`, `rubber_golem.png`

모두 1254×1254 투명 RGBA 원본이며 모바일 임포트는 512px로 제한합니다. 공격 확정 후 0.18초 동안 표시하고, 외부 콘셉트 팩에 같은 ID의 공격 이미지가 없으면 대기 포즈를 유지합니다.

### 2.9 일반 수비병력 얼굴 아이콘 — 9개

경로: `res://assets/graphics/defender_icons/`

- `rapid.png`
- `area.png`
- `pierce.png`
- `slow.png`
- `knockback.png`
- `execute.png`
- `mark.png`
- `chain.png`
- `rubber_golem.png`

### 2.10 타워·친위대 — 20개

경로: `res://assets/graphics/towers/`

- 일반 타워 호환 아트: `rapid.png`, `area.png`, `pierce.png`, `slow.png`, `knockback.png`, `execute.png`, `mark.png`, `chain.png`
- 활성 안정 ID 친위대: `emerald_guardian.png`, `sapphire_lance.png`, `amethyst_nova.png`, `jade_roulette.png`, `obsidian_verdict.png`, `obsidian_inquisitor.png`
- 레거시 후보명 호환 아트: `partason_royal_guard.png`, `jiane_fanatic_follower.png`, `kasuha_abyss_believer.png`, `irelai_resurrected_guard.png`
- `economy.png` — 에셋 카탈로그의 `towers/rubber_golem` 명시적 오버라이드
- `tower_test.png` — 타워 폴백 텍스처

일반 수비병력의 현재 기본 분류는 `defenders/{id}.png`입니다. `towers/`의 일반 타워 파일은 레거시·호환 경로로 보존합니다.

### 2.10-A 후보 전용 친위대 공격 포즈 — 6개

경로: `res://assets/graphics/tower_attacks/`

- `emerald_guardian.png`, `sapphire_lance.png`, `amethyst_nova.png`, `jade_roulette.png`, `obsidian_verdict.png`, `obsidian_inquisitor.png`

일반 수비병력 공격 포즈와 같은 1254×1254 RGBA·512px 모바일 임포트 계약을 사용합니다.

### 2.11 적·보스 — 34개

경로: `res://assets/graphics/enemies/`

- 일반·특수 적: `normal.png`, `fast.png`, `swarm.png`, `armored.png`, `splitter.png`, `support.png`, `shifter.png`, `cleanser.png`, `disruptor.png`, `ranged.png`, `shielded.png`, `regenerator.png`, `charger.png`, `phase.png`, `sapper.png`, `guardian.png`
- v0.15 활성 공용 적: `civilian_slime.png`, `goblin_raider.png`, `skeleton_raider.png`, `orc_shield.png`, `hound_light_infantry.png`, `wraith_raider.png`, `steel_golem.png`은 모두 v0.19 플랫 카툰 1254×1254 투명 RGBA 마스터와 512px 임포트 상한을 사용
- v0.15 팩션 대표 적: `partason_standard_shield.png`, `jiane_succubus_bewitcher.png`, `kasuha_abyss_creature.png`, `irelai_skeleton_cavalry.png`, `judaginda_cult_applicant.png`은 모두 v0.19 플랫 카툰 1254×1254 투명 RGBA 마스터와 512px 임포트 상한을 사용
- 수치·폴백 보스: `boss_5.png`, `boss_10.png`, `boss_15.png`, `final_boss.png`, `judgment_bell.png`은 모두 서로 다른 v0.19 플랫 카툰 1254×1254 투명 RGBA 마스터와 512px 임포트 상한을 사용한다. 선거 전투에서는 후보/심복 난입 SD가 본체를 대체하며 이 파일들은 비선거·도감·치환 실패 폴백이다.
- `enemy_test.png` — 진영·보스 문양이 없는 붉은 태엽 딱정벌레형 적 폴백, 1254×1254 투명 RGBA 마스터·512px 임포트 상한

승인된 그래픽 별칭:

- `enemies/zigzag` → `enemies/shifter`
- `enemies/taunter` → `enemies/disruptor`

### 2.12 발사체 — 8개

경로: `res://assets/graphics/projectiles/`

- `plasma_bolt.png` — 기본 플라즈마 발사체
- `artillery_shell.png` — 포격 발사체
- `frost_shard.png` — 냉기 파편
- `kinetic_slug.png` — 운동탄
- `election/goblin_javelin.svg` — 고블린 창병 투창
- `election/skeleton_grenade.svg` — 해골 척탄병 화염탄
- `election/royal_slash.svg` — 파르태손 왕실 친위대 검기
- `election/judgment_bolt.svg` — 주다긴다 죽음교 판결탄

선거 전용 4종은 `projectiles/{id}` 카탈로그 오버라이드와 `TowerData.projectile_texture_id`로 병종에 매핑합니다. 대체 프로필은 기존 플라즈마·포탄 역할 폴백을 유지합니다.

### 2.13 진영 문양 — 10개

경로: `res://assets/graphics/emblems/`

- `partason_crown.svg`
- `jiane_star.svg`
- `kasuha_abyss.svg`
- `irelai_spirit.svg`
- `judaginda_bell.svg`
- `partason_sword_shield.svg`
- `jiane_heart.svg`
- `kasuha_tentacle_eye.svg`
- `irelai_skull_aura.svg`
- `judaginda_scythe_blood.svg`

신규 5개는 활성 후보 카드·팩션 marker·대응 진영 표식에 함께 사용하고, 기존 5개는 외부 팩 호환 별칭으로 보존합니다.

### 2.14 후보·상태 전투 효과 — 5개

경로: `res://assets/graphics/effects/`

- `jiane_dream_barrier.png` — `몽마의 권위`가 핵 돌파 피해를 완화할 때 코어 돌파선에 표시되는 사파이어·마젠타 꿈 장벽
- `judaginda_verdict_seal.png` — 주다긴다 또는 친위대가 처형에 성공한 위치에 표시되는 흑요석·적색 판결 인장
- `status_effect_icon_atlas_v019.png` — 독·출혈·감전·화상, 제어·표식·중첩·강화·넉백 16종의 4×4 공유 아이콘 아틀라스
- `reaper_summon_v019.png` — 주다긴다 필살 공약 시 별도 현현하는 우향 사신 SD
- `death_vanguard_member_token_v019.png` — 죽음교 돌격부대 현재/최대 인원을 표시하는 후드 흉상 토큰

꿈 장벽과 판결 인장은 1254×1254 투명 RGBA이며 `effects/{id}` 규칙 경로로 해석됩니다. 전투에서는 108~140px 범위로 축소하고 `CombatEffectBudget.Priority.IMPORTANT` 예산을 통과한 경우에만 짧게 표시합니다. 신규 3종은 각각 1024/1024/512px RGBA 원본과 512/512/256px 임포트 상한을 사용하고, 단일 아틀라스·기존 오라/궤적·소형 스택 토큰으로 별도 파티클 노드를 만들지 않습니다.

### 2.15 공용 UI 의미 아이콘 — 1개

경로: `res://assets/graphics/ui/`

- `flat_effect_icon_atlas_v019.png` — 레벨업 카드·아티팩트 HUD·도감이 공유하는 5×5 플랫 인포그래픽 아이콘 아틀라스

1254×1254 투명 RGBA 원본을 모바일 임포트 1024px로 제한합니다. 위력·속도·범위·내구·제어, 병력·후보·심복·편대·전역, 독·화상·출혈·감전·표식, 경험치·경고·복귀·과열·유도·표식 증폭의 21개 활성 의미와 공용 예비 4개를 고정 셀에 배치하고, 런타임에서는 기존 의미 색상 토큰으로 틴트합니다.

## 3. 오디오 리소스

### 3.1 전투 — 8개

경로: `res://assets/audio/combat/`

- `hit_light.wav` — 가벼운 적중
- `hit_heavy.wav` — 강한 적중
- `core_hit.wav` — 코어 피격
- `tower_rapid.wav` — 속사 계열 공격
- `tower_blast.wav` — 폭발 계열 공격
- `tower_energy.wav` — 에너지 계열 공격
- `tower_saw.wav` — 톱날 계열 공격
- `tower_arcane.wav` — 비전 계열 공격

### 3.2 게임 진행 — 12개

경로: `res://assets/audio/gameplay/`

- `level_up.wav` — 레벨업
- `core_skill.wav` — 공통 핵 스킬 폴백
- `core_skill_emerald.wav`
- `core_skill_sapphire.wav`
- `core_skill_amethyst.wav`
- `core_skill_jade.wav`
- `core_skill_obsidian.wav`
- `candidate_skill_partason.wav` — 파르태손 필살 공약
- `candidate_skill_jiane.wav` — 지아느 필살 공약
- `candidate_skill_kasuha.wav` — 카스하 필살 공약
- `candidate_skill_irelai.wav` — 이레라이 필살 공약
- `candidate_skill_judaginda.wav` — 주다긴다 필살 공약

`core_skill_*` 파일명은 대체 프로필과 안정 역할 키 호환을 위해 유지합니다. 활성 선거 카탈로그는 `candidate_skill_*` 역할을 우선 사용합니다.

### 3.3 이벤트 — 4개

경로: `res://assets/audio/events/`

- `boss_warning.wav`
- `boss_spawn.wav`
- `victory.wav`
- `defeat.wav`

### 3.4 UI — 1개

경로: `res://assets/audio/ui/`

- `ui_click.wav`

## 4. 데이터 인스턴스

### 4.1 콘셉트·선거 — 10개

경로: `res://data/concepts/`

- `demon_election_vertical_slice.tres` — 현재 활성 기본 콘셉트 프로필
- `demon_election_assets.tres` — 현재 그래픽·오디오 카탈로그와 별칭
- `demon_election_texts.tres` — 선거 콘셉트 UI 텍스트
- `demon_election_campaign_v0_8.tres` — 후보·심복·진영 캠페인
- `demon_election_decrees_v0_8.tres` — 후보별 칙령 카탈로그
- `demon_election_governance_v0_8.tres` — 통치 반응 카탈로그
- `formation_defense.tres` — 선거 캠페인 없는 대체 프로필
- `formation_defense_assets.tres` — 대체 프로필 에셋 카탈로그
- `formation_defense_texts.tres` — 대체 프로필 텍스트
- `example_arcane_reskin.tres` — 콘셉트 교체 예시

### 4.2 스테이지·보상·메타 — 8개

- `res://data/stages/standard_20m.tres` — 실제 600초 표준 스테이지
- `res://data/meta/stage_rewards/standard_20m.tres` — 표준 스테이지 보상
- `res://data/meta/meta_progression_config.tres` — 메타 진행 설정
- `res://data/meta/codex_rules_v0_17.tres` — 용어·상태·전투 규칙 도감 10종
- `res://data/meta/defense_stat_catalog_v0_19.tres` — 일반 9병종의 POWER/SPEED/RANGE 27개 매핑
- `res://data/meta/overgrowth_catalog_v0_19.tres` — 후보 2종·심복 4종의 완료 후 반복 초과성장
- `res://data/meta/artifact_catalog_v0_19.tres` — 일반·후보·심복·친위대·상태 대상의 초기 아티팩트 18종
- `res://data/enemies/basic_enemy.tres` — 기본 적 Resource 예시·폴백 데이터

`standard_20m` 파일명은 호환을 위해 유지되지만 실제 스테이지 길이는 10분입니다.

### 4.3 튜토리얼 — 2개

- `res://data/tutorial/tutorial_v0_17.tres` — 파르태손·칸다와 6단계 학습 순서를 고정한 시나리오
- `res://data/tutorial/tutorial_60s_stage.tres` — 고블린 단일 풀과 55초 보스를 사용하는 60초 스테이지

## 5. 런타임 씬

- `res://scenes/main/main_menu.tscn` — 프로젝트 시작 씬
- `res://scenes/game/game.tscn` — 전투 게임 조정 씬
- `res://scenes/tutorial/tutorial_game.tscn` — 공용 전투 씬을 재사용하는 튜토리얼 진입 씬
- `res://scenes/battlefield/battlefield.tscn` — 전장
- `res://scenes/actors/core.tscn` — 코어
- `res://scenes/actors/target_cursor.tscn` — 목표지점·심복
- `res://scenes/actors/enemy.tscn` — 일반 적·보스 공용 액터
- `res://scenes/pickups/experience_orb.tscn` — 경험치 오브
- `res://scenes/ui/hud.tscn` — 전투 HUD·결과
- `res://scenes/ui/level_up_panel.tscn` — 레벨업·특화·편대 선택
- `res://scenes/ui/artifact_resolution_panel.tscn` — 가득 찬 6칸 아티팩트 교체·포기 모달
- `res://scenes/ui/pause_menu.tscn` — 일시정지·옵션
- `res://scenes/ui/components/choice_card.tscn` — 성장·편대 선택 공용 카드
- `res://scenes/ui/components/combat_result_overlay.tscn` — 전투 결과 공용 오버레이
- `res://scenes/ui/components/modal_shell.tscn` — 전투 모달 공용 shell
- `res://scenes/ui/components/page_shell.tscn` — 메타 페이지 공용 shell
- `res://scenes/ui/components/stat_row.tscn` — 유닛 상세 능력치 행
- `res://scenes/ui/components/tag_chip.tscn` — 분류·상태 공용 태그
- `res://scenes/ui/components/unit_info_popover.tscn` — 전투 유닛 정보 팝오버

테스트 계약에서만 사용하는 `res://scenes/ui/components/icon_chip.tscn`은 런타임 씬 집계와 Android 패키지에서 제외합니다.

## 6. Resource 스키마

### 6.1 콘셉트·카탈로그

- `game_concept_data.gd`, `game_asset_catalog_data.gd`, `game_text_catalog_data.gd`, `content_pack_data.gd`
- `election_campaign_data.gd`, `election_faction_data.gd`, `candidate_profile_data.gd`, `retainer_profile_data.gd`
- `candidate_decree_catalog_data.gd`, `candidate_decree_data.gd`
- `governance_reaction_catalog_data.gd`, `governance_reaction_data.gd`

### 6.2 전투 원형·상태

- `core_data.gd`, `cursor_data.gd`, `tower_data.gd`, `enemy_data.gd`, `stage_data.gd`, `spawn_phase_data.gd`, `spawn_packet_data.gd`
- `enemy_spawn_profile_data.gd`, `enemy_movement_profile_data.gd`, `enemy_acceleration_profile_data.gd`, `enemy_death_effect_profile_data.gd`, `enemy_decay_profile_data.gd`, `enemy_group_acceleration_profile_data.gd`, `enemy_formation_profile_data.gd`, `faction_prelude_data.gd`, `faction_spawn_packet_data.gd`
- `tower_formation_data.gd`, `formation_cell_data.gd`, `tower_branch_data.gd`, `specialization_branch_data.gd`
- `combat_pace.gd`, `control_resistance_profile_data.gd`, `charm_profile_data.gd`, `judgment_profile_data.gd`, `execution_profile_data.gd`
- `necromancy_profile_data.gd`, `retainer_reactivation_profile_data.gd`, `vanguard_stack_profile_data.gd`, `combo_attack_profile_data.gd`

### 6.3 성장·보상·메타

- `candidate_growth_data.gd`, `candidate_upgrade_data.gd`, `guard_growth_data.gd`, `guard_specialization_data.gd`, `retainer_growth_data.gd`
- `upgrade_data.gd`, `stage_reward_data.gd`, `stage_runtime_boss_plan.gd`, `tutorial_scenario_data.gd`
- `achievement_data.gd`, `meta_progression_config.gd`, `shop_product_data.gd`
- `codex_rule_entry_data.gd`, `codex_rule_catalog_data.gd`
- `defense_stat_axis_data.gd`, `defense_stat_mapping_data.gd`, `defense_stat_catalog_data.gd`
- `overgrowth_option_data.gd`, `overgrowth_catalog_data.gd`
- `artifact_effect_data.gd`, `artifact_data.gd`, `artifact_catalog_data.gd`
- `game_types.gd`

총 65개 스키마이며 위 파일은 모두 `res://resources/` 아래에 있습니다. v0.15 목표 적은 `EnemySpawnProfileData`로 비용·역할·해금·진영·그룹·희귀 쿨다운을 선언합니다. 공용 적은 선택적 이동·피격 가속·사망 효과를, 팩션 적은 자가 감소·동일 그룹 사망 가속·Tier 대열 프로필을 사용합니다. 표준 스테이지는 `FactionPreludeData`로 네 보스 슬롯의 예고 지속시간·Tier·팩션 비용 비율을, `FactionSpawnPacketData` 5개로 진영별 Tier 1~3 수량과 동반 공용 적을 정의합니다. 기존 6개 `SpawnPhaseData`의 Base/Bonus 예산·Alive Pressure 안에서 Prelude 비용을 대체하며 별도 예산 채널은 만들지 않습니다. `TutorialScenarioData`는 짧은 스테이지와 고정 후보·심복·편대·성장·적·보스 ID를 묶어 표준 런 정산과 분리하고, `CodexRuleEntryData`·`CodexRuleCatalogData`는 용어·상태·전투 규칙 항목과 resolver 키를 데이터화합니다. `DefenseStatAxisData`·`DefenseStatMappingData`·`DefenseStatCatalogData`는 일반 9병종의 세 능력축과 실제 modifier 경계를 소유하고, `OvergrowthOptionData`·`OvergrowthCatalogData`는 후보·심복 완료 후 반복 수치 계열을 선언합니다. `ArtifactEffectData`·`ArtifactData`·`ArtifactCatalogData`는 대상군·축/수정 키·값 방식·trade-off·적격 조건을 가진 초기 18종을 선언합니다.

## 7. 운영 메모

- 새 그래픽·오디오는 제작 버전이 아니라 런타임 역할 폴더에 배치합니다.
- 콘텐츠 ID와 파일명은 가능한 한 동일하게 유지합니다.
- 파일 이동·교체 시 `demon_election_assets.tres`, 승인 별칭, Godot 재임포트와 전체 스모크를 함께 확인합니다.
- 일반 병력 전신은 `defenders/`, 일반 공격 포즈는 `defender_attacks/`, 레벨업 얼굴은 `defender_icons/`, 후보 전용 친위대는 `towers/`, 친위대 공격 포즈는 `tower_attacks/`를 권위 경로로 사용합니다.
- 이 문서는 2026-07-29자 `TD_Survival_Resource_Inventory_2026-07-29.docx`를 대체하는 현재 Markdown 목록입니다.
