# 후보·심복 전투 SD 수직 절편 — 2026-08-09

## 범위

후보·심복 10종 전체에 생성·투명화·최적화·카탈로그·런타임 표시·검증 파이프라인을 적용한다. 기본, 환혹, 심연, 사령, 심판의 다섯 기본 조합이 모두 전용 전투 SD를 사용한다.

## 제작 결과

| 역할 | 설정 ID | 원본 참고 | 최종 리소스 | 전투 표시 |
|---|---|---|---|---|
| 후보 | `partason` | `candidates/partason.png` | `combat_sd/candidates/partason.png` | 에메랄드 핵 위 |
| 심복 | `kanda` | `retainers/kanda.png` | `combat_sd/retainers/kanda.png` | 철갑 목표지점 위 |
| 후보 | `jiane` | `candidates/jiane.png` | `combat_sd/candidates/jiane.png` | 사파이어 핵 위 |
| 심복 | `given` | `retainers/given.png` | `combat_sd/retainers/given.png` | 실버 목표지점 위 |
| 후보 | `kasuha` | `candidates/kasuha.png` | `combat_sd/candidates/kasuha.png` | 아메지스트 핵 위 |
| 심복 | `jeomujeom` | `retainers/jeomujeom.png` | `combat_sd/retainers/jeomujeom.png` | 골드 목표지점 위 |
| 후보 | `irelai` | `candidates/irelai.png` | `combat_sd/candidates/irelai.png` | 제이드 핵 위 |
| 심복 | `jugdied` | `retainers/jugdied.png` | `combat_sd/retainers/jugdied.png` | 플래티넘 목표지점 위 |
| 후보 | `judaginda` | `candidates/judaginda.png` | `combat_sd/candidates/judaginda.png` | 옵시디언 핵 위 |
| 심복 | `death_vanguard` | `retainers/death_vanguard.png` | `combat_sd/retainers/death_vanguard.png` | 뱅가드 목표지점 위 |

- 내장 이미지 생성으로 기존 초상의 얼굴·뿔·갑옷·진영색을 유지한 2.5등신 캐주얼 2.5D 전신을 생성했다.
- 생성 원본은 균일 녹색 크로마키를 사용했고 공식 `remove_chroma_key.py`의 soft matte·despill로 투명화했다.
- 최종 PNG는 모바일 표시 크기에 맞춰 512×512 RGBA로 축소했다. 파일 크기는 파르태손 324,552바이트, 칸다 271,480바이트, 지아느 258,569바이트, 기븐 232,829바이트, 카스하 257,690바이트, 저므조므 307,457바이트, 이레라이 287,085바이트, 주그디에드 246,393바이트, 주다긴다 265,206바이트, 돌격부대 257,810바이트이다.
- 열 파일 모두 네 모서리 알파가 0이고 시각 검사에서 녹색 테두리나 잘린 무기·신체가 없다.

## 프롬프트 규격

