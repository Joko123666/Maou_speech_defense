# 적 리소스 아트 방침 재점검 — 2026-08-31

## 결론

현재 활성 적 리소스 17 ID는 v0.19 아트 방침에 맞는 전용 이미지로 승인할 수 있다. 다만 비활성 구형 적 16파일은 외부 팩 호환 결정을 마친 뒤 정리해야 한다.

- 활성 일반 적 7종과 팩션 적 5종은 파일 연결·투명도·방향·팩션 구분은 정상이다.
- 최초 감사에서 12종 전체가 갱신된 수비측 SD보다 사실적 비례, 다단 명암, 재질 질감과 내부 선 정보가 많다고 판정했다. 이후 P0 5종, P1 4종, P2 3종을 모두 갱신했으며 현재 일반·팩션 적 12종은 전부 승인 상태다.
- 기본 보스 4종과 별칭으로만 존재하던 `judgment_bell`도 모두 전용 플랫 카툰 자산으로 갱신했다. 도감·폴백에서도 구형 보스 렌더나 공유 정체성이 노출되지 않는다.
- 후보·심복 난입 SD 10종은 좌향, 역할별 장식 등급, 투명 마스터, 안전 여백과 512px 런타임 상한을 지켜 현재 승인 상태를 유지할 수 있다.
- 기존 M4 적 감사는 방향과 외곽선만 검사했다. 이번에 문제가 된 `플랫 컬러링`, `그림자·질감 최소화`, `작은 크기에서의 세부도`, `마스터 안전 여백`은 당시 승인 범위가 아니었다.

공식 난입의 역할 재대조 결과는 `docs/OFFICIAL_INTRUSION_BOSS_ART_REGENERATION_PLAN_2026-09-03.md`가 보완한다. 기본 보스 5 PNG는 전투 수치·비선거·도감·치환 실패 폴백이고, 선거 전투의 주 이미지는 후보/심복 난입 SD다. 선택 심복 중복 시에는 수치 ID와 표시 인물 ID를 먼저 분리한 뒤 진영별 대체 간부 5종을 추가한다.

## P0 개선 적용 결과

감사 직후 최우선 5종과 활성 폴백 1종을 v0.19 스타일로 재제작해 활성 경로에 적용했다.

- 적용 ID: `wraith_raider`, `steel_golem`, `hound_light_infantry`, `kasuha_abyss_creature`, `irelai_skeleton_cavalry`, `enemy_test`
- 공통 규격: 1254×1254 실제 RGBA 투명 마스터, 네 변 7% 이상 안전 여백, 런타임 임포트 상한 512px
- 공통 표현: 중간 굵기 딥 네이비 외곽선, 3~5개 주요 색면, 2단 셀 셰이딩, 제한된 하이라이트, 좌향 또는 중량형 정면-좌향 예외
- 검수: 기존/신규와 96·64·48px를 `tests/visual_reviews/enemy_style_refresh_p0.png`에서 비교하고, Forward Mobile의 `enemy_roster.png`와 `demon_election_faction_showcase.png`에서 활성 전장 표시를 확인했다.
- 회귀 방지: `data/art/character_style_refresh_manifest_v1.json`과 `V019CharacterStyleRefreshContractTest`가 경로·해시·알파·안전 여백·512px import를 검사한다.

따라서 아래 P0 표의 5종과 `enemy_test`는 현재 승인 상태다. P1 4종, P2 3종과 보스 5종도 다음 적용 결과로 대체됐다.

## P1 개선 적용 결과

2026-09-03에 다음 4종을 같은 v0.19 적측 스타일 패스로 재제작해 활성 경로에 적용했다.

