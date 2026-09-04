class_name CharmProfileData
extends Resource

@export_range(0.0, 1.0, 0.01) var application_chance: float = 0.35
@export_range(0.1, 5.0, 0.05) var duration: float = 0.9
@export_range(0.1, 15.0, 0.1) var active_zone_duration: float = 6.0
@export_range(0.0, 10.0, 0.05) var reapplication_immunity: float = 1.25
@export_range(0.0, 0.8, 0.01) var boss_slow_power: float = 0.55
@export_range(0.0, 1.0, 0.01) var boss_vulnerability: float = 0.15

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if application_chance <= 0.0:
		errors.append("charm application chance must be positive")
	if duration <= 0.0:
		errors.append("charm duration must be positive")
	if reapplication_immunity < 0.0:
		errors.append("charm reapplication immunity cannot be negative")
	if boss_slow_power <= 0.0:
		errors.append("charm boss slow power must be positive")
	if boss_vulnerability <= 0.0:
		errors.append("charm boss vulnerability must be positive")
	return errors
