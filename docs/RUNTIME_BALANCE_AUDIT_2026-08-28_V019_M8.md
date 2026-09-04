# v0.19 M8 아티팩트 결과·밸런스 감사

- 실행일: 2026-08-28 (Asia/Seoul)
- 엔진: Godot 4.7 stable, Forward Mobile
- 감사 schema: v18
- 빌드 정책 / Run RNG revision: 3 / 2
- 판정: 기술 품질 통과, 통합 밸런스 미승인

## 범위

M8에서 아티팩트의 제안·획득·포기·교체·최종 보유·대상군·효과 기여 추정치를 `RunMetrics`, 결과 화면, `RunOutcomeSummary`, 정산 체크포인트와 감사 JSON에 같은 구조로 보존하는지 확인했다. 감사 모드는 `disabled|normal|forced`로 분리했으며 `forced`는 계약과 상한 검증에만 사용하고 승률 비교에서는 제외했다.

장기 비교 조건은 두 모드 모두 다음과 같다.

| 축 | 값 |
|---|---|
| 시나리오 | `judgment_vanguard` |
| 시드 | `1847`, `42731`, `99881` |
| 빌드 / 숙련 | `average_coherent` / `average` |
| Bonus Spawn | `disabled` |
| 배속 / 목표 시간 | 3× / 600초 |

## 기술 검증

| 검증 | 결과 |
|---|---|
| Godot 헤드리스 에디터 파싱 | 종료 코드 0 |
| 전체 계약·게임플레이 스모크 | `SMOKE TEST PASS` |
| normal 60초 1×/2×/3× 안정 지문 | 일치, `speed_equivalence.passed=true` |
| forced 60초 계약 런 | 제안 2, 획득 1, 선택률 50%, 성능 예산 통과 |
| disabled / normal 600초 매트릭스 품질 | 각 3/3 유효, timeout 0, 성능 실패 0 |
| hard-counter 경고 | 두 모드 합계 0 |
| 결과 UI | D3D12 Forward Mobile 종료 코드 0, 승리·패배 1280×720 직접 검수 통과 |

장기 감사의 평균 프레임 시간은 disabled 5.560ms, normal 5.560ms였고 두 모드 모두 최악 프레임 16.667ms, 33ms 초과율 0%였다. 모바일 실기기 성능 승인을 대체하지는 않는다.

## 600초 동일 시드 비교

| 모드 | 시드 | 생존 | Lv. | 처치 | 최종 보스 | 승리 | 제안 / 획득 | 최종 보유 |
|---|---:|---:|---:|---:|---|---|---:|---|
| disabled | 1847 | 414.78초 | 26 | 913 | 미도달 | 실패 | 0 / 0 | 없음 |
| disabled | 42731 | 324.72초 | 21 | 649 | 미도달 | 실패 | 0 / 0 | 없음 |
| disabled | 99881 | 619.13초 | 30 | 1,982 | 도달 | 승리 | 0 / 0 | 없음 |
| normal | 1847 | 442.10초 | 27 | 1,011 | 미도달 | 실패 | 2 / 2 | `green_gear`, `bloodletter_needle` |
| normal | 42731 | 321.00초 | 20 | 612 | 미도달 | 실패 | 0 / 0 | 없음 |
| normal | 99881 | 442.92초 | 27 | 1,050 | 미도달 | 실패 | 0 / 0 | 없음 |

| 집계 | disabled | normal |
|---|---:|---:|
| 평균 생존 | 452.88초 | 402.01초 |
| 평균 완료율 | 74.4% | 67.0% |
| 최종 보스 도전 | 1/3 | 0/3 |
| 승리 | 1/3 | 0/3 |
| 총 제안 / 획득 | 0 / 0 | 2 / 2 |
| 평균 제안 / 보유 | 0 / 0 | 0.667 / 0.667 |
| 최대 보유 | 0/6 | 2/6 |
| 런당 평균 추정 기여 | 0 | 2,403.8 |

normal에서 실제 아티팩트를 얻은 시드 1847은 disabled 대비 생존 +27.32초, 레벨 +1, 처치 +98, 관측 출력 비례 추정 기여 7,211.3을 기록했다. 따라서 개별 고점 상승은 관측됐지만, 3시드 분포 전체는 disabled보다 낮았으므로 normal 고점 분포가 안정적으로 증가했다고 승인할 수 없다.

normal의 두 아티팩트는 일반 수비병력과 상태 대상군에서 각각 1회 선택됐다. 후보·심복·친위대 대상 표본, 포기·교체, 6칸 완성 표본은 없었다. 선택률 100%도 제안 2회뿐이므로 강제 선택으로 판정할 표본이 부족하다. 완주 normal 표본이 0개여서 “완주당 평균 1~2회” 게이트도 판정을 보류하며, 요약기는 중도 종료 런을 이 게이트에 사용하지 않도록 수정했다.

## 판정

- 결과·체크포인트·감사 원장, 공개 정보 선택 정책, 세 모드, 속도 등가성과 데스크톱 성능은 승인한다.
- Base-only는 평균 완료율 85%와 무아티팩트 최종 보스 도달 보장을 충족하지 못했다.
- normal은 개별 획득 런의 상승은 보였지만 전체 분포와 최종 보스 도달이 개선되지 않았다.
- 따라서 M8 기술 구현은 완료했지만 장기 밸런스는 미승인이다. 이 결과로 M9 모바일·배포 승인을 진행하지 않는다.

진단 중 해골 원본 돌파 피해 9→6, 고정 사선 누수만 20%·5% 칩 피해로 낮추는 국소 실험을 각각 수행했다. 시드 1847은 443.2초, 471.4초, 495.0초에 여전히 종료됐고 후반에는 중간 보스 반복 돌파가 다음 병목이 됐다. 단일 적 수치만 낮추는 방식은 근본 수렴책이 아니므로 모든 실험 변경을 복원했다.

## 재현 명령

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847,42731,99881 --speeds=3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --artifact-mode=disabled --audit-seconds=600 --checkpoint=user://v019_m8_disabled_checkpoint.json --result=user://v019_m8_disabled_result.json

& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . tests/balance_audit_matrix.tscn -- --scenarios=judgment_vanguard --seeds=1847,42731,99881 --speeds=3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --artifact-mode=normal --audit-seconds=600 --checkpoint=user://v019_m8_normal_checkpoint.json --result=user://v019_m8_normal_result.json
```
