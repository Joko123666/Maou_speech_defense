class_name TowerData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var behavior: StringName = &"rapid"
@export var target_rule: StringName = &"closest_core"
@export var damage: float = 10.0
@export var attack_interval: float = 1.0
@export var attack_range: float = 1000.0
@export var attack_range_cells: float = 1.5
## 네트워크형 수비병력의 중계점 간 기본 연결 거리입니다. 일반 공격 사거리와 분리합니다.
@export var link_range_cells: float = 0.0
@export var area_radius: float = 0.0
@export var status_power: float = 0.0
@export var max_level: int = 7
@export var has_base_gimmick: bool = false
@export var base_gimmick_id: StringName
@export var color: Color = Color("7ec8ff")
@export var tags: Array[StringName] = []
## 활성 선거 캠페인에서 도감에 표시할 출신 진영입니다. 비어 있으면 등록 용병·임대 장비로 표시합니다.
@export var origin_faction_id: StringName = &""
@export var technology_name: String = ""
@export var texture: Texture2D
## 공격 확정 직후 잠시 표시할 전용 포즈입니다. 누락되면 `texture`를 계속 사용합니다.
@export var attack_texture: Texture2D
## 활성 콘셉트 카탈로그의 `projectiles/{id}`를 조회합니다. 비어 있거나 누락되면 기존 행동별 폴백을 사용합니다.
@export var projectile_texture_id: StringName
@export var unique_core_id: StringName
@export var reactivation_profile: RetainerReactivationProfileData
## 단일 대상 DPS뿐 아니라 광역 적중 수, 제어, 표식, 보상 기여를 포함한 편대 구성용 기대값입니다.
@export var formation_power_rating: float = 100.0

func is_unique() -> bool:
	return unique_core_id != &""
