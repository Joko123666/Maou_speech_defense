# GameController 상위 3개 추출 후 구조 재감사

- 감사일: 2026-08-30 (Asia/Seoul)
- 대상: `scripts/game/game_controller.gd`
- 기준: S4 상위 3개 실행 서비스 추출 뒤 4,029행·389개 인스턴스 함수
- 성격: 정적 감사. 런타임 코드·수치·씬·리소스는 변경하지 않음

## 1. 결론

S4에서 선정한 `SpiritAttackExecutionService`, `CursorHitEffectService`, `EnemySpecialActionExecutionService` 추출 뒤에는 즉시 분리할 만한 네 번째 `GameController` 규칙 경계가 없습니다.

남은 직접 피해·상태·공간 접근은 대부분 기존 서비스에 전달하는 실제 Node 콜백이거나 1~2개 함수의 작은 로컬 규칙입니다. 이들을 서비스로 옮기면 장면 결합이 줄기보다 Callable·결과 정산 경계가 늘어납니다. 따라서 현재 기준선에서 추가 컨트롤러 추출을 중단했습니다. 후속 단일 개선으로 지정했던, 런타임 스크립트 오류 뒤에도 전체 스모크가 `SMOKE TEST PASS`를 출력할 수 있는 검증 허점을 막는 엄격한 헤드리스 품질 게이트도 구현·검증 완료했습니다.

## 2. 정량 기준선

| 항목 | 최신 결과 | S4 기준 대비 | 판정 |
|---|---:|---:|---|
| 전체 행 | 4,029 | -63 | 최초 4,114행 대비 -85행 |
| 인스턴스 함수 | 389 | -6 | 최초 399함수 대비 -10함수 |
| 최대 함수 | 38행 | 동일 | `_run_signal_callbacks()` 신호 사전 구성으로 유지 |
| 20행 이상 | 31개 | +1 | 크기만으로 추출하지 않음 |
| 15행 이상 | 80개 | -4 | 서비스 연결·결과 정산이 다수 |
| 10행 이하 | 238개 | -5 | 전체의 61.2%, 얇은 조정·어댑터가 주류 |
| 5행 이하 | 118개 | -1 | 직접 위임 또는 단순 표현 함수 |
| 직접 `take_damage()` | 18곳 | -1 | 8개 서비스 피해 콜백, 3개 런타임 수명주기, 7개 로컬 규칙 |
| 직접 상태 적용 | 4곳 | -5 | 넉백·감속·공포의 작은 로컬 규칙 또는 타워 적중 콜백 |
| 직접 `RunRng` | 2곳 | -5 | 생성 위치와 뼈 파편 서비스의 얇은 RNG 콜백 |
| 직접 공간 인덱스 접근 | 14곳 | -5 | 8개 질의 어댑터, 6개 작은 로컬 규칙 |

함수 수가 줄어든 상태에서 20행 이상 함수가 한 개 늘어난 것은 새 대형 규칙이 생겼다는 뜻이 아닙니다. 상위 목록은 신호·튜토리얼·Core/타워 공격 서비스 연결과 결과 표현이 차지하며, 가장 큰 함수도 기존 38행 신호 콜백 사전입니다.

## 3. 직접 경계 분류

### 피해 18곳

- 서비스·피해 경계 콜백 8곳: 사령, 죽음의 파도, 목표지점 후속, Core 특화/벽/포격, 뼈 파편, 일반 타워의 실제 `take_damage()` 어댑터입니다.
- 런타임 수명주기 3곳: 일반/보스 Core 돌파와 튜토리얼 보스 종료입니다.
- 로컬 규칙 7곳: 돌격부대 희생, 저므조므 재소환, 목표지점 보상 연쇄, Core 후속 사격, 목표지점 기본 피해 폴백, Core 고점 광역, 이동 궤적탄입니다.

서비스 콜백은 실제 Node 생명주기를 소유하는 컨트롤러에 남겨야 합니다. 로컬 규칙 7곳도 하나의 도메인으로 묶이지 않고 각각 기존 신호·메트릭·표현 흐름에 붙어 있어 독립 서비스의 응집도가 낮습니다.

