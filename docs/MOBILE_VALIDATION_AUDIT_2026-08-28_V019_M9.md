# GDD v0.19 M9 모바일·배포 검증 감사

- 검증일: 2026-08-28 (Asia/Seoul)
- 기준: `godot_formation_defense_gdd_v0_19.md`, `docs/GDD_V0_19_IMPROVEMENT_PLAN.md`
- 엔진: Godot 4.7 stable, Mobile renderer, 1280×720 landscape
- 판정: **기술 준비 부분 승인 / Android·iOS 실기기 및 릴리스 배포 최종 승인 보류**

## 1. 결론

프로젝트는 Android 디버그 APK를 재현 가능하게 만들고, 모바일 기준 UI·터치 계약과 Forward Mobile 장시간 성능 게이트를 통과했다. 이번 검증에서 아티팩트 상세 버튼을 48px 터치 타깃으로 보강하고 Android 내보내기에서 `tests/*`를 제외했다.

다만 연결된 Android 실기기와 로컬 에뮬레이터가 없어서 설치·첫 실행·실제 터치·안전영역·뒤로가기·발열·메모리·배터리·스피커를 측정하지 못했다. 릴리스 키도 없고 패키지 ID·앱 아이콘·버전 메타데이터가 제품 확정값이 아니며, Windows 호스트에는 iOS 빌드 환경과 iOS 프리셋이 없다. 따라서 M9 전체 완료나 스토어 제출 가능 상태로 판정하지 않는다.

## 2. 검증 환경

| 항목 | 결과 |
|---|---|
| Godot | 4.7 stable export template 설치 확인 |
| Android SDK | platform/build-tools 36.1, `adb` 사용 가능 |
| Android 대상 | 연결 실기기 0대, 설치된 에뮬레이터/AVD 없음 |
| iOS 대상 | Windows 호스트, `xcodebuild` 없음, iOS export preset 없음 |
| 렌더 경로 | D3D12 Forward Mobile, NVIDIA GeForce RTX 5060 Laptop GPU |

Forward Mobile 결과는 렌더 경로와 프로젝트 성능 예산을 검증하는 대체 표본일 뿐 모바일 SoC의 CPU/GPU·발열 승인을 대신하지 않는다.

## 3. UI·입력 검증

UI 스냅샷 러너가 1280×720 화면 78장을 생성했고 종료 코드 0을 기록했다. 다음 대표 화면을 원본 해상도로 직접 확인했다.

- `artifact_hud.png`, `artifact_hud_details.png`: 6칸 HUD, 48px 상세 버튼, 확장 패널의 잘림·겹침 없음
- `artifact_choices.png`, `artifact_replacement.png`: 단일 아티팩트 카드, 6개 교체 슬롯과 50px 포기 버튼의 잘림·겹침 없음
- `tutorial_movement.png`, `gameplay_hud.png`: 목적지 지정 안내와 전투 HUD 경계 정상
- `result_screen.png`, `result_screen_defeat.png`: 승리·패배 결과 화면 경계 정상

전체 스모크는 목적지 터치/드래그의 카메라 좌표 변환, 화면 배속 버튼, 3×에서 180Hz 물리 틱, 48px 일시정지·하단 패널·아티팩트 상세 타깃과 교체/포기 흐름을 포함해 `SMOKE TEST PASS`를 기록했다. 종료 시 기존 ObjectDB/리소스 잔존 경고는 있었지만 계약 또는 게임플레이 실패는 없었다.

실제 손가락 오조작률, OS 제스처·노치/펀치홀 안전영역, Android 뒤로가기와 앱 중단/복귀는 실기기에서 별도로 확인해야 한다.

## 4. Android 패키지 검증

유효한 디버그 산출물:

- 경로: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_m9_debug.apk`
- 크기: 102,349,169 bytes (약 97.61 MiB)
- 이전 139,170,718 bytes 대비 36,821,549 bytes, 26.46% 감소
- ABI: `arm64-v8a`만 포함
- Android: min SDK 24, target/compile SDK 36
- 화면: landscape, immersive mode
- 렌더러: Godot Mobile; GLES 3 필수, Vulkan 기능 선택
- 서명: Godot 디버그 인증서, APK Signature Scheme v2/v3 검증 통과
- 권한: 네트워크·위치·카메라·마이크 등 불필요한 앱 권한 없음
- 패키지 내 `tests/` 항목: 0개

현재 제품 배포 차단 항목:

- 패키지 ID가 `com.example.td_survival`인 예시 값이다.
- 버전 코드/이름이 `1`/`1.0.0` 기본값이고 앱 표시명도 제품 승인값으로 명시되지 않았다.
- 런처 아이콘이 별도 Android 자산 없이 기본 Godot `icon.svg`를 사용하며 themed icon 경로가 없다.
- 릴리스 키 저장소가 없어 release export가 실패했다.
- 실패 과정에서 생성된 `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_m9_release.apk`는 `Missing META-INF/MANIFEST.MF`로 서명 검증에 실패하는 불완전 파일이다. 배포하면 안 된다.

## 5. 장시간 Forward Mobile 성능

동일한 `judgment_vanguard`, 평균 빌드/평균 숙련, Bonus disabled, 아티팩트 normal, 3×/180Hz 조건으로 실제 창 렌더 감사를 실행했다.

| 구간 | 게임 시간 | 평균 프레임 | 최악 프레임 | 33ms 초과 | 적/투사체/효과 피크 | 효과 예산 드롭 | 판정 |
|---|---:|---:|---:|---:|---|---:|---|
| 단기 | 120.02초 | 5.579ms | 16.667ms | 0% | 12 / 4 / 23 | 0 | 통과 |
| 장기 | 482.53초 | 5.561ms | 16.667ms | 0% | 58 / 6 / 39 | 1,373 | 통과 |

장기 실행은 600초 상한 전에 패배로 종료됐다. 3× 효과 활성 한도 40 아래에서 피크 39를 유지했고, 저우선순위 효과 1,373개를 의도적으로 생략하면서 성능 위반 0건을 기록했다. 이는 효과 예산의 작동을 확인하지만 실제 모바일 GPU의 프레임과 발열을 승인하지는 않는다.

## 6. 최종 승인 전 필수 실기기 체크리스트

1. 최소 사양 Android arm64 기기와 대표 중급 기기에 디버그/릴리스 후보를 설치하고 첫 실행·재실행·업데이트를 확인한다.
2. 노치/펀치홀/제스처 내비게이션에서 메뉴, HUD 6칸, 교체 모달, 일시정지, 결과 화면의 안전영역을 확인한다.
3. 이동 터치/드래그, 후보 액티브, 배속, 사거리, 카드 선택, 교체/포기, 뒤로가기와 앱 중단/복귀를 손으로 검증한다.
4. 1×와 3×를 각각 10분 실행해 평균/최악 프레임, 33ms 초과율, 최고 온도, 메모리, 배터리 감소와 스피커 왜곡을 기록한다.
5. 제품 패키지 ID·앱 이름·버전 정책·런처/적응형/단색 아이콘과 릴리스 키를 확정한 뒤 서명된 release APK/AAB를 다시 검증한다.
6. macOS/Xcode 환경에서 iOS preset, 번들 ID, 서명과 실기기 안전영역·성능을 별도 승인한다.

## 7. 재현 명령 요약

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --audio-driver Dummy res://tests/smoke_test.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --path . --audio-driver Dummy res://tests/ui_snapshot.tscn
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-debug Android 'C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_m9_debug.apk'
```