- 적용 ID: `goblin_raider`, `skeleton_raider`, `orc_shield`, `partason_standard_shield`
- 제작: 내장 ImageGen의 정체성 보존/스타일 전환 방식으로 종족·역할·대표 장비·팩션색·좌향 실루엣을 유지하고, SD 플랫 카툰 비례·중간 딥 네이비 외곽선·3~5개 색면·2단 셀 셰이딩으로 단순화했다.
- 규격: 1254×1254 실제 RGBA 마스터, 네 변 최소 100px(7.97%) 안전 여백, 활성 임포트 상한 512px
- 검수: `tests/visual_reviews/enemy_style_refresh_p1.png`에서 240/96/64/48px 역할 판독성을 확인하고 Forward Mobile의 적 도감·팩션 쇼케이스·전장 스냅샷에서 잘림과 겹침이 없음을 확인했다.
- 회귀 방지: `enemy_p1_style_refresh` manifest와 `V019CharacterStyleRefreshContractTest`가 스테이징/활성 경로, SHA-256, 실제 알파, 안전 여백, 방향 단서, 512px 임포트를 검사한다.
- 복구: 교체 전 활성 파일은 저장소 밖 `C:\Users\USER\.codex\backups\td-survival\enemy-art-p1\20260903_142432`에 보존했다.

이 단계에서 활성 일반·팩션 적은 P0 5종과 P1 4종, 합계 9/12가 승인 상태가 됐다. 이후 P2 3종도 아래와 같이 완료했다.

## P2 개선 적용 결과

2026-09-03에 남은 일반·팩션 적 3종을 같은 v0.19 적측 스타일 패스로 재제작해 활성 경로에 적용했다.

- 적용 ID: `civilian_slime`, `jiane_succubus_bewitcher`, `judaginda_cult_applicant`
- 제작: 내장 ImageGen의 정체성 보존·스타일 전환·정밀 배경 교체 방식으로 슬라임 전단/주머니, 지아느 하트 부채/한 쌍의 날개, 주다긴다 붉은 후드/작은 낫을 유지하고 SD 플랫 카툰 비례와 3~5개 색면으로 단순화했다.
- 규격: 1254×1254 실제 RGBA 마스터, 네 변 최소 100px(7.97%) 안전 여백, 활성 임포트 상한 512px
- 검수: `tests/visual_reviews/enemy_style_refresh_p2.png`에서 220/96/64/48px와 36px 8기 밀도를 확인하고 Forward Mobile의 적 도감·팩션 쇼케이스·전장 스냅샷에서 역할 판독과 겹침을 확인했다.
- 방향: 세 자산 모두 원본부터 좌향이므로 `judaginda_cult_applicant`에만 적용하던 런타임 좌우반전 보정을 제거했다.
- 회귀 방지: `enemy_p2_style_refresh` manifest와 `V019CharacterStyleRefreshContractTest`가 스테이징/활성 경로, SHA-256, 실제 알파, 안전 여백, 방향 단서, 512px 임포트와 보정 제거를 검사한다.
- 복구: 교체 전 활성 파일은 저장소 밖 `C:\Users\USER\.codex\backups\td-survival\enemy-art-p2\20260903_151046`에 보존했다.

이로써 활성 일반·팩션 적 12/12가 승인 상태가 됐고, 후속 단계에서 보스 5종도 완료했다.

## 보스 개선 적용 결과

2026-09-03에 기본 보스 4종을 역할 정체성을 유지한 플랫 카툰 SD로 다시 제작하고, `judgment_bell`에 독립된 종지기 이미지를 제공했다.

