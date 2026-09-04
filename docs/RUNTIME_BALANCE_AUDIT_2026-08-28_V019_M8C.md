# GDD v0.19 M8C Base-only/normal 밸런스 수렴 감사

- 감사일: 2026-08-28
- 기준 GDD: `godot_formation_defense_gdd_v0_19.md`
- 감사 schema: v18
- 대상: `judgment_vanguard`, 평균 빌드/평균 숙련, Bonus disabled
- 시드: 1847, 42731, 99881
- 장기 감사: 600초, 3배속, 아티팩트 `disabled`와 `normal` 분리
- 판정: **비모바일 M8 기술·통합 밸런스 승인**

## 1. 해결한 문제

기존 M8 감사에서는 Base-only가 평균 452.88초·최종 보스 도전 1/3, normal이 평균 402.01초·최종 보스 도전 0/3이었다. 적 수나 경험치 예산은 유지됐지만 후반의 같은 Spawn group 다중 누수와 중간 보스 반복 돌파가 핵 체력을 지나치게 빠르게 소모했다. 단순 일반 돌파 피해 배율 또는 스폰 가중치만 조정한 실험은 두 실패 시드를 함께 수렴시키지 못했다.

이번 수렴은 적 수·XP·보스 체력·아티팩트 효과를 올리지 않고 돌파 책임 경계를 명확하게 하는 방식으로 적용했다.

- 일반 적 개별 돌파 피해: 원천 피해 × Challenge × 장비 배율의 30%.
- 같은 Spawn `group_id`의 일반 돌파 피해: 후보 최대 체력의 4%를 기본 상한으로 하되, 첫 단일 개체의 온전한 피해보다 낮추지 않음.
- 최종 보스 경쟁 시작 전 일반 적: 핵을 최대 체력 40% 아래로 낮출 수 없음. 중간/최종 보스 피해는 이 보호를 우회하며 최종 보스 출현과 함께 보호 종료.
- 중간 보스 첫 돌파: Tier 1/2/3에서 최대 체력의 15%/17.5%/20%. 첫 세 보스의 1회 돌파 합은 52.5%.
- 같은 중간 보스의 재돌파: 첫 돌파의 10%. 최종 보스는 첫/재돌파 모두 기존 22% 상한 유지.
- 고정 사선 전문 적 `skeleton_raider`: 6초 희귀 스폰 쿨다운. 표준 스테이지의 기본 가중치는 유지.

## 2. 장기 감사 결과

### 아티팩트 disabled

| 시드 | 경과(초) | 최종 보스 도전 | 보스 처치 | 레벨 | 처치 | 승리 | 종료 핵 |
|---:|---:|:---:|---:|---:|---:|:---:|---:|
| 1847 | 621.48 | 예 | 3 | 28 | 1,379 | 아니오 | 0.00 |
| 42731 | 621.02 | 예 | 3 | 29 | 1,612 | 아니오 | 0.00 |
| 99881 | 616.73 | 예 | 4 | 29 | 1,663 | 예 | 36.66 |

- 평균 경과 619.74초, 평균 레벨 28.67, 최종 보스 도전 3/3, 승리 1/3.
- 일반 돌파 피해는 시드별 190.27/185.85/149.73이었다.
- 최종전 전 핵 보호로 막은 피해는 864.63/369.45/185.37, 그룹 상한으로 막은 피해는 9.50/5.70/0.00이었다. 두 방지 원장은 중복 집계하지 않는다.
- 반복 중간 보스 돌파로 막은 피해는 0.00/61.20/0.00이었다.

### 아티팩트 normal

| 시드 | 경과(초) | 최종 보스 도전 | 보스 처치 | 레벨 | 처치 | 제안/획득 | 승리 |
|---:|---:|:---:|---:|---:|---:|:---:|:---:|
| 1847 | 605.77 | 예 | 3 | 28 | 1,172 | 2/2 | 아니오 |
| 42731 | 606.22 | 예 | 3 | 28 | 1,159 | 1/1 | 아니오 |
| 99881 | 604.45 | 예 | 3 | 28 | 1,334 | 1/1 | 아니오 |

