class_name EnemyDecayProfileData
extends Resource

@export_range(1.0, 120.0, 0.5) var lifetime_seconds: float = 26.0

func get_health_loss_per_second(maximum_health: float) -> float:
	return maxf(maximum_health, 0.0) / maxf(lifetime_seconds, 0.01)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if lifetime_seconds <= 0.0:
		errors.append("enemy decay profile requires a positive lifetime")
	return errors