- 적용 ID: `boss_5`, `boss_10`, `boss_15`, `final_boss`, `judgment_bell`
- 제작: 내장 ImageGen의 정체성 보존·스타일 전환·정밀 편집 방식으로 선봉장의 주황 반응로/쌍집게, 방해 책임자의 보라 외눈/4개 코일, 근위대장의 금색 관/4개 소환 드론, 최종 후보의 붉은 터빈 눈/6개 칼날 다리, 종지기의 거대 종 몸체/망치를 고정했다. 사실적 금속 질감과 미세 패널 선은 줄였다.
- 규격: 1254×1254 실제 RGBA 마스터, 네 변 7% 이상 안전 여백, 활성 임포트 상한 512px
- 분리: `judgment_bell.tres`가 `judgment_bell.png`를 직접 사용하며 두 활성 카탈로그에서 `enemies/judgment_bell -> enemies/final_boss` 별칭을 제거했다.
- 검수: `tests/visual_reviews/enemy_boss_style_refresh.png`에서 220/96/64/48px 색·실루엣·핵심 소품을 확인하고, Forward Mobile 85개를 다시 생성해 보스 경고·팩션 쇼케이스·전장·보스 로스터 배치를 확인했다.
- 회귀 방지: `enemy_boss_style_refresh` manifest와 `V019CharacterStyleRefreshContractTest`가 스테이징/활성 SHA-256, 실제 알파, 안전 여백, 512px 임포트, 5개 고유 정체성, 전용 데이터 연결과 별칭 제거를 검사한다.
- 복구: 교체 전 보스 4파일은 저장소 밖 `C:\Users\USER\.codex\backups\td-survival\enemy-boss-art\20260903_153908`에 보존했다.

이 단계로 활성 일반 7종·팩션 적 5종·보스 5종, 합계 17/17 ID가 전용 승인 아트를 사용한다.

## 판정 기준

`godot_formation_defense_gdd_v0_19.md`의 다음 계약을 사용했다.

- 두꺼운/중간 암색 외곽선, 데포르메, 플랫 컬러링, 밝은 카툰 과장
- 정교한 사실 묘사보다 실루엣 우선
- 그림자와 질감을 최소화하고 색면 분할 우선
- 적은 기본 좌향, 아군보다 상대적으로 얇은 외곽선
- 일반 적은 중립색, 팩션 적은 대표색과 문양으로 구분
- 모바일 48/64/96px에서 역할과 방향을 즉시 판독
- 1254×1254 RGBA 투명 마스터, 일반 7% 이상·긴 무기 4% 이상 안전 여백, 런타임 512px 상한

## 실제 활성 범위

기본 콘셉트 프로필은 외부 `ContentPackData` 없이 내장 `DataRegistry`를 사용한다.

- 일반 적 7종: `civilian_slime`, `goblin_raider`, `skeleton_raider`, `orc_shield`, `hound_light_infantry`, `wraith_raider`, `steel_golem`
- 팩션 적 5종: `partason_standard_shield`, `jiane_succubus_bewitcher`, `kasuha_abyss_creature`, `irelai_skeleton_cavalry`, `judaginda_cult_applicant`
- 보스 5 ID: `boss_5`, `boss_10`, `boss_15`, `final_boss`, `judgment_bell`
- 보스 5 ID는 각각 같은 이름의 전용 PNG를 사용하며 `judgment_bell` 별칭은 제거됐다.
- 선거 전투의 보스 본체는 비최종 슬롯에서 심복 난입 SD, 최종 슬롯에서 후보 난입 SD로 대체된다.

## 활성 일반·팩션 적 판정

### P0 — 우선 갱신

| ID | 판정 근거 |
|---|---|
| `wraith_raider` | 다중 반투명 불꽃·연기·내부 발광이 본체 실루엣보다 강하고 48px에서 하나의 보라색 잡음 덩어리로 합쳐진다. |
| `steel_golem` | 금속 판재, 볼트, 반사광과 다단 명암이 과다하다. 갱신 수비병력의 굵은 색면보다 사실적 렌더에 가깝다. |
| `kasuha_abyss_creature` | 피부/갑각 질감, 균열과 발광이 많고 큰 체구가 캔버스 가장자리까지 차지한다. 카스하 색은 명확하지만 팩션 적 장식 등급 1.1을 초과한다. |
| `irelai_skeleton_cavalry` | 기수·말·뼈·갑옷·영혼 불꽃이 동시에 경쟁한다. 3~6기 대열로 출현하므로 단일 이미지보다 전장 밀도 문제가 크게 증폭된다. |
| `hound_light_infantry` | 칼날형 사지, 붉은 갈기와 다수의 가는 돌출부가 겹쳐 48px에서 역할보다 날카로운 잔상이 먼저 읽힌다. |

