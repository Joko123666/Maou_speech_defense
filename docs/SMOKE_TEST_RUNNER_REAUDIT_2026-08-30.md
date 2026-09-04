# 전체 스모크 러너 구조 재감사

- 감사일: 2026-08-30 (Asia/Seoul)
- 대상: `tests/smoke_test_runner.gd`, `tests/smoke_test.tscn`, `tools/run_headless_quality_gate.ps1`
- 기준: 엄격한 헤드리스 품질 게이트 구현 완료 뒤 최신 코드
- 성격: 정적 감사 뒤 P1·P2·P6 프로세스 격리와 P3~P5 계약 모듈화·중복 제거 구현/검증 완료

## 1. 결론

`smoke_test_runner.gd`는 2,741행·5함수이고 `_run()` 한 함수가 2,706행입니다. 실제 assertion은 599개, `await`는 53회, 객체 생성은 89회, 명시적 `free()`·`queue_free()`는 97회입니다. 크기만의 문제가 아니라 순수 계약 호출, 파일 내구성, Autoload 상태 변경, 메뉴·게임 장면의 순차 런타임 검사가 한 코루틴과 하나의 `failures` 배열을 공유합니다.

다만 실제 게임 장면 1,472행은 하나의 `GameController`를 순차 재사용해 입력→공격→성장→최종 보스→결과 상태를 검증합니다. 이를 작은 함수나 파일로 기계적으로 이동하면 장면 상태 인자가 늘고 실행 계약은 그대로 결합된 채 위치만 흩어집니다. 첫 개선으로 장면 런타임과 독립적이면서 파일·Autoload 오염 위험이 큰 저장·체크포인트·메타 진행 211행을 별도 프로세스로 격리했습니다.

## 2. 정량 기준선

| 항목 | 결과 | 해석 |
|---|---:|---|
| 전체 행 | 2,741 | 단일 테스트 진입점에 여러 세대 계약 누적 |
| 함수 | 5 | `_ready`, 검사/파일/열 fixture 보조와 `_run` |
| `_run()` | 2,706행 | 전체 파일의 98.7% |
| 실제 assertion | 599 | `_check()` 정의 1건은 제외 |
| 외부 계약 suite 호출 | 51 | 이 중 host `self`를 받는 호출 14건 |
| `await` | 53 | 메뉴·게임 장면 프레임과 pause 추종 타이머 중심 |
| 객체 생성 | 89 | `new()`와 `instantiate()` 기준 |
| 명시적 정리 | 97 | `free()`와 `queue_free()` 기준 |

## 3. 논리 구간 분류

| 구간 | 행·규모 | 상태·수명주기 특성 | 판정 |
|---|---:|---|---|
| 외부 계약 dispatch `38~140` | 103행, suite 51개 | 37개 순수 호출과 host 의존 호출 14개, 실패 배열만 공유 | 유지. 현재 구현 동결 계약이 진입점의 호출 문자열을 직접 확인하므로 별도 개선에서 registry 계약부터 바꿔야 함 |
| 콘텐츠·선거 런타임 `141~343` | 203행, assertion 36, await 2 | 콘셉트 교체, 메뉴·레벨업 패널, 선거 진행 백업/복원, 오디오·RNG | **P2 분리 완료** |
| 저장·체크포인트·메타 `344~554` | 211행, assertion 57, await 0 | 파일 참조 7, 전역 상태 변경 30, Node 생성 5·정리 4 | **P1 분리 완료** |
| 카탈로그·밸런스·상태 `555~1102` | 548행, assertion 144, await 0 | 데이터 표면·감사 요약·적 상태 fixture가 혼합 | 한 묶음 추출 금지. P3 밸런스 요약 168행·25 assertion과 P4 고유 피해/상태 133행·23 assertion을 전용 계약으로 이동 완료 |
| 메뉴 장면 `1103~1145` | 43행, assertion 12, await 8 | 한 메뉴 인스턴스의 페이지·선택 전이 | 작고 응집되어 현 위치 유지 |
| 출격 준비 장면 `1146~1260` | 115행, assertion 26, await 4 | 별도 GameController의 편대 선택·포기·결과 snapshot | P3. 이미 자체 장면 수명이 명확하지만 우선 효과가 작음 |
| 메인 게임 장면 `1261~2732` | 1,472행, assertion 324, await 38 | 한 게임 인스턴스와 전투·성장·종료 상태를 순차 재사용 | 현재 시나리오 단위 유지. 내부 도메인 이동은 프로세스 격리가 아님 |
| 정리·종료 `2733~2741` | 9행 | 음성 풀 정리, PASS/FAIL와 프로세스 종료 | 진입점 유지 |

