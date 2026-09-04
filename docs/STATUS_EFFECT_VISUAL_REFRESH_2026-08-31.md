# 상태이상·넉백 시각 이펙트 갱신

- 날짜: 2026-08-31
- 상태: v0.19 아틀라스 갱신·자동 회귀·Forward Mobile 시각 검수·Android 디버그 export 완료
- 기준: `godot_formation_defense_gdd_v0_19.md`의 상태 색상, 색 외 실루엣 구분, 짧고 명확한 넉백 원칙

## 목표

기존 적 렌더링은 일부 상태를 색이 다른 호나 공전 점으로만 표시해 작은 화면에서 독·출혈·감전·화상의 형태가 충분히 구분되지 않았다. 1차 절차형 실루엣 갱신 뒤에도 단순 도형 인상이 남아, 이번 갱신은 v0.19 굵은 외곽선·2단 셀 셰이딩 아이콘을 4×4 공유 아틀라스로 적용한다. 방향과 움직임 정보는 경량 도형을 함께 사용하되 지속 파티클, 화면 전체 광원과 긴 궤적은 추가하지 않는다.

## 활성 시각 언어

| 상태 ID | 색 | 고유 형태 | 배치 |
|---|---|---|---|
| `poison` | 독녹 | 셀 셰이딩 기포 3개 | 본체 아래 상태열 |
| `bleed` | 진한 적색 | 광택이 있는 세로 피방울 | 본체 아래 상태열 |
| `shock` | 노랑 | 굵은 각진 번개 | 본체 아래 상태열 |
| `burn` | 주황 | 속불이 있는 갈라진 불꽃 | 본체 아래 상태열 |
| `slow` | 청색 | 추 아이콘 + 발밑 저항 파동 2겹 | 본체 하단 외곽 |
| `fear` | 탁한 보라 | 떨림선이 있는 눈 | 머리 위 제어 슬롯 |
| `charm` | 분홍 | 날개 하트 인장 | 머리 위 제어 슬롯 |
| `stun` | 노랑 | 5방향 셀 셰이딩 충격 별 | 머리 위 제어 슬롯 |
| `freeze` | 청백 | 굵은 6갈래 눈결정 | 머리 위 제어 슬롯 |
| `mark` | 자주 | 눈 조준 아이콘 + 네 모서리 브래킷 | 본체 모서리 |
| `sentence` | 적색 | 최대 3개 검 판결 인장 | 본체 왼쪽 |
| `pierce_mark` | 금속 금색 | 갈라진 방패 | 본체 왼쪽 |
| `frost_stack` | 청백 | 최대 3개 얼음 파편 | 본체 오른쪽 |
| `haste` | 녹색 | 이중 전진 화살 | 본체 오른쪽 |
| `fortify` | 강철 청색 | 방패 아이콘 + 양쪽 브래킷 | 본체 외곽 |
| `knockback` | 백금색 | 쐐기 아이콘 + 후방 잔상선과 전방 압축선 | 0.24초 이내 일시 표시 |

## 복잡도·성능 예산

- 모든 적이 512px로 임포트된 단일 4×4 Texture2D 아틀라스를 공유한다. 상태마다 별도 Texture2D, Particle, Shader, 자식 Node는 만들지 않는다.
- 독·출혈·감전·화상은 고정된 하단 상태열에 상태 종류당 아이콘 하나만 표시한다. 중첩 정보는 최대 3개의 작은 점으로 제한한다.
- 제어 상태는 머리 위 전용 슬롯을 사용하고, 표식·판결·빙결 중첩·강화는 서로 다른 외곽 위치를 사용해 같은 반경에 공전시키지 않는다.
- 상태 적용/재적용 때만 약 0.21초 동안 해당 실루엣을 16~18% 확대한다. 지속 상태는 정적인 형태를 유지하며 표식만 기존의 미세한 호흡을 보존한다.
- 넉백은 기존 캐릭터 반투명 잔상을 유지하되, 3개의 짧은 후방선과 하나의 전방 압축선만 사용한다. 전체 화면 플래시나 원형 충격파를 추가하지 않는다.
- 40개 적에게 단일·복합 상태를 혼합하고 한 적에게 공통 4상태를 모두 적용한 밀도 표본으로 캐릭터·체력바·행 경계를 가리지 않는지 확인했다.

## 구현 경계

- `scripts/effects/enemy_status_effect_renderer.gd`: 4×4 셀 매핑, 팔레트, 안정 순서, 복합 상태 배치와 둔화·표식·강화·넉백 보조 도형
- `assets/graphics/effects/status_effect_icon_atlas_v019.png`: 16종 상태·일시 효과의 활성 공유 아틀라스
- `scripts/actors/enemy.gd`: 실제 상태 적용 성공 시 짧은 펄스 시작, 상태 해제/만료 시 즉시 redraw, 렌더러 호출
- `scripts/combat/control_attack_execution_service.gd`: 직접 기록되는 `frost_stack`도 같은 시각 알림 경로 사용
- `tests/contracts/enemy_status_visual_contract_test.gd`: 15개 지속 상태와 넉백의 고유 실루엣, 팔레트, 중복 제거, 실제 적용·정화·넉백 연결 검사
- `tests/status_effect_visual_review.tscn`: 16개 개별 표본과 40개 적 밀도 표본 생성

## 검증

- Godot 4.7 Forward Mobile 개별 검수: `tests/visual_reviews/status_effect_visual_review.png`
- Godot 4.7 Forward Mobile 밀도 검수: `tests/visual_reviews/status_effect_density_review.png`
- 전체 7단계 품질 게이트: 7/7 통과
- 보고서: `C:\Users\USER\AppData\Local\Temp\td-survival-headless-quality-gate\20260831_220408_189_25520\summary.json`
- Android arm64 디버그 APK: 68,970,280 bytes(65.78MiB), zipalign·v2/v3 서명·신규 아틀라스 포함 확인
- SHA-256: `C66A45FFF50819F8229B88B659CE6DFF19D189684BCFBDF1C40FA9995E3464C7`

실제 Android 기기의 작은 물리 화면, 1×·3× 속도, 저사양 GPU에서의 장시간 판독성·발열은 승인 기기에서 추가 확인해야 한다.
