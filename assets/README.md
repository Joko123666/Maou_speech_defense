# TD Survival 에셋 구조

에셋은 생성 방식이나 버전이 아니라 런타임 역할을 기준으로 분류합니다. 코드와 씬에서는 아래 경로를 직접 참조합니다.

```text
assets/
├─ graphics/
│  ├─ backgrounds/   전장·메뉴 배경
│  ├─ cores/         방어 코어
│  ├─ cursors/       타깃 위치·등급 커서
│  ├─ enemies/       일반 적·특수 적·보스
│  ├─ projectiles/   타워 발사체
│  └─ towers/        공통·타입별 타워
└─ audio/
   ├─ combat/        타격·코어 피격
   ├─ gameplay/      코어 스킬·레벨업
   ├─ events/        보스·승리·패배
   └─ ui/            메뉴 조작음
```

## 운영 규칙

1. 새 파일은 실제 소비 기능에 해당하는 폴더에 추가합니다.
2. `generated`, `temp`, `v2` 같은 제작 과정·버전 이름은 폴더명으로 사용하지 않습니다.
3. 교체 가능한 시안의 버전은 소스 관리 이력이나 별도 작업 폴더에서 관리하고, 런타임 경로에는 승인된 파일만 둡니다.
4. 파일을 이동하면 `res://assets/...` 참조와 Godot import 상태를 함께 검증합니다.
5. 효과음은 `tools/generate_sfx.py`로 동일한 분류 구조에 재생성할 수 있습니다.