## 4. 핵심 위험

### PASS 문자열과 엔진 오류

기존 `failures` 배열은 `_check()` 실패만 수집하고 GDScript 런타임 오류는 수집하지 못합니다. 이 문제는 `run_headless_quality_gate.ps1`이 프로세스 출력과 종료 누수를 함께 판정해 탐지합니다. 러너 분리의 목표는 탐지 중복이 아니라 오류 뒤 다른 영역이 오염되는 범위를 줄이는 것입니다.

### 전역 상태와 파일 fixture 오염

저장·체크포인트·메타 구간은 `SaveManager`, `RunCheckpointService`, `MetaProgressionService` 상태를 백업한 뒤 바꾸고 `user://smoke_*` 파일을 생성·회전·삭제합니다. 일반 assertion 실패는 계속 진행되어 정리까지 도달하지만 런타임 스크립트 오류가 현재 코루틴을 끊으면 복원과 파일 삭제를 건너뛸 수 있습니다. 같은 프로세스의 뒤쪽 메뉴·게임 검사는 오염된 상태에서 연쇄 실패할 수 있습니다.

### 기계적 함수 분리의 한계

메인 게임 구간을 `_test_core()`, `_test_towers()`처럼 같은 스크립트의 보조 함수로 옮기면 하나의 `game`, `failures`, SceneTree와 RNG를 계속 공유합니다. 행 수는 줄어도 실패 격리·실행 시간·진단 소유권은 개선되지 않으므로 첫 단계로 선택하지 않습니다.

## 5. P1 첫 단일 구현 — MetaProgressionPersistenceSmoke (완료)

`344~554`의 저장 schema·원자 교체·보상·체크포인트·메타 잠금/정산/구매·도전 단계 UI 계약을 전용 runner와 scene으로 이동했습니다.

### 소유권

- 신규 runner: 자체 `failures`, JSON fixture 쓰기, `SaveManager`·`RunCheckpointService`·`MetaProgressionService` 백업/변경/복원, `user://smoke_*` 선삭제·후삭제, 결과 timeline과 challenge 메뉴 fixture.
- 기존 전체 스모크: 콘셉트·오디오/RNG 검증 뒤 카탈로그·밸런스·상태와 실제 메뉴·게임 장면 시나리오를 계속 소유.
- PowerShell 품질 게이트: 전용 scene을 별도 Godot 프로세스로 실행하고 정확한 `META PERSISTENCE SMOKE PASS`와 공통 오류·누수 패턴을 판정.

### 필요한 계약

1. 신규 프로세스는 시작 시 과거 `smoke_meta_save*`·`smoke_run_checkpoint*` fixture를 먼저 제거합니다.
2. 현재 57개 assertion과 정확 수치·파일 회전 순서를 변경하지 않습니다.
3. 일반 assertion 실패에도 메모리 상태와 fixture 정리를 수행한 뒤 비0으로 종료합니다.
4. 런타임 오류로 정리가 중단되어도 다음 실행의 선삭제와 프로세스 격리로 메인 게임 스모크를 오염시키지 않습니다.
5. 기존 전체 스모크에서 이동한 assertion은 중복 실행하지 않습니다.
6. 엄격한 품질 게이트는 파싱, 콘텐츠·선거, 메타 지속성, 출격 준비, 전체 스모크, 튜토리얼, verbose 전체 스모크의 일곱 단계를 모두 통과해야 성공합니다.
7. 구현 동결 계약은 신규 scene·runner 경로와 품질 게이트 호출을 요구하도록 갱신합니다.

### 위험과 대응

- 순서 변화: 원본 `344~554` 내부 순서를 그대로 보존하고 독립 프로세스의 초기 Autoload 상태만 명시합니다.
- `default_stage` 의존: runner가 `ConceptService.get_default_stage()`를 직접 조회하고 유효성을 첫 assertion/선행 검사로 고정합니다.
- 비동기 메뉴 정리: 현재 검사는 프레임 대기 없이 속성을 읽습니다. 이 순서를 유지하고 프로세스 종료 전 Node 정리만 보장합니다.
- 전체 실행 시간 증가: Godot 프로세스 한 번이 추가되지만 실패 도메인 식별과 상태 격리가 우선입니다. 이후 측정값으로 유지 여부를 판단합니다.

