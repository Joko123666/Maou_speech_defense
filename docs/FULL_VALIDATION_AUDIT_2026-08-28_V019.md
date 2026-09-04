# GDD v0.19 전체 검증·빌드 가능성 감사

- 검증일: 2026-08-28 (Asia/Seoul)
- 엔진: Godot 4.7 stable
- 기준 소스: 현재 프로젝트와 `godot_formation_defense_gdd_v0_19.md`
- 종합 판정: **로컬 실행·Android 디버그 빌드 가능 / Android 릴리스·iOS·Windows 독립 배포 빌드 불가**

## 1. 판정 요약

| 대상 | 판정 | 근거 |
|---|---|---|
| Godot 에디터/Windows 로컬 실행 | 가능 | Forward Mobile 시작 씬 부팅 종료 코드 0 |
| Android arm64 디버그 APK | 가능 | 새 빌드 종료 코드 0, v2/v3 서명과 패키지 구조 검증 통과 |
| Android 릴리스 APK/AAB | 불가 | 릴리스 키스토어 없음, 제품 패키지/버전/아이콘 미확정, 현재 preset은 APK 형식 |
| Android 실기기 승인 | 미검증 | 연결 기기와 로컬 에뮬레이터 없음 |
| iOS 빌드 | 불가 | iOS preset 없음, Windows 호스트에 Xcode/서명 환경 없음 |
| Windows 독립 실행 파일 | 미구성 | Windows Desktop export preset 없음 |

Android 디버그 APK는 개발·내부 전달용으로 유효하다. 스토어 제출 또는 외부 릴리스 후보로는 승인하지 않는다.

## 2. 전체 회귀 검증

| 검증 | 결과 | 핵심 수치 |
|---|---|---|
| Godot 헤드리스 에디터 파싱·리소스 스캔 | 통과 | 종료 코드 0 |
| 전체 계약·게임플레이 스모크 | 통과 | `SMOKE TEST PASS`; 2026-08-29 후속 테스트 소유권 수정 뒤 ObjectDB·리소스 종료 경고 0 |
| 튜토리얼 실제 씬 흐름 | 통과 | `TUTORIAL RUNTIME SMOKE PASS` |
| 신규 계정 경제 감사 | 통과 | 첫 패배 +45, 첫 구매 3런, 5런 후 7/9, 완전 해금 예상 7런 |
| Forward Mobile UI 스냅샷 | 통과 | 78개 생성, 종료 코드 0 |
| 시작 씬 실제 렌더 부팅 | 통과 | D3D12 Forward Mobile, 종료 코드 0 |
| 60초 1×/2×/3× 등가성 | 통과 | 모두 Lv.5·XP 168·75킬, 불일치 0건 |
| 3×/180Hz 장시간 실제 렌더 | 통과 | 494.32초, 평균 5.561ms, 최악 16.667ms, 33ms 초과 0% |

UI는 `main_menu`, `gameplay_hud`, `tutorial_movement`, `level_up_choices`, `artifact_choices`, `artifact_replacement`, `artifact_hud_details`, `result_screen`, `result_screen_defeat` 9개 대표 화면을 1280×720 원본으로 직접 확인했다. 텍스트·버튼·패널의 잘림이나 겹침을 발견하지 않았다.

초기 전체 검증에서는 ObjectDB 134개·리소스 109개 종료 경고가 남았다. 2026-08-29 후속 개선에서 `V019M4DefenseStatContractTest`가 표현식 안에서 만든 `LoadoutManager`를 해제하지 않아 그 노드가 방어 능력축·초과성장·아티팩트 리소스를 연쇄 보유한 것이 원인임을 확인했다. 명시적 지역 변수와 `free()`로 소유권을 정리한 뒤 일반·`--verbose` 전체 스모크 모두 누수·잔존 리소스·Orphan StringName 보고 없이 종료 코드 0을 기록한다.

## 3. 장시간 성능 결과

조건은 `judgment_vanguard`, seed 99881, 평균 빌드/평균 숙련, Bonus disabled, artifact normal, 3×/180Hz, Forward Mobile 실제 창 렌더다.