### P1 — 같은 갱신 묶음에서 재제작

| ID | 판정 근거 |
|---|---|
| `goblin_raider` | 역할과 좌향은 선명하지만 가죽·금속·천 재질, 인체 비례와 소품 수가 수비측 SD보다 사실적이다. |
| `skeleton_raider` | 가는 사실 비례와 어두운 천 주름 때문에 48px에서 뼈/무기보다 어두운 외곽만 남는다. |
| `orc_shield` | 방패 역할은 읽히지만 목재 결, 금속 반사와 갑옷 음영이 과하고 상단 여백이 거의 없다. |
| `partason_standard_shield` | 녹색·금색 팩션 구분과 방패는 합격이나 성인 비례, 갑옷 반사와 작은 문양이 일반 팩션 적 등급보다 복잡하다. |

### P2 — 정체성은 유지하고 단순화

| ID | 판정 근거 |
|---|---|
| `civilian_slime` | 가장 카툰에 가깝고 안전 여백도 통과한다. 다만 반투명 방울·내부 광택과 소품 질감을 2단 명암으로 줄여야 한다. |
| `jiane_succubus_bewitcher` | 마젠타 팩션색과 날개 실루엣은 명확하다. 성인형 세부 비례와 다중 의상 그라데이션을 SD 기준으로 단순화할 필요가 있다. |
| `judaginda_cult_applicant` | 적/팩션 구분과 붉은 후드는 명확했지만 구형 원본은 런타임 좌향 보정이 필요했다. 천 주름·벨트·팔다리 비례를 줄인 직접 좌향 자산으로 대체할 수 있는 정체성이었다. |

P0·P1·P2는 후속 제작·적용·자동 계약을 거쳐 모두 승인 상태로 전환됐다. 위 표는 최초 감사 당시의 우선순위 근거로 보존한다.

## 보스와 공식 난입

### 기본 보스 원본

최초 감사에서 `boss_5`, `boss_10`, `boss_15`, `final_boss`는 고밀도 기계 갑각·발광 홈·금속 재질 계열이어서 v0.19와 맞지 않았고, `judgment_bell`은 전용 이미지가 없었다. 현재는 다섯 보스 모두 전용 플랫 카툰 자산으로 대체됐다.

- 기본 선거 전투에서는 후보/심복 난입 SD가 본체를 대체하므로 즉시 전투 가시성 위험은 낮다.
- 도감이 사용하는 `EnemyData.texture`도 새 활성 파일을 직접 가리킨다.
- `judgment_bell`은 붉은 후드·검은 종 몸체·단일 타격 망치로 `final_boss`의 거미형 실루엣과 분리된다.
- 모든 보스 마스터가 네 변 7% 이상 투명 여백과 512px 임포트 상한을 지킨다.

따라서 기본 보스 도감/폴백 원본 재제작과 별칭 분리는 완료 상태다.

### 후보·심복 난입 SD 10종

현재 승인 유지가 가능하다.

- 모두 1254×1254 RGBA이며 실측 최소 안전 여백은 8.1% 이상이다.
- 모두 임포트 `process/size_limit=512`를 사용한다.
- 좌향 공격 자세, 적대 표정/응시, 중간 외곽선, 팩션별 적대 효과가 분리된다.
- 48px에서는 일부 내부 효과가 조밀하지만 실제 보스 렌더 크기는 반지름 계약상 약 158~224px이고 공식 난입 장식 등급 1.65가 허용된다.
- 카스하/저므조므의 촉수, 이레라이/주그디에드의 영혼 불꽃, 죽음교 돌격대의 다인 구도는 후속 실기기에서만 추가 관찰한다.

## 파일 규격과 잔존 리소스

### 활성 적 원본 16파일 — 최초 감사 시점

