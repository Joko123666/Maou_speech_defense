# 캐릭터 리소스 M7 Android 실기기 검증 준비

- 기준일: 2026-08-29
- 범위: v0.19 캐릭터 갱신 M6 활성 자산의 Android 패키지·실기기 검증 준비
- 판정: **디버그 패키지·수집 도구 준비 완료 / 연결 Android 실기기 0대로 최종 승인 보류**

## 1. 이번 개선 결과

M6에서 활성 경로로 복사한 캐릭터 54개와 동일한 1254px 검수·파생 원본 56개가 `all_resources` Android 내보내기에 중복 포함될 수 있는 문제를 확인했다. 런타임은 안정 정식 경로만 사용하므로 `export_presets.cfg`에서 다음 비런타임 경로를 제외했다.

- `tests/*`
- `assets/graphics/style_refresh_v019/*`
- `tools/*`

내보내기 전후 동일한 Godot 4.7 Android arm64 디버그 APK를 비교한 결과는 다음과 같다.

| 항목 | 제외 전 | 제외 후 | 변화 |
|---|---:|---:|---:|
| APK bytes | 100,478,360 | 87,628,100 | -12,850,260 |
| APK MiB | 95.82 | 83.57 | -12.79% |

최적화 APK의 ZIP 항목을 검사해 활성 캐릭터 import 54개가 모두 존재하고, `style_refresh_v019`, `tests`, `tools` 항목은 각각 0개이며 `arm64-v8a/libgodot_android.so` 1개 외 다른 ABI 라이브러리가 없음을 확인했다. 활성 캐릭터는 안정 정식 경로에 있으므로 전체 스모크와 M6 자산 계약을 그대로 유지한다.

## 2. 최신 디버그 APK

- 경로: `C:\Users\USER\Documents\GodotGames\Output\TD_survival_v019_character_m7_debug.apk`
- 크기: 87,628,100 bytes, 83.57 MiB
- 패키지: `com.example.td_survival` — 제품 ID가 아닌 기존 예시 값
- ABI: arm64-v8a 전용
- Android: min SDK 24, target/compile SDK 36
- 서명: Godot 디버그 인증서, APK Signature Scheme v2/v3 검증 통과
- 상태: 개발·실기기 검증용이며 스토어 제출용 릴리스 산출물이 아님

제품 패키지 ID, 앱 이름·버전 정책, 런처/적응형/단색 아이콘, 릴리스 키와 AAB 목표 형식은 사용자 결정이 필요한 기존 배포 차단 항목으로 유지한다.

## 3. 재현 가능한 실기기 수집 도구

`tools/android_character_m7_validation.ps1`은 Godot·SDK·ADB 사전 점검, 디버그 빌드·v2/v3 서명 확인, 설치·실행과 실기기 증거 수집을 같은 절차로 수행한다. 여러 기기가 연결되면 `-DeviceSerial`을 요구해 잘못된 기기에 설치하지 않으며, 성공 시 종료 코드 0을 명시적으로 반환한다.

수집 항목:

- 시작·종료 스크린샷
- `gfxinfo framestats`와 평균/최악 프레임, 16/33ms 초과 수
- 시작·종료 Total PSS 메모리
- 시작·종료 배터리 잔량
- 종료 시 thermal service 상태
- 전체 구간 logcat과 기기 속성
- 방향·팩션·48/64/96px 판독성·팝인·감소 모션 수동 판정표

산출물은 `C:\Users\USER\Documents\GodotGames\Output\m7_device_reports\<시각>_<label>\`에 저장된다.

## 4. 연결 기기에서 실행할 명령

프로젝트 루트에서 실행한다.

```powershell
& '.\tools\android_character_m7_validation.ps1' -Mode preflight
& '.\tools\android_character_m7_validation.ps1' -Mode build
& '.\tools\android_character_m7_validation.ps1' -Mode full -Label startup_and_safe_area -SampleSeconds 120
```

설치 후 해당 전투 상태로 직접 이동해 다음 표본을 각각 수집한다.

```powershell
& '.\tools\android_character_m7_validation.ps1' -Mode collect -Label combat_1x -SampleSeconds 600
& '.\tools\android_character_m7_validation.ps1' -Mode collect -Label combat_3x -SampleSeconds 600
& '.\tools\android_character_m7_validation.ps1' -Mode collect -Label prelude_to_boss_transition -SampleSeconds 180
& '.\tools\android_character_m7_validation.ps1' -Mode collect -Label reduced_motion_3x -SampleSeconds 600
```

## 5. 남은 승인 게이트

현재 ADB 사전 점검 결과 승인된 연결 기기는 0대다. 다음 항목은 데스크톱 Forward Mobile이나 APK 생성 성공으로 대체하지 않는다.

1. 최소 사양 arm64 Android와 대표 중급 기기에서 설치·첫 실행·재실행·업데이트
2. 노치·펀치홀·제스처 내비게이션의 실제 safe inset과 뒤로가기·중단/복귀
3. 아군 우향·공식 난입 좌향, 팩션·역할의 48/64/96px 오인 표본 0
4. 1×/3× 혼잡 전투와 Prelude→보스에서 텍스처 팝인·과도한 프레임 드롭 0
5. 10분 표본의 메모리, 최고 온도, 배터리 감소와 스피커 왜곡 승인

위 실기기 표본이 모두 수집·승인될 때만 캐릭터 리소스 M7을 완료로 전환한다.