| 항목 | 결과 |
|---|---:|
| 게임 시간 | 494.3167초, 패배 종료 |
| 레벨 / 처치 | Lv.28 / 1,192 |
| 보스 처치 / 최종 보스 도전 | 2 / 미도전 |
| 평균 / 최악 프레임 | 5.561ms / 16.667ms |
| 33ms 초과율 / 측정 프레임 | 0% / 29,672 |
| 적 / 투사체 / 효과 / 소환 피크 | 60 / 6 / 39 / 0 |
| 저우선순위 효과 예산 드롭 | 1,482 |
| 성능 예산 | 통과, 위반 0건 |

바로 앞의 같은 조건 실행도 종료 코드 0이었으나 485.70초·Lv.28·1,165킬로 종료됐다. 이전 M9 감사의 같은 조건은 482.53초·1,159킬이었다. 단기 60초 안정 지문은 완전히 일치하지만 실제 창 장기 결과는 약 2.4% 범위에서 변동했다. 따라서 실제 창 감사는 성능 회귀 판단에 사용하고, 정확한 장기 밸런스 재현성은 기존 격리 매트릭스 결과를 권위로 유지한다.

## 4. Android 디버그 APK 검수

- 산출물: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_full_validation_debug.apk`
- 크기: 102,349,169 bytes (약 97.61 MiB)
- SHA-256: `01D20B9C1042C5866F0A608B26E461CCC16B8F6C928CA0270A9E82A261D9ACAF`
- 패키지 항목: 874개, `project.binary` 1개, `assets/tests/*` 0개
- ABI: `arm64-v8a`의 `libgodot_android.so`, `libc++_shared.so`
- 서명: v1 미사용, APK Signature Scheme v2/v3 통과, Godot 디버그 인증서
- SDK: min 24, target/compile 36
- 화면: landscape, immersive mode
- 런처: exported activity alias, `MAIN`/`LAUNCHER` intent 존재
- 앱 권한 선언: 0개
- 렌더러: Godot Mobile, GLES 3 필수·Vulkan 기능 선택

## 5. 릴리스 차단 요소

1. `com.example.td_survival`은 제품 패키지 ID가 아닌 예시 값이다.
2. 버전 코드/이름은 `1`/`1.0.0` 기본값이고 앱 표시명도 제품 승인값으로 확정되지 않았다.
3. 별도 Android 런처·적응형·단색 아이콘 없이 기본 Godot `icon.svg`를 사용한다. 패키지 검사에서 themed icon 누락 경고가 발생한다.
4. 릴리스 키스토어가 없어 `--export-release Android`가 종료 코드 1로 실패한다.
5. 현재 Android preset의 export format은 APK이며 AAB 제출 구성이 아니다.
6. 실패 산출물 `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_m9_release.apk`는 100,444,717 bytes지만 `Missing META-INF/MANIFEST.MF`로 서명 검증에 실패한다. 배포하면 안 된다.
7. Android 실기기·에뮬레이터가 없어 설치, 첫 실행, 업데이트, 터치, 뒤로가기, 안전영역, 발열, 메모리, 배터리, 스피커를 승인하지 못했다.
8. iOS와 Windows Desktop export preset이 없고 현재 호스트에서는 iOS 서명 검증이 불가능하다.

## 6. 릴리스 빌드 전 필수 입력

- 제품 Android application ID와 iOS bundle ID
- 스토어 앱 이름, version code/name 정책
- Android 런처·adaptive foreground/background·monochrome 아이콘
- 안전하게 보관할 Android release keystore, alias와 암호 주입 방식
- APK 내부 배포와 AAB 스토어 제출 중 목표 형식
- 최소/대표 Android 실기기와 macOS/Xcode/iOS 실기기 환경

이 값이 확정되면 release preset을 완성하고 서명된 APK/AAB의 설치·업데이트·실기기 성능을 최종 승인할 수 있다.

## 7. 실행한 주요 명령

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --audio-driver Dummy res://tests/smoke_test.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --audio-driver Dummy res://tests/tutorial_runtime_smoke_test.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --audio-driver Dummy res://tests/economy_audit.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --path . --audio-driver Dummy res://tests/ui_snapshot.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-debug Android 'C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_full_validation_debug.apk'
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-release Android 'C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_m9_release.apk'
```