- 일반·팩션 적 12파일: 512×512 RGBA
- 기본 보스 4파일: 627×627 RGBA
- 같은 ID의 별도 1254px 마스터는 저장소에 없다.
- 16파일 모두 임포트 상한이 0이다. 512px 파일은 결과적으로 목표 크기지만 627px 보스는 런타임 512px 계약을 초과한다.
- 선호 7% 안전 여백을 네 변 모두 만족하는 파일은 `civilian_slime` 1종뿐이다. 15/16은 한 변 이상 미달하고 `boss_15` 상단과 `final_boss` 좌측은 투명 여백이 0이다.
- 모두 실제 RGBA 투명 이미지이며 배경이 구워진 파일은 없었다.

P0·P1·P2와 보스 개선 적용 뒤에는 일반/팩션 12종과 기본 보스 4종 전부가 1254×1254 RGBA·7% 이상 여백·512px 상한으로 전환됐다. 새 `judgment_bell.png`도 같은 규격을 사용한다.

### 구형·폴백 파일

`normal`, `fast`, `swarm`, `armored`, `splitter`, `support`, `shifter`, `cleanser`, `disruptor`, `ranged`, `shielded`, `regenerator`, `charger`, `phase`, `sapper`, `guardian`은 현재 내장 자동 스폰 카탈로그에서 퇴역했지만 `assets/graphics/enemies/`에 남아 있다. 전부 구형 기계형 고밀도 렌더 계열이다.

- `shifter`, `disruptor`는 각각 `zigzag`, `taunter` 승인 별칭의 대상이다.
- `enemy_test.png`는 적 누락 시 쓰는 활성 폴백이며, P0에서 진영·보스 문양이 없는 붉은 태엽 딱정벌레형 1254×1254 RGBA·512px 상한 자산으로 교체했다.
- 나머지는 현재 내장 전투에는 나타나지 않지만 외부 팩의 동일 ID나 직접 경로 사용 시 다시 노출될 수 있다.

## 권장 개선 순서

1. 적 전용 스타일 토큰과 검수 장면을 만든다. 갱신 수비병력과 같은 화면에서 96/64/48px, 단일/12기/40기 밀도를 비교한다.
2. **완료:** P0 5종과 `enemy_test` 폴백을 실루엣·대표 장비·팩션색을 유지한 3~5개 주요 색면, 2단 명암, 제한된 하이라이트로 재제작했다.
3. **P1·P2 완료:** P1 4종과 `civilian_slime`, `jiane_succubus_bewitcher`, `judaginda_cult_applicant`를 같은 제작 패스로 갱신했다. 팩션 적 장식량은 일반 적의 약 1.1배를 넘기지 않는다.
4. **완료:** 기본 보스 5 ID에 전용 도감/폴백 이미지를 제공하고 `judgment_bell` 별칭을 제거했다.
5. **완료:** 시각 승인 뒤 활성 경로를 전환하고 1254px 마스터·512px 임포트·7% 여백·좌향/정면 예외를 계약으로 고정했다.
6. 구형 16파일은 별칭·외부 팩 호환 결정을 끝낸 뒤 격리 또는 삭제한다.

## 이번 작업에서 수행한 검증

