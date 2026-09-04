class_name VanguardStackProfileData
extends Resource

@export_range(1, 12, 1) var maximum_members: int = 3
@export_range(1, 12, 1) var minimum_members: int = 1
@export_range(0.05, 1.0, 0.01) var damage_per_member: float = 0.333333
@export_range(0.01, 0.5, 0.01) var execution_health_ratio: float = 0.12
@export_range(0.1, 30.0, 0.1) var reinforcement_seconds: float = 5.5

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if maximum_members <= 0: errors.append("vanguard maximum members must be positive")
	if minimum_members <= 0 or minimum_members > maximum_members: errors.append("vanguard minimum members must be within the squad range")
	if damage_per_member <= 0.0: errors.append("vanguard member damage contribution must be positive")
	if execution_health_ratio <= 0.0 or execution_health_ratio >= 1.0: errors.append("vanguard execution ratio must be between zero and one")
	if reinforcement_seconds <= 0.0: errors.append("vanguard reinforcement time must be positive")
	return errors
