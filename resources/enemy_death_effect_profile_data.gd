class_name EnemyDeathEffectProfileData
extends Resource

@export var effect: StringName = &"none"
@export_range(0.0, 1000.0, 1.0) var radius: float = 0.0
@export_range(0.0, 30.0, 0.1) var duration: float = 0.0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if effect not in [&"none", &"disable_normal_defenders", &"disable_killer_normal_defender"]:
		errors.append("enemy death effect profile has unsupported effect '%s'" % effect)
	if effect == &"disable_normal_defenders" and (radius <= 0.0 or duration <= 0.0):
		errors.append("area defender-disable profile requires a positive radius and duration")
	if effect == &"disable_killer_normal_defender" and duration <= 0.0:
		errors.append("killer defender-disable profile requires a positive duration")
	return errors
