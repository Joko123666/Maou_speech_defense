# GDD v0.19 M10 아티팩트 자연 표본 확대

- 점검일: 2026-08-28 (Asia/Seoul)
- 범위: 5후보 대표 시나리오 × 시드 1847/42731/99881 × 600초
- 공통 조건: 3배속, `average_coherent` 빌드, `average` 숙련, Bonus disabled, 아티팩트 normal
- 결론: **아티팩트 제안 빈도와 비강제 선택 승인. 확률·효과 조정 없이 유지한다.**

## 1. 목적

M8C의 `judgment_vanguard` 단일 후보 3시드 표본을 다섯 후보로 확대해 다음 항목을 확인했다.

- 완주 런당 평균 제안 1~2회 목표 유지 여부
- 아티팩트가 등장할 때 사실상 항상 선택되는지 여부
- 후보·심복·친위대·일반 병력·상태 대상군의 자연 노출 여부
- 아티팩트가 없어도 최종 보스에 도전 가능한 저점 보장 유지 여부
- 결과 JSON만으로 감사 schema와 정책 revision을 식별할 수 있는지 여부

## 2. 통합 결과

| 지표 | 결과 | 판정 |
|---|---:|---|
| 수집 런 | 15/15 | 통과 |
| 품질/밸런스/성능 게이트 | 모두 통과 | 통과 |
| 최종 보스 도전 | 15/15 | 저점 보장 유지 |
| 승리 | 3/15, 20% | 후보별 1승씩 세 후보에서 관측 |
| 평균 경과 | 644.96초 | 완주 표본 |
| 평균 레벨 | 29.07 | 목표 25±5 안 |
| 평균 처치 | 1,607.8 | 참고값 |
| 아티팩트 제안 | 21회, 완주당 1.40회 | 목표 1~2회 통과 |
| 아티팩트 획득 | 19회, 런당 1.27회 | 제안 이하 |
| 선택률 | 90.48%, 19/21 | 비선택 2건 확인 |
| 평균/최대 보유 | 1.27 / 3 | 6칸 상한 이하 |
| 6칸 완성·교체·포기 | 0 / 0 / 0 | 낮은 출현률에서 정상, forced 계약 유지 |

`artifact_offer_frequency`와 `artifact_selection_forced` 진단은 통합 15런에서 모두 발생하지 않았다. 따라서 5.5% 출현률과 현재 효과 수치는 조정하지 않는다.

## 3. 후보별 결과

| 시나리오 | 런 | 승리 | 평균 경과 | 평균 Lv. | 제안 | 획득 | 선택률 |
|---|---:|---:|---:|---:|---:|---:|---:|
| `royal_armament` | 3 | 1 | 640.12초 | 29.33 | 3 | 3 | 100% |
| `charm_combo` | 3 | 1 | 647.97초 | 28.33 | 5 | 5 | 100% |
| `abyss_research` | 3 | 0 | 669.01초 | 29.67 | 3 | 2 | 66.67% |
| `necromancy_vanguard` | 3 | 1 | 662.32초 | 30.00 | 6 | 5 | 83.33% |
| `judgment_vanguard` | 3 | 0 | 605.39초 | 28.00 | 4 | 4 | 100% |

모든 후보가 최종 보스에 도전했다. 후보별 3런은 승률 비교를 확정하기에는 작으므로 승리 0/3인 카스하·주다긴다를 즉시 상향하지 않는다.

## 4. 대상군과 선택

| 대상군 | 제안 | 선택 | 선택률 |
|---|---:|---:|---:|
| 후보 | 1 | 1 | 100% |
| 심복 | 6 | 5 | 83.33% |
| 친위대 | 4 | 4 | 100% |
| 일반 수비병력 | 7 | 6 | 85.71% |
| 상태 | 3 | 3 | 100% |

다섯 대상군이 모두 자연 표본에 등장했다. 비선택은 일반 병력용 `control_compass` 1회와 심복용 `silver_spur` 제안 중 1회에서 발생했다. 전체 선택률이 100%가 아니므로 일반 성장을 항상 밀어내는 강제 선택 증거는 없다.

## 5. 적용한 감사 개선

`tests/balance_audit_matrix_runner.gd`의 최종 결과에 다음 필드를 명시했다.

- `audit_schema_version`
- `build_policy_revision`
- `rng_revision`

기존에는 이 값들이 자식 보고서와 체크포인트 구성 서명에만 있어 최종 결과 JSON 단독으로는 revision을 확인하기 어려웠다. schema 자체의 데이터 호환 경계는 바뀌지 않아 현재 버전 19를 유지한다. 계약 테스트가 세 필드의 최종 요약 보존을 검사한다.

## 6. 남은 관측 항목

- normal 1~2회 목표에서는 6칸 포화가 일반적인 한 런 결과가 아니므로 교체/포기는 forced 계약 검증을 계속 권위로 사용한다.
- 이번 표본은 평균 빌드·평균 숙련만 사용했다. `strong_synergy`, `weak_coherent`, `tangled` 정책의 선택률과 아티팩트별 효용 차이는 후속 표본이다.
- 통합 감사에는 STEP 저선택 1건과 특화 미선택/과선택 경고가 남았다. 이는 아티팩트 빈도·강제 선택 경고가 아니며, 정책별 표본을 분리하기 전 수치 변경 근거로 사용하지 않는다.
- Android 실기기·릴리스 서명·제품 ID/아이콘·iOS/Windows 내보내기는 별도 배포 작업이다.

## 7. 재현 정보

권위 통합 결과:

- `user://v019_m10_natural_combined_result.json`
- 현재 M12 진단 구조 재요약본: 356,812 bytes, SHA-256 `1F9967CFD3A1E3C3169760C9D417F3718746C756CFBF2D04BF0C3643C2BAF4CB`
- 최초 M10 결과: 195,738 bytes, SHA-256 `50D31C5A1B0053A0D6F6AAF8A75BD4C372654AB7B04B01499096400598E266FF` (원시 15런은 동일하며 M12에서 정책 셀·시나리오 진단만 다시 파생함)

통합 체크포인트는 41,792,354 bytes, SHA-256 `525E92F702699080F798482C4C5738B184E415EB1158F9216F90F3DF8285847D`다.

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --audio-driver Dummy res://tests/balance_audit_matrix.tscn -- --scenarios=royal_armament,charm_combo,abyss_research,necromancy_vanguard,judgment_vanguard --seeds=1847,42731,99881 --speeds=3 --build-policies=average_coherent --skill-policies=average --bonus-modes=disabled --artifact-mode=normal --audit-seconds=600 --checkpoint=user://v019_m10_natural_combined_checkpoint.json --result=user://v019_m10_natural_combined_result.json --resume
```

코드 변경 뒤 전체 `SMOKE TEST PASS`를 재확인했다. 종료 시 ObjectDB 134개와 리소스 109개의 정리 경고는 기존 알려진 테스트 종료 경고다.
