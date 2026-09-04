class_name ComboAttackProfileData
extends Resource

@export var combo_type: StringName = &"line_charge"
@export_range(8.0, 160.0, 1.0) var path_half_width: float = 46.0
@export_range(0.05, 10.0, 0.05) var damage_multiplier: float = 2.5
@export_range(0.0, 300.0, 1.0) var knockback: float = 72.0
@export_range(0.1, 30.0, 0.1) var reconstruction_seconds: float = 5.0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if combo_type == &"": errors.append("combo attack type is empty")
	if path_half_width <= 0.0: errors.append("combo attack path half width must be positive")
	if damage_multiplier <= 0.0: errors.append("combo attack damage multiplier must be positive")
	if knockback < 0.0: errors.append("combo attack knockback cannot be negative")
	if reconstruction_seconds <= 0.0: errors.append("combo attack reconstruction time must be positive")
	return errors
