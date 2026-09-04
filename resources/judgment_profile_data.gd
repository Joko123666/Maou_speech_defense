class_name JudgmentProfileData
extends Resource

@export_range(1, 10, 1) var required_sentence_stacks: int = 3
@export_range(0.1, 30.0, 0.1) var sentence_duration: float = 6.0
@export_range(0.0, 0.95, 0.01) var execute_health_ratio: float = 0.12
@export_range(0.0, 0.5, 0.005) var boss_fixed_health_ratio: float = 0.045
@export var execution_profile: ExecutionProfileData = ExecutionProfileData.new()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if required_sentence_stacks <= 0:
		errors.append("judgment required sentence stacks must be positive")
	if sentence_duration <= 0.0:
		errors.append("judgment sentence duration must be positive")
	if execute_health_ratio <= 0.0:
		errors.append("judgment execute health ratio must be positive")
	if boss_fixed_health_ratio <= 0.0:
		errors.append("judgment boss fixed health ratio must be positive")
	if execution_profile == null:
		errors.append("judgment execution profile is required")
	else:
		errors.append_array(execution_profile.get_validation_errors())
	return errors
