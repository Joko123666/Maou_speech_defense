class_name EnemyMovementProfileData
extends Resource

@export var kind: StringName = &"direct"
@export_range(0.0, 1.0, 0.01) var destination_offset_min: float = 0.22
@export_range(0.0, 1.0, 0.01) var destination_offset_max: float = 0.38

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if kind not in [&"direct", &"fixed_diagonal"]:
		errors.append("enemy movement profile has unsupported kind '%s'" % kind)
	if destination_offset_min < 0.0 or destination_offset_max < destination_offset_min:
		errors.append("enemy movement profile has an invalid destination offset range")
	return errors