- GDD v0.19 아트 방침과 캐릭터 갱신 manifest 대조
- `DataRegistry`, 기본 콘셉트 프로필, 자산 카탈로그, 캠페인 보스 이미지 대체 경로 대조
- 활성 일반·팩션 적 12종과 기본 보스 4파일을 180/96/64/48px로 직접 비교
- 후보·심복 난입 10종의 기존 96/64/48px 검수 캡처 재확인
- 모든 활성 파일의 크기·RGBA·임포트 상한·알파 안전 여백 실측
- 구형 16종과 활성 폴백 1종의 시각 및 참조 경계 확인
- 직전 전체 품질 게이트 `20260831_195845_831_25932/summary.json`의 7/7 통과 재확인
- P0 신규 계약을 포함한 스모크 `SMOKE TEST PASS`
- Forward Mobile UI 스냅샷 85개 재생성, `enemy_roster.png`·`demon_election_faction_showcase.png` 직접 검수
- 최종 전체 품질 게이트 7/7 통과: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_211444_375_23780\summary.json`
- Android arm64 디버그 APK 68,662,325 bytes(65.48MiB), SHA-256 `654ADEC51E343E25A844371A80CA851AE7476DFF53FDF08E433B4ADB41AD686B`; zipalign·v2/v3 서명·신규 6종 포함·staging/tests/tools/reference 0항목 확인
- P1 4종 검수 캡처 `tests/visual_reviews/enemy_style_refresh_p1.png`를 생성하고 240/96/64/48px에서 종족·역할·방향·팩션 구분을 직접 확인
- P1 계약 포함 스모크 `SMOKE TEST PASS`, Forward Mobile UI 스냅샷 85개 생성 종료 코드 0 및 `enemy_roster.png`·`demon_election_faction_showcase.png`·`demon_election_vertical_slice.png` 직접 검수
- P1 적용 뒤 최종 전체 품질 게이트 7/7 통과: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260903_142857_244_20668\summary.json`
- Android arm64 디버그 APK `TD_survival_v019_enemy_p1_style_debug.apk` 69,140,494 bytes, SHA-256 `05BF299B3F0660C2E7C7C6F97EC36AE69B833BCDD0C627A66603DB65E4302517`; package `com.example.td_survival`, versionName `0.03`, min/target SDK 24/36, zipalign·v2/v3 서명 유효, P1 활성 4종 CTEX/import 포함, staging/tests/tools/reference/data/art 0항목 확인
- P2 3종 검수 캡처 `tests/visual_reviews/enemy_style_refresh_p2.png`를 생성하고 220/96/64/48px와 36px 8기 밀도에서 역할·방향·팩션 구분을 직접 확인
- P2 계약 포함 스모크 `SMOKE TEST PASS`, Forward Mobile UI 스냅샷 85개 생성 종료 코드 0 및 `enemy_roster.png`·`demon_election_faction_showcase.png`·`demon_election_vertical_slice.png` 직접 검수
- P2 적용 뒤 최종 전체 품질 게이트 7/7 통과: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260903_151549_568_21660\summary.json`
- Android arm64 디버그 APK `TD_survival_v019_enemy_p2_style_debug.apk` 68,894,734 bytes, SHA-256 `1AFB1624E9A3753FCE8AA316074EEB7D6FD9E8BAD4279890642B8128360DD3AD`; package `com.example.td_survival`, versionName `0.03`, min/target SDK 24/36, zipalign·v2/v3 서명 유효, P2 활성 3종 CTEX/import 포함, staging/tests/tools/reference/data/art 0항목 확인
- 보스 5종 검수 캡처 `tests/visual_reviews/enemy_boss_style_refresh.png`를 생성하고 220/96/64/48px에서 색·실루엣·핵심 소품과 실제 투명 여백을 직접 확인
- 보스 계약 포함 스모크 `SMOKE TEST PASS`, Forward Mobile UI 스냅샷 85개 생성 종료 코드 0 및 `boss_roster.png`·`demon_election_boss_warning.png`·`demon_election_faction_showcase.png`·`demon_election_vertical_slice.png` 직접 검수
- 보스 적용 뒤 최종 전체 품질 게이트 7/7 통과: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260903_154531_494_11236\summary.json`
- Android arm64 디버그 APK `TD_survival_v019_enemy_boss_style_debug.apk` 68,284,655 bytes, SHA-256 `133D2BFDC99D6ED175C1037D2DCC433D26A2121C4F246817B425B768DF82455B`; package `com.example.td_survival`, versionName `0.03`, min/target SDK 24/36, zipalign·v2/v3 서명 유효, 보스 5종 CTEX/import 포함, staging/tests/tools/reference/data/art 0항목 확인

최초 감사 단계에서는 게임 코드와 이미지 리소스를 수정하지 않았으며, 이후 P0·P1·P2·보스 개선 단계에서 활성 일반·팩션 적 12종, 보스 5종과 폴백 1종, 회귀 계약·검수 산출물을 추가했다. 현재 남은 아트 정리 범위는 비활성 구형 적 16파일의 호환 정책 결정이다.
