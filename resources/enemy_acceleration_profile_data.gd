class_name EnemyAccelerationProfileData
extends Resource

@export_range(0.0, 1.0, 0.01) var speed_per_hit: float = 0.06
@export_range(1, 20, 1) var maximum_stacks: int = 5
@export_range(0.05, 20.0, 0.05) var duration: float = 2.5
@export_range(0.0, 5.0, 0.01) var internal_cooldown: float = 0.2

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if speed_per_hit <= 0.0 or maximum_stacks < 1 or duration <= 0.0 or internal_cooldown < 0.0:
		errors.append("enemy acceleration profile has invalid stack parameters")
	return errors
