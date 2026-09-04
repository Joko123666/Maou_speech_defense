# GDD v0.19 M11 정책별 편대·특화 진단 감사

- 기준일: 2026-08-28
- 목적: M10 평균 정책 집계에서 보인 STEP·특화 선택 경고가 콘텐츠 공통 결함인지 빌드 정책별 선택 성향인지 분리
- 공통 조건: 5후보 시나리오, seed 1847, 3배속, Bonus disabled, 아티팩트 normal, 런당 600초
- 정책 조건: 강한 빌드×평균 숙련, 평균 빌드×평균 숙련, 약한 빌드×높은 숙련, 뒤엉킨 빌드×낮은 숙련

## 판정

콘텐츠 수치를 변경하지 않습니다. 20개 비교 런은 모두 최종 보스에 도전했고 품질·밸런스·성능 게이트를 통과했습니다. STEP 선택률은 정책별 20.0~75.0%로 분산되어 공통 저선택 현상이 아니며, 특화 경고도 네 정책에서 동일 안정 ID로 반복되지 않았습니다.

대신 감사 매트릭스를 개선했습니다. 각 `policy_cells` 항목은 자체 `balance_assessment`, `formation_diagnostics`, `specialization_diagnostics`를 보존합니다. 다중 정책 결과의 `policy_warning_overlap`은 경고 코드와 대상 안정 ID/형태/크기/효율 cohort를 결합한 식별자로 공통 경고와 정책 전용 경고를 자동 분리합니다. 이 파생 요약은 체크포인트 호환성이나 시뮬레이션 의미를 바꾸지 않으므로 schema와 빌드 정책 revision은 각각 19와 3을 유지합니다.

## 5후보 정책 비교

| 빌드/숙련 | 승리 | 평균 Lv. | 핵 체력 비율 | STEP 제안/선택 | STEP 선택률 | 편대 경고 | 특화 경고 | 아티팩트 제안/획득 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| strong/average | 2/5 | 29.2 | 23.4% | 8/2 | 25.0% | 0 | 1 | 8/7 |
| average/average | 1/5 | 29.0 | 11.7% | 10/2 | 20.0% | 0 | 2 | 8/8 |
| weak/high | 0/5 | 28.0 | 0.0% | 8/6 | 75.0% | 4 | 5 | 4/0 |
| tangled/low | 0/5 | 21.6 | 0.0% | 6/2 | 33.3% | 5 | 5 | 0/0 |

- 모든 셀은 5/5 완주 표본, 최종 보스 도전 5/5, 성능 예산 통과율 100%, 최악 프레임 16.667ms, 타임아웃·I/O 실패 0건입니다.
- strong의 특화 경고는 `tower_specialization_entry:execute` 과선택 1건입니다.
- average의 특화 경고는 `guard_specialization_entry:sapphire_spearhead` 미선택과 `tower_specialization_entry:pierce` 과선택입니다.
- weak의 특화 미선택 5건은 gold/iron 커서와 emerald/jade/obsidian 친위대 진입이며, 뒤엉킨 정책의 5건은 iron/platinum 커서와 amethyst/emerald/sapphire 친위대 훈련입니다. 동일 대상의 전 정책 공통 경고는 없습니다.
- 약한·뒤엉킨 정책은 강한·평균 정책보다 성장 선택 우선순위가 의도적으로 다릅니다. 따라서 이 두 정책의 제안 미선택을 강한 빌드용 특화 수치 상향 근거로 사용하지 않습니다.
- 기존 M10 3시드 평균 정책의 STEP 15/2(13.33%) 경고는 seed 1847의 10/2(20.0%)와 다른 정책의 25.0~75.0%를 함께 볼 때 단일 집계 경계값 효과입니다. 추가 시드 없이 STEP 데이터나 제안 가중치를 변경하지 않습니다.

## 감사 구조 개선

- `tests/balance_audit_matrix_runner.gd`
  - 정책 셀별 보고서를 다시 요약해 자체 밸런스 판정과 편대 형태/병종 수/크기, 특화 제안·선택률을 저장합니다.
  - `policy_warning_overlap.checked`, `compared_cells`, `common_warning_keys`, `warning_keys_by_cell`, `policy_specific_warning_keys`를 추가했습니다.
  - 경고 식별자는 단순 코드뿐 아니라 `specialization_id`, `formation_id`, `size`, `value`, `efficiency_cohort`, `artifact_id`, `target_group`을 포함합니다.
- `tests/contracts/v016_balance_audit_policy_contract_test.gd`
  - 정책별 진단과 공통/정책 전용 경고 분류가 감사 매트릭스에서 제거되지 않도록 계약을 추가했습니다.

## 검증

- Godot 4.7 전체 스모크: `SMOKE TEST PASS` 두 차례
- 장기 비교: 신규 strong/weak/tangled 15런과 기존 동일 seed average 5런, 합계 20런
- 30초 4정책 구조 프로브: 종료 코드 0, `quality_gate_passed=true`, 네 셀 모두 세 진단 필드 존재
- 구조 프로브 재개: `resumed_runs=4`, `policy_warning_overlap.checked=true`, `compared_cells=4`, 공통 경고 목록 생성 확인
- 종료 시 ObjectDB 134개·리소스 109개 정리 경고는 기존 스모크 종료 경고이며 테스트 실패는 아닙니다.

## 결과 파일

Godot 사용자 데이터 기준 경로는 `C:\Users\USER\AppData\Roaming\Godot\app_userdata\TD_survival`입니다.

| 파일 | 크기 | SHA-256 |
| --- | ---: | --- |
| `v019_m11_strong_result.json` | 148,052 bytes | `72E9FEE49A43BB1EC01B27DA99A253F6BF510F1F8078336F2B7D11224909BFD4` |
| `v019_m10_natural_1847_result.json` | 146,030 bytes | `5F6F261BCA5B544EEE573475CDDB412F684F0B1E4B44D3D709DA40823789DC19` |
| `v019_m11_weak_result.json` | 101,863 bytes | `C736C715C6AE6245A02B05CEB636F9BAF5DADBBF3033839D5405EC1866058CCB` |
| `v019_m11_tangled_result.json` | 92,157 bytes | `F0A24B5B9388DECFDE2DEC60C7790567B7BC1C0690071B9B02341D15258047FC` |
| `v019_m11_policy_diagnostics_probe_result.json` | 29,216 bytes | `C97CD9565D6FBB5303C59C7AC515DDF9B529BD9C38A3980DCE81276600AFC83A` |

## 남은 일

- **M12에서 완료:** strong/weak/tangled의 seed 42731·99881을 추가해 4정책 모두 5후보×3시드 15런으로 확장했습니다. 상세 결과는 `docs/RUNTIME_BALANCE_AUDIT_2026-08-28_V019_M12.md`를 따릅니다.
- strong의 정밀 피해 격차는 해소됐고 지속 화력 격차만 남았으나 average·tangled에서 재현되지 않아 수치를 유지했습니다.
- Android 실기기, 제품 ID/아이콘/버전, 릴리스 키, iOS/Windows 내보내기 준비는 외부 환경이 필요한 배포 후속으로 남습니다.
