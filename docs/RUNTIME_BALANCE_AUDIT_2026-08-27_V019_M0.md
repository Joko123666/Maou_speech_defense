# GDD v0.19 M0 무아티팩트 기준선 감사

- 실행일: 2026-08-27 (Asia/Seoul)
- 엔진: Godot 4.7 stable, headless
- 감사 스키마: v17
- 빌드 정책 revision: 2
- Run RNG revision: 2
- 아티팩트 모드: `disabled`
- 원본 결과: `user://v019_m0_speed_result.json`, `user://v019_m0_no_artifact_result.json`
- 체크포인트: `user://v019_m0_speed_checkpoint.json`, `user://v019_m0_no_artifact_checkpoint.json`

## 목적

v0.19 아티팩트와 POWER/SPEED/RANGE 이관 전에 현재 전투를 대조군으로 고정한다. 이 보고서는 무아티팩트 상태의 승인서가 아니라 재현 가능한 출발점이며, 기술 품질과 장기 밸런스 판정을 분리한다.

## 실행 조건

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . res://tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847 --speeds=1,2,3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --audit-seconds=60 --checkpoint=user://v019_m0_speed_checkpoint.json --result=user://v019_m0_speed_result.json

& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . res://tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847,42731,99881 --speeds=3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --audit-seconds=600 --checkpoint=user://v019_m0_no_artifact_checkpoint.json --result=user://v019_m0_no_artifact_result.json
```

`Bonus disabled`를 사용했으므로 세 장기 런의 Bonus Spawn 수와 Bonus XP 비율은 모두 0이다. 현재 프로젝트에는 아티팩트 런타임이 없으며, schema v17의 `artifact_mode=disabled`가 이를 명시적으로 보존한다.

## 60초 속도 등가성

| 항목 | 결과 |
|---|---:|
| 실행 수 | 3 (1×/2×/3×) |
| 품질 게이트 | 통과 |
| 속도 지문 불일치 | 0 |
| 공통 레벨 | 4 |
| 공통 XP | 149.1 |
| 공통 처치 | 76 |
| Bonus XP 비율 | 0% |

레벨, XP, 처치, 스폰, 보드, 정책 행동과 성장 지문이 세 속도에서 일치했다.

## 600초 3시드 무아티팩트 대조군

| 시드 | 생존 시간 | 완료율 | 레벨 | XP | 처치 | Base XP 회수율 | 최종 보스 도전 |
|---:|---:|---:|---:|---:|---:|---:|---|
| 1847 | 325.18초 | 54.2% | 19 | 1,502.55 | 610 | 62% | 아니요 |
| 42731 | 326.67초 | 54.4% | 19 | 1,481.55 | 634 | 60% | 아니요 |
| 99881 | 472.42초 | 78.7% | 28 | 4,721.85 | 1,215 | 84% | 아니요 |
| 평균 | 374.76초 | 62.46% | 22 | — | 819.67 | — | 0/3 |

- 기술 품질 게이트: 통과
- 밸런스 게이트: 실패
- 승리: 0/3
- 최종 보스 도전: 0/3
- 평균 프레임: 5.561ms
- 최악 프레임: 16.667ms
- 33ms 초과율: 0%
- 타임아웃·무효 보드·자식 프로세스·입출력 실패: 0

## 판정

M0의 목적이었던 재현 가능한 무아티팩트 대조군 저장과 기술 게이트는 완료됐다. 그러나 이 기준선은 v0.16의 “Base-only 평균 빌드가 최종 보스에 도전 가능” 목표를 충족하지 못한다.

주요 경고는 다음과 같다.

- 평균 생존 완료율 62.46%로 최소 장기 기준 85% 미달
- 완주 표본 0개로 최종 성장 속도 판정 불가
- STEP 형태 선택 0/4, 단일 병종 편대 선택 1/9
- `vanguard_hunt`, `judaginda_guard_sudden_death`가 각 3회 제시되고도 선택되지 않음

따라서 이 결과를 좋은 밸런스로 승인하지 않는다. M1~M5의 메타·온보딩·공통 언어 작업은 진행할 수 있지만, `global_upgrade` 제거와 아티팩트 효과를 결합하는 M6 전에 Base-only 저점 수렴을 별도 게이트로 해결해야 한다. 이후 변경은 같은 설정과 시드로 이 보고서와 비교한다.