- 평균 경과 605.48초, 평균 레벨 28.00, 최종 보스 도전 3/3, 승리 0/3.
- 완주당 평균 제안/획득/보유 수는 모두 1.33, 최대 보유 수는 2였다.
- 제안·선택 대상군은 `candidate`, `normal_defender`, `retainer`, `status` 각 1건이었다.
- 관측 출력 비례 효과 기여 추정 평균은 6,980.48이었다.
- 선택률은 4/4(100%)였고 포기·교체는 없었다. 이는 강제 선택 결론이 아니라 작은 표본의 한계로 분류한다.
- 일반 돌파 피해는 226.16/223.40/187.34, 최종전 전 핵 보호 피해는 1,518.94/1,682.70/1,121.06, 그룹 상한 피해는 5.70/28.90/3.80, 반복 중간 보스 피해는 30.60/91.80/57.38이었다.

## 3. 품질·성능·결정성

- disabled/normal 모두 `quality_gate_passed=true`, `balance_gate_passed=true`.
- 두 장기 감사 모두 타임아웃, 자식 프로세스 실패, 체크포인트 I/O 실패, 무효 블록 보드, 성능 예산 실패가 0건이었다.
- 평균 프레임은 disabled 5.559ms, normal 5.559ms였고 최악 프레임은 모두 16.667ms, 33ms 초과 비율은 0이었다.
- 모든 6개 장기 런의 제어 실효성 hard-counter 경고는 0건이었다.
- 60초 normal 1×/2×/3×는 모두 Lv.5·XP 168·75킬·핵 170으로 안정 지문이 일치했고 `speed_equivalence.passed=true`였다.
- Godot 4.7 헤드리스 에디터 파싱 종료 코드 0과 전체 `SMOKE TEST PASS`를 확인했다. 기존 종료 시 ObjectDB/리소스 잔존 경고는 있었으나 테스트 종료 코드는 0이었다.

## 4. 판정과 남은 위험

Base-only가 아티팩트 없이도 최종 보스에 3/3 도달하고 normal도 완주당 1~2회 제안 범위에서 3/3 도달하므로, M8의 저점 보장과 통합 밸런스 게이트를 승인한다. 아티팩트가 없어도 최종전을 시작할 수 있어 normal 고점이 필수 승리 조건이 되지 않았다.

다음 항목은 M8 승인 차단이 아니라 표본 확대 대상이다.

- 단일 후보·평균 정책·3시드 결과이므로 다른 후보와 약한/강한/꼬임 빌드로 일반화하지 않는다.
- normal 승리는 0/3이므로 아티팩트가 승률을 높인다고 결론 내리지 않는다.
- 4건의 제안이 모두 선택됐고 6칸 포화·포기·교체 표본이 없어 선택 비강제성과 인벤토리 포화 행동은 forced 계약 감사에 계속 의존한다.
- 밸런스 평가에는 STEP 저선택과 일부 특화 미선택/과선택 경고가 남아 있다. hard-counter 경고와는 별개다.
- 실제 모바일 입력·180Hz 3배속 비용·발열·Android/iOS export·캐릭터 음성 승인은 사용자 재개 지시 전까지 M9에서 보류한다.

## 5. 재현 명령

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847,42731,99881 --speeds=3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --artifact-mode=disabled --audit-seconds=600 --checkpoint=user://v019_m8c_disabled_checkpoint.json --result=user://v019_m8c_disabled_result.json

& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847,42731,99881 --speeds=3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --artifact-mode=normal --audit-seconds=600 --checkpoint=user://v019_m8c_normal_checkpoint.json --result=user://v019_m8c_normal_result.json

& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847 --speeds=1,2,3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --artifact-mode=normal --audit-seconds=60 --checkpoint=user://v019_m8c_speed_checkpoint.json --result=user://v019_m8c_speed_result.json
```
