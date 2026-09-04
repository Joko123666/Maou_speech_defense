class_name ControlResistanceProfileData
extends Resource

## 모든 보스 제어기가 공유하는 재적용 저항 계약입니다. 실제 효과 감소율은
## EnemyData의 기존 status/knockback_resistance와 결합해 한 경로에서 계산합니다.
@export var recovery_seconds: Dictionary = {
	&"displacement": 0.8,
	&"slow": 0.65,
	&"fear": 1.0,
	&"stun": 1.4,
	&"charm": 2.0,
}
@export_range(0.01, 1.0, 0.01) var minimum_effect_ratio: float = 0.1
@export_range(0.01, 1.0, 0.01) var minimum_duration_ratio: float = 0.15

func recovery_for(control_type: StringName) -> float:
	return maxf(float(recovery_seconds.get(control_family(control_type), 0.0)), 0.0)

func effect_ratio(control_type: StringName, status_resistance: float, knockback_resistance: float) -> float:
	var resistance := knockback_resistance if control_family(control_type) == &"displacement" else status_resistance
	return maxf(1.0 - clampf(resistance, 0.0, 0.95), minimum_effect_ratio)

func duration_ratio(control_type: StringName, status_resistance: float) -> float:
	if control_family(control_type) == &"displacement":
		return 1.0
	return maxf(1.0 - clampf(status_resistance, 0.0, 0.95), minimum_duration_ratio)

func control_family(control_type: StringName) -> StringName:
	if control_type in [&"knockback", &"gather", &"forced_movement"]:
		return &"displacement"
	return control_type