## 6. P2 구현 결과와 후속 후보

P1 완료 뒤 최신 `smoke_test_runner.gd`를 다시 계측했습니다. 기존 runner는 2,741행·5함수에서 2,521행·4함수로, `_run()`은 2,706행에서 2,495행으로 줄었고 assertion은 599개에서 542개가 됐습니다. 전용 `meta_progression_persistence_smoke_runner.gd`는 267행·6함수·58 assertion이며, 이동한 57개 계약에 기본 스테이지 유효성 선행 검사 1개를 더했습니다. 기존 runner의 `smoke_meta_save`·`smoke_run_checkpoint` fixture 참조는 0건입니다.

P2 재감사에서는 콘텐츠 팩의 순수 검증 일부가 기존 계약 suite와 겹치더라도, 같은 구간이 `ConceptService` 프로필을 세 번 교체하고 `SaveManager` 선거 진행을 바꾸며 실제 메뉴·레벨업 씬을 생성한다는 점을 확인했습니다. 복원 전 스크립트 오류가 이후 2천여 행을 잘못된 프로필과 저장 상태로 실행시킬 수 있어 `ContentElectionRuntimeSmoke` 별도 프로세스로 격리했습니다. 원래 프로필·콘텐츠 잠금 우회·후보/심복 선택 ID·지지도/당선/칙령을 자체 복원합니다.

P2 뒤 기존 runner는 2,320행·4함수, `_run()` 2,294행·506 assertion입니다. 전용 `content_election_runtime_smoke_runner.gd`는 250행·5함수·36 assertion이며 기존 runner의 `example_arcane_reskin.tres`와 선거 UI fixture 참조는 0건입니다. 최초 기준선과 비교하면 기존 runner에서 총 421행·93 assertion을 두 독립 프로세스로 이동했고, 기본 스테이지 조회와 이후 테스트에 필요한 콘텐츠 잠금 우회만 남겼습니다.

P3 재감사에서는 최신 `134~681` 548행을 다시 나눴습니다. `BalanceAuditSummary`의 합성 2런 집계와 표본 충분성·편대/특화/효율 진단 `358~525`는 168행·25 assertion이고 await, Node 생성, 전역 상태 변경이 모두 0건입니다. 기존 v0.16 계약은 정책 축과 혼합 시나리오 진단을 검증하지만 이 25개 기본 집계·경고 계약을 대체하지 않으므로 삭제하지 않고 `BalanceAuditSummaryContractTest`로 이동했습니다. 메인 runner에는 전용 suite dispatch만 남겼고 구현 동결 계약이 경로와 호출을 고정합니다.

P3 뒤 기존 runner는 2,154행·4함수, `_run()` 2,128행·481 assertion입니다. 전용 계약은 183행·3함수·25 assertion이며 전체 자동 검증 assertion 수는 그대로입니다. 남은 구간은 카탈로그·편대·성장·런 메트릭 `136~359` 224행과 실제 피해·상태 Node `360~515` 156행으로 분리됩니다.

P4에서는 실제 피해·상태 156행·26 assertion을 `CommonStatusV013ContractTest`와 assertion 단위로 대조했습니다. 공통 화상의 source-agnostic 감쇠와 재적용 timeline 2개, 단일 출혈원의 스택 비례 피해 1개는 기존 계약이 같거나 더 강한 다중 source 조건으로 검증하므로 중복 fixture 23행·3 assertion을 제거했습니다. 나머지 피해 실제 손실, 공격 timer remainder, 긴 프레임 상태 만료, 상태 사망과 Core 도달 배제, 강도별 갱신, 저항/정화, 성장 profile, shock cap, 서로 다른 출혈 source의 독립 만료, 상태 enum 23개는 고유합니다.

고유 133행·23 assertion은 smoke host의 SceneTree를 명시적으로 받는 `EnemyRuntimeStateContractTest`로 이동했습니다. 기존 `add_child`·process 비활성·signal·`queue_free` 순서를 보존하고 메인에는 한 번의 `run(self)` dispatch만 남겼습니다. P4 뒤 기존 runner는 정확히 2,000행·4함수, `_run()` 1,974행·455 assertion이며 전용 계약은 148행·3함수·23 assertion입니다. 직접 중복 assertion 수만 3개 줄고 고유 동작 범위는 유지됩니다.

