# 콘텐츠·텍스트 편집 가이드

활성 프로필은 `data/concepts/demon_election_vertical_slice.tres`입니다. 안정 ID는 저장 데이터와 테스트가 참조하므로 표시 문구나 수치를 바꿀 때 `id`는 변경하지 않습니다.

## 전투 콘텐츠

`data/concepts/demon_election_content_pack.tres`가 활성 전투 콘텐츠의 인덱스입니다. 실제 편집 파일은 `data/content/demon_election/` 아래에 역할별로 분리되어 있습니다.

| 폴더 | 편집 대상 |
|---|---|
| `cores/` | 후보 표시명·설명·기본 공격·필살 공약 수치 |
| `cursors/` | 심복 표시명·설명·이동·공격·회수 수치 |
| `towers/` | 일반 병력·친위대 표시명·설명·전투 수치 |
| `formations/` | 편대 표시명·배치 셀·편성점수·태그 |
| `tower_branches/` | 병종별 Lv.4/Lv.7 분기 이름과 수정치 |
| `specializations/` | 후보·심복·상태 특화 이름과 수정치 |
| `enemies/`, `bosses/` | 난입자·보스 표시명과 전투 수치 |
| `spawn_profiles/` | 적 역할·팩션·스폰 예산 메타데이터 |

Godot Inspector에서 개별 `.tres`를 열어 편집합니다. 팩 검증은 중복 ID, 끊어진 참조, 편대 셀과 점수, 스폰 프로필, 스테이지·보상표 연결을 검사합니다.

`tools/export_builtin_content_pack.tscn`은 과거 코드 빌더 기준으로 전체 팩을 다시 생성하는 마이그레이션 도구입니다. 실행하면 수동 편집값을 덮어쓰므로 일반 편집 과정에서는 사용하지 않습니다.

## UI 텍스트

- 선거 콘셉트: `data/concepts/demon_election_texts.tres`
- 호환 콘셉트: `data/concepts/formation_defense_texts.tres`

`entries`의 의미 키는 코드가 조회하므로 이름을 바꾸지 않습니다. `{candidate}`, `{skill}` 같은 토큰을 추가·삭제할 때는 같은 파일의 `placeholder_contracts`도 정확히 맞춥니다. 토큰이 누락된 호출은 평문 fallback을 사용하며, fallback도 해결할 수 없으면 의미 키를 표시하고 경고를 남깁니다.

## 검증

```powershell
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe' --headless --path . res://tests/content_election_runtime_smoke.tscn
& tools/run_headless_quality_gate.ps1
```

문구 변경은 콘텐츠 테스트와 UI 스냅샷을 함께 확인합니다. 수치 변경은 전체 품질 게이트 뒤 관련 밸런스 감사도 별도로 실행합니다.