- 파르태손: 기존 초상을 정체성 참고로 사용하고 검게 쓸어 넘긴 머리, 대칭 뿔, 호박색 눈, 뾰족귀, 적금색 중갑과 에메랄드 결정광을 유지한 무기 없는 지휘 대기 자세.
- 칸다: 기존 초상을 정체성 참고로 사용하고 짧은 흑회색 머리, 짧은 두 뿔, 호박색 눈, 왼쪽 눈 흉터, 적색·건메탈 중갑과 에메랄드 등을 유지한 방어 대기 자세.
- 지아느: 기존 초상을 정체성 참고로 사용하고 긴 보랏빛 머리, 굽은 두 뿔, 자홍색 눈, 별 모양 보석, 금색 테두리의 자홍·보라 갑옷을 유지한 환혹 시전 자세.
- 기븐: 기존 초상을 정체성 참고로 사용하고 비대칭 라벤더 머리와 회색 언더컷, 짧은 두 뿔, 보라색 눈, 사슬과 원형 장식의 검은 갑옷, 자홍 균열광을 유지한 짧은 채찍 제어 자세.
- 카스하: 기존 초상을 정체성 참고로 사용하고 긴 남청색 머리, 높게 뻗은 두 뿔, 청록색 눈과 얼굴 균열, 금색 테두리의 남청 갑옷과 다이아 결정을 유지한 양손 응축 폭발 준비 자세.
- 저므조므: 기존 초상을 정체성 참고로 사용하고 뾰족한 후드 투구, 청록 단안, 무거운 남청·건메탈 갑주, 금색 테두리와 원형 발광 노드를 유지한 넓은 지역 제어 자세.
- 이레라이: 기존 초상을 정체성 참고로 사용하고 양 갈래 땋은 머리, 금동 사슴뿔 왕관, 녹색 눈과 보석, 옥색·금색 견갑과 중앙 등불을 유지한 세 사령 인장 지휘 자세.
- 주그디에드: 기존 초상을 정체성 참고로 사용하고 짧은 백발, 왕관형 검은 뿔, 녹색 눈과 얼굴 문양, 검은 기사 갑주와 은색 칼날 견갑, 옥색 흉부 결정을 유지한 무기 없는 전방 돌격 자세.
- 주다긴다: 기존 초상을 정체성 참고로 사용하고 검은 머리, 비대칭 뿔, 붉은 눈, 흑적 고갑, 은색 견갑, 종 문양을 유지한 무기 없는 전투 대기 자세.
- 죽음교 돌격부대: 기존 초상을 정체성 참고로 사용하고 뿔 투구, 철 가면, 붉은 눈, 검은 갑옷, 붉은 스카프, 다이아 문양 장병기를 유지한 경계 행진 자세.
- 공통: 단일 캐릭터 전신, 2.5등신, 균일 `#00ff00`, 그림자·반사·문자·UI·워터마크 없음.

## 런타임 계약

- 선택 화면 초상과 전투 SD는 `candidates`/`retainers`와 `candidate_sd`/`retainer_sd`로 분리한다.
- `ConceptService.optional_content_texture()`는 알 수 없는 ID에 공용 폴백을 반환하지 않는다.
- SD가 있으면 기존 핵·목표지점 표식을 알파 기반 문양으로 남기고 캐릭터를 그 위에 표시한다. 체력·공격·회수 범위, 쿨다운·목적지 링과 입력 좌표는 바꾸지 않는다.
- `CombatCharacterArtContractTest`가 활성 선거 캠페인의 후보·심복 배열을 직접 순회해 10종 완전 커버리지, 512px 규격, 알파 포맷, 투명 모서리와 알 수 없는 ID의 명시적 부재를 검사한다.

## 검증

- Godot 4.7 헤드리스 에디터 종료 코드 0.
- `tests/smoke_test.tscn`: `SMOKE TEST PASS`.
- Forward Mobile UI 스냅샷 종료 코드 0.
- `demon_election_irelai_jugdied_combat.png`를 직접 확인해 이레라이는 좌측 제이드 핵 판정 안쪽, 주그디에드는 중앙 플래티넘 목표지점 링 안쪽에서 읽히고 HUD·입력 영역을 침범하지 않음을 확인했다.
- `demon_election_combo_reconstruction.png`에서 주그디에드 SD가 재구성 중 기존 붕괴 상태로 전환되어 뼈 조각과 재구성 타이머를 가리지 않음을 확인했다.
- `demon_election_kasuha_jeomujeom_combat.png`를 직접 확인해 카스하는 좌측 아메지스트 핵 판정 안쪽, 저므조므는 중앙 골드 목표지점 링 안쪽에서 읽히고 HUD·입력 영역을 침범하지 않음을 확인했다.
- `demon_election_jiane_given_combat.png`를 직접 확인해 지아느는 좌측 사파이어 핵 판정 안쪽, 기븐은 중앙 실버 목표지점 링 안쪽에서 읽히고 HUD·입력 영역을 침범하지 않음을 확인했다.
- `demon_election_partason_kanda_combat.png`를 직접 확인해 파르태손은 좌측 핵 판정 안쪽, 칸다는 중앙 목표지점 링 안쪽에서 읽히고 HUD·입력 영역을 침범하지 않음을 확인했다.

## 후속 작업

- 후보 선택·보스 진입·안내 공약·결과 음성은 별도 오디오 승인 대상으로 남긴다.
- 실제 모바일 기기에서 1×/3× 전투 가독성, 프레임, 발열과 스피커 음량을 승인한다.