P5에서는 카탈로그·편대·성장·런 메트릭 224행·93 assertion site를 기존 53개 suite와 대조했습니다. v0.19 후보·심복 수, 자산 계약의 15종 병력 런타임 texture·일반/친위대 고유성, v0.13/v0.14 초기 4칸 편대와 starter 병종, v0.15 일반 적 수·정확 ID의 9개 assertion은 기존 계약이 같거나 더 강하게 보장하므로 제거했습니다. 편대 총수·15/17/17 크기·shape 오류와 후보 효과 texture의 중복 조건도 각 assertion에서 빼고 숨은 reinforcement role, 22개 2차원 편대, 빈 보드 배치 가능성, 실제 effect style만 남겼습니다.

나머지 전투 pace·커서/적 texture 연결·타격 effect routing·편대 점수/친위대 layout·분기/특화 수치·성장 라우팅·도전 Spawn·보스 곡선·XP 신호/무상한 처리·RunMetrics 84개 고유 assertion은 host SceneTree를 받는 `CatalogGrowthRuntimeContractTest` 220행·3함수로 이동했습니다. P5 뒤 기존 runner는 1,777행·4함수, `_run()` 1,751행·362 assertion이며 외부 dispatch는 54개입니다. 자동 검증의 고유 동작 범위는 유지되고 정적 중복 assertion만 9개 줄었습니다.

P6에서는 출격 준비 `182~295` 114행·26 assertion의 수명주기를 재감사했습니다. 이 구간은 별도 `GameController` 하나를 생성해 기본 친위대 준비→확정→첫 편대 제안→배치 포기와 40% 환급→다음 편대 성공→편대 메트릭·빌드 요약→결과 보드 snapshot까지 끝낸 뒤 해제합니다. 파일 접근과 SaveManager 직접 변경은 0건이고 `testing_mode`가 체크포인트·정산 저장을 차단합니다. 프로세스 입력은 콘텐츠 잠금 우회와 기본 emerald/iron·도전 0, pause 상태뿐이라 독립 진입점으로 고정할 수 있습니다.

26개 assertion을 `preparation_runtime_smoke_runner.gd` 166행·4함수와 전용 scene으로 그대로 이동했습니다. runner는 선택 후보/심복/도전/칙령·run/artifact mode·last result와 콘텐츠 잠금 우회를 백업하고 emerald/iron 기준선을 명시한 뒤 정상 종료에서 복원합니다. 정확한 `PREPARATION RUNTIME SMOKE PASS`를 출력하고 품질 게이트의 `preparation` 단계가 이를 별도 Godot 프로세스로 판정합니다. P6 뒤 기존 runner는 1,664행·4함수, `_run()` 1,638행·336 assertion이고 이동 fixture 참조는 0건입니다.

1. 메뉴 장면 `139~180` 42행·12 assertion은 한 메뉴 인스턴스의 페이지 전이라 작고 응집되어 현 위치를 유지합니다.
2. 메인 게임 `184~1655` 1,472행·324 assertion은 한 `GameController`의 순차 전투 상태를 재사용하므로 시나리오 내부를 기계 분리하지 않습니다.
3. 추가 runner 책임 이동은 현재 중단합니다. 다음 신뢰성 후보는 Godot 프로세스가 성공/실패 종료를 호출하지 못할 때 품질 게이트가 무기한 대기하지 않도록 단계별 실행 시간 상한과 timeout 위반을 추가하는 것입니다.

P7에서는 기존 `Invoke-GodotStage`가 `& $Executable` 동기 호출의 반환만 기다려, GDScript 오류로 scene의 `get_tree().quit()`까지 도달하지 못하면 품질 게이트 자체가 끝나지 않는 위험을 확인했습니다. `StageTimeoutSeconds`를 기본 120초·허용 1~3600초로 추가하고, 각 단계를 shell 없이 `System.Diagnostics.Process`로 직접 시작하는 `Invoke-BoundedProcess` 경계로 교체했습니다. stdout/stderr는 비동기로 끝까지 수집해 pipe 포화 교착을 피하고, 상한 초과 시 프로세스 트리 종료를 우선 시도한 뒤 단일 프로세스 종료로 호환 폴백합니다.