### 상태 4곳

- 돌격부대 희생 넉백과 저므조므 재소환 감속은 각각의 신호 결과 정산에 붙어 있습니다.
- 주다긴다 처형 공포는 단일 13행 규칙이며 modifier·공간 질의·메트릭·표현을 한 장소에서 읽을 수 있습니다.
- 고유 방사 타워 감속은 `UniqueFieldAttackExecutionService`가 호출하는 실제 적중 콜백입니다.

### RNG 2곳

- 일반 적 생성 위치의 `RunRng.spawn_rangef()`는 전장의 자유 위치 요청 인자입니다.
- 뼈 파편의 `RunRng.rangef()`는 `SkeletonBoneShardExecutionService`에 전달하는 명시적 RNG 콜백입니다.

두 위치 모두 순서 규칙을 컨트롤러에서 계산하지 않으므로 추가 추출 대상이 아닙니다.

### 공간 인덱스 14곳

- 8곳은 목표지점 공격 후보 구성, Core 반격·돌격부대 원형, 타워 타기팅, 처형 기절, 네트워크/관통 선분, 골렘 제어에 전달하는 질의 어댑터입니다.
- 6곳은 돌격부대 희생, 저므조므 재소환, 처형 공포, 보상 연쇄, Core 고점 광역, 이동 궤적탄의 작은 로컬 규칙입니다.

공간 질의 자체보다 대상 순서·생존 단계·RNG 소비 순서가 함께 있는지가 추출 기준입니다. 여섯 로컬 규칙에는 S4 상위 3개와 같은 독립 순서 계약이 없습니다.

## 4. 남은 후보 판정

| 후보 | 규모·결합 | 판정 | 재검토 조건 |
|---|---|---|---|
| 돌격부대 희생·저므조므 재소환 범위 효과 | 2함수·약 30행, 서로 다른 컴포넌트 신호와 메트릭·표현 결합 | 유지 | 같은 심복/돌격부대 범위 규칙이 3개 이상으로 늘거나 독립 정책이 필요할 때 |
| 주다긴다 처형 공포 | 1함수·13행 | 유지 | 공포 전파·저항·대상 우선순위가 추가될 때 |
| 목표지점 이동 궤적탄 | 누적 상태와 발사 포함 2함수·18행 | 유지 | 다중 탄종·RNG·관통 등 독립 실행 정책이 생길 때 |
| 목표지점 보상 연쇄 | 1함수·5행 | 유지 | 연쇄 횟수·대상 선택·감쇠 규칙이 추가될 때 |
| Core 고점 광역·후속 사격 | 기존 Core/목표지점 서비스의 실제 피해·표현 콜백 | 유지 | 서비스가 결과가 아니라 대상 선택까지 호출자에게 중복 요구할 때 |

현재 후보들은 기존 계획의 선정 게이트인 같은 도메인 보조 함수 3개 이상, 20행 이상의 규칙·표현 혼합, 호출자에게 전달할 실패 사유, 독립 계약 부재를 동시에 충족하지 않습니다.

## 5. 엄격한 헤드리스 품질 게이트 (완료)

이전 `EnemySpecialActionExecutionService` 계약을 처음 통합했을 때 테스트 클로저 오류로 `SCRIPT ERROR`와 후속 누수가 발생했지만 일반 스모크 러너는 마지막에 `SMOKE TEST PASS`를 출력했습니다. GDScript의 `failures` 배열은 엔진이 보고한 런타임 스크립트 오류를 자동 수집하지 않으므로 PASS 문자열만 확인하는 절차는 안전하지 않습니다.

`tools/run_headless_quality_gate.ps1`을 추가해 PowerShell 진입점 하나에서 아래 일곱 단계를 실행하고 로그와 프로세스 종료 상태를 함께 판정합니다.

