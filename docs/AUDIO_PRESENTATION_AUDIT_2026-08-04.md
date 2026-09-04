# 전투 사운드 프레젠테이션 감사 — 2026-08-04

## 승인 범위

- 원본 WAV: mono, 44.1kHz, 16-bit PCM
- Godot 런타임: mono, 44.1kHz, QOA 모바일 압축
- 재생 동시성: 기존 16보이스 풀 유지
- 반복 공격 제한: 핵·커서·타워 타격이 공유하는 45ms 슬롯 유지
- 안전 폴백: 알 수 없는 핵은 `core_skill`, 알 수 없는 타워 행동은 `hit_light`

## 핵 액티브 음색

| 안정 ID | 파일 | 길이 | 의도 |
|---|---|---:|---|
| emerald | `core_skill_emerald.wav` | 1.00초 | 상승 충전음 뒤 짧고 단단한 프리즘 포격 |
| sapphire | `core_skill_sapphire.wav` | 1.08초 | 고역 스윕과 유리성 공명으로 전장 전체 효과 강조 |
| amethyst | `core_skill_amethyst.wav` | 1.06초 | 낮은 지속음과 3연 펄스로 억제벽의 중량 표현 |
| jade | `core_skill_jade.wav` | 1.18초 | 하강 음계와 저역 잔향으로 사령 출격 표현 |
| obsidian | `core_skill_obsidian.wav` | 1.20초 | 종소리 배음과 저역 충격으로 최종 선고 표현 |

## 타워 공격군 음색

| 역할 | 적용 행동 | 파일 | 길이 |
|---|---|---|---:|
| 속사 | `rapid`, `unique_single` | `tower_rapid.wav` | 0.11초 |
| 폭발 | `area`, `unique_radial` | `tower_blast.wav` | 0.34초 |
| 에너지 | `pierce`, `unique_pierce`, `chain` | `tower_energy.wav` | 0.22초 |
| 톱날 | `knockback` | `tower_saw.wav` | 0.24초 |
| 비전/제어 | `slow`, `execute`, `mark`, `unique_random` | `tower_arcane.wav` | 0.29초 |

## 자동 검증

- 기본 Formation Defense와 마계 선거 프로필 모두 전용 사운드 10개를 필수로 소유합니다.
- 10개 리소스와 실제 파형 해시는 모두 서로 달라야 합니다.
- 핵 5종과 지원되는 타워 행동 13종의 라우팅을 계약으로 고정합니다.
- 원본 생성은 `tools/generate_sfx.py` 한 곳에서 결정적으로 재현합니다.