timeout 단계는 exit `-1`과 `nonzero_exit`, `timeout` 위반을 반환하며 JSON stage에 `timed_out`, `timeout_seconds`, `elapsed_ms`를 기록합니다. selftest는 timeout evaluator를 추가한 13개 사례와 현재 PowerShell 자식의 실제 3초 sleep을 1초에 종료하는 bounded-process probe를 함께 실행합니다. 실제 Godot parse에 1초 상한을 적용한 음성 검사는 1.053초에 `nonzero_exit, timeout`으로 실패하고 비0 종료했으며 보고서 `20260830_234015_561_26160/summary.json`에 같은 진단이 저장됐습니다.

기본 120초 전체 7단계는 모두 종료 코드 0으로 다시 통과했고 가장 긴 smoke 단계는 14.838초, timeout은 0건입니다. 정상 보고서는 `20260830_234037_353_22132/summary.json`입니다. 품질 게이트는 343행·6함수가 됐고 구현 동결 계약이 시간 상한·bounded process·timeout 분류·실제 probe 문자열을 고정합니다. 현재 자동 내부 구조·스모크 신뢰성 백로그에는 즉시 구현할 다음 항목이 없습니다.

Android M7 실기기 표본과 제품 식별자·릴리스 키 결정은 계속 별도 외부 입력 트랙입니다.

## 7. 구현 검증

- 최초 감사에서 실제 함수 시작점과 행 수, assertion·suite·await·객체 생성/정리, 파일·Autoload 접근을 정적으로 계측했습니다.
- `ImplementationFreezeContractTest`가 신규 scene·runner·품질 게이트 경로, 메타 fixture의 기존 runner 제거, 정확한 성공 표식을 고정합니다.
- PowerShell 구문 검사와 현재 `selftest` 12개 판정 사례가 통과했습니다.
- `-Mode content` 단독 실행이 종료 코드 0과 정확한 `CONTENT ELECTION SMOKE PASS`로 통과했습니다.
- `-Mode meta` 단독 실행이 종료 코드 0과 정확한 `META PERSISTENCE SMOKE PASS`로 통과했습니다.
- 현재 `full` 진입점의 Godot 4.7 파싱→콘텐츠·선거→메타 지속성→출격 준비→전체 `SMOKE TEST PASS`→튜토리얼 `TUTORIAL RUNTIME SMOKE PASS`→verbose 전체 스모크 일곱 단계가 모두 종료 코드 0이며 금지 오류·ObjectDB/리소스/StringName 누수는 0건입니다.
- P3 계약 이동 뒤에도 같은 6단계 게이트와 `selftest` 11개 사례가 모두 통과했으며 최신 보고서의 여섯 stage `violations`는 모두 빈 배열입니다.
- P4 고유 계약 이동과 중복 3개 제거 뒤에도 Godot 4.7 파싱, `selftest` 11개, 같은 6단계 전체 게이트가 통과했고 모든 stage의 오류·누수 위반은 0건입니다.
- P5 카탈로그·편대·성장·메트릭 계약 이동과 중복 9개 제거 뒤에도 Godot 4.7 파싱, `selftest` 11개, 같은 6단계 전체 게이트가 모두 종료 코드 0으로 통과했습니다. 최신 보고서는 `20260830_232300_545_11932/summary.json`이며 모든 stage의 오류·누수 위반은 0건입니다.
- P6 출격 준비 프로세스 격리 뒤 Godot 4.7 파싱, 단독 `preparation`, `selftest` 12개와 파싱→콘텐츠·선거→메타→출격 준비→전체 스모크→튜토리얼→verbose 스모크의 7단계 전체 게이트가 모두 종료 코드 0으로 통과했습니다. 최신 보고서는 `20260830_233026_382_28532/summary.json`이며 모든 stage의 오류·누수 위반은 0건입니다.
- P7 시간 상한 뒤 PowerShell 파싱, timeout evaluator를 포함한 13개 사례, 실제 bounded-process probe, Godot parse 1초 강제 timeout, 기본 120초 전체 7단계를 검증했습니다. 강제 timeout은 의도대로 비0, 정상 전체는 종료 코드 0이며 오류·누수·timeout 위반은 0건입니다.