1. Godot 헤드리스 편집기 파싱.
2. `tests/content_election_runtime_smoke.tscn`과 정확한 `CONTENT ELECTION SMOKE PASS` 확인.
3. `tests/meta_progression_persistence_smoke.tscn`과 정확한 `META PERSISTENCE SMOKE PASS` 확인.
4. `tests/preparation_runtime_smoke.tscn`과 정확한 `PREPARATION RUNTIME SMOKE PASS` 확인.
5. 전체 `tests/smoke_test.tscn`과 정확한 `SMOKE TEST PASS` 확인.
6. `tests/tutorial_runtime_smoke_test.tscn`과 정확한 `TUTORIAL RUNTIME SMOKE PASS` 확인.
7. `--verbose` 전체 스모크에서 `SCRIPT ERROR`, 일반 오류, ObjectDB·리소스 누수, Orphan StringName을 검사.

각 프로세스의 종료 코드가 0이 아니거나 성공 표식이 없거나 금지 오류·누수 패턴이 하나라도 있으면 래퍼가 비0으로 종료합니다. 실패 시 단계별 마지막 40줄을 표시하고, 모든 원본 로그와 JSON 요약 경로를 남깁니다. `full` 외에도 단계별 모드와 Godot 없이 판정기만 검증하는 `selftest` 모드를 제공합니다.

각 자식 프로세스는 기본 120초, CLI 허용 1~3600초의 `StageTimeoutSeconds` 안에 끝나야 합니다. stdout/stderr를 비동기 수집하고 상한 초과 시 프로세스 트리를 종료해 exit `-1`, `nonzero_exit`·`timeout` 위반과 상한/경과 시간을 JSON에 남깁니다. 자체 판정 13개 사례가 정상 성공, 콘텐츠·선거/메타/출격 준비 성공, timeout, 오류와 PASS 동시 출력, 성공 표식 누락, 비0 종료, 일반 엔진 오류, ObjectDB/리소스 누수, Orphan StringName, 진단 문구 오탐 방지를 확인하고 실제 3초 자식 프로세스를 1초에 종료하는 probe도 수행합니다.

## 6. 검증과 상태

- 구조 감사는 함수 시작점·본문 길이와 직접 피해·상태·RNG·공간 인덱스 참조를 실제 최신 코드에서 정적으로 대조했습니다.
- 품질 게이트 구현 뒤 PowerShell 구문 검사, 13개 자체 판정 사례와 실제 bounded-process timeout probe가 통과했습니다.
- 새 `full` 진입점으로 Godot 4.7 파싱, 콘텐츠·선거 `CONTENT ELECTION SMOKE PASS`, 메타 `META PERSISTENCE SMOKE PASS`, 출격 준비 `PREPARATION RUNTIME SMOKE PASS`, 전체 `SMOKE TEST PASS`, 튜토리얼 `TUTORIAL RUNTIME SMOKE PASS`, verbose 전체 `SMOKE TEST PASS`를 실행했고 일곱 단계 모두 종료 코드 0, 성공 표식 확인, 금지 오류·누수 0건으로 통과했습니다.
- Godot parse에 1초 상한을 적용한 음성 검사에서 프로세스가 1.053초에 종료되고 `nonzero_exit, timeout`과 `timed_out=true`가 JSON에 기록됐습니다. 기본 120초 전체 게이트의 최장 단계는 14.838초이고 timeout은 0건입니다.
- 추가 `GameController` 서비스 추출 백로그는 활성화하지 않습니다. 위 재검토 조건이 생길 때만 다시 엽니다.
- `MetaProgressionPersistenceSmoke`·`ContentElectionRuntimeSmoke`·`PreparationRuntimeSmoke` 분리, `BalanceAuditSummaryContractTest`·`EnemyRuntimeStateContractTest`·`CatalogGrowthRuntimeContractTest` 모듈화, 중복 assertion 총 12개 제거를 완료해 기존 runner는 1,664행·4함수, `_run()` 1,638행·336 assertion이 됐습니다. 메뉴와 메인 게임은 시나리오 단위로 유지하고 품질 게이트의 단계별 실행 시간 상한까지 완료해 즉시 구현할 내부 구조·신뢰성 백로그는 없습니다.
- Android M7 실기기 표본과 제품 식별자·릴리스 키 결정은 계속 별도 외부 입력 트랙입니다.
