class_name EnemyGroupAccelerationProfileData
extends Resource

@export_range(0.0, 1.0, 0.01) var speed_per_ally_death: float = 0.08
@export_range(1, 20, 1) var maximum_stacks: int = 4
@export_range(0.05, 20.0, 0.05) var duration: float = 4.0
@export_range(0.0, 5.0, 0.01) var internal_cooldown: float = 0.0

func get_maximum_speed_bonus() -> float:
	return speed_per_ally_death * float(maximum_stacks)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if speed_per_ally_death <= 0.0 or maximum_stacks < 1 or duration <= 0.0 or internal_cooldown < 0.0:
		errors.append("enemy group acceleration profile has invalid stack parameters")
	if get_maximum_speed_bonus() > 1.0:
		errors.append("enemy group acceleration profile exceeds the 100 percent speed cap")
	return errors
