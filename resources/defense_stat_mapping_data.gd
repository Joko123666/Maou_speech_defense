class_name DefenseStatMappingData
extends Resource

const MULTIPLIER_MODE := &"multiplier"
const FIXED_MODE := &"fixed"

@export var tower_id: StringName
@export var axis_id: StringName
@export var display_name: String
@export var modifier_keys: Array[StringName] = []
@export var value_mode: StringName = MULTIPLIER_MODE
@export var cap: float = 2.0
@export var applies_to_guard: bool = true
@export var allowed_target_kinds: Array[StringName] = [&"normal_defender"]

func supports(modifier_key: StringName, target_kind: StringName, is_guard: bool) -> bool:
	return modifier_key in modifier_keys and target_kind in allowed_target_kinds and (not is_guard or applies_to_guard)

func primary_modifier_key() -> StringName:
	return modifier_keys[0] if not modifier_keys.is_empty() else &""

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if tower_id == &"": errors.append("defense stat mapping has no tower id")
	if axis_id not in [&"power", &"speed", &"range"]: errors.append("tower '%s' has unknown axis '%s'" % [tower_id, axis_id])
	if display_name.strip_edges().is_empty(): errors.append("tower '%s' axis '%s' has no display name" % [tower_id, axis_id])
	if modifier_keys.is_empty(): errors.append("tower '%s' axis '%s' has no modifier keys" % [tower_id, axis_id])
	if value_mode not in [MULTIPLIER_MODE, FIXED_MODE]: errors.append("tower '%s' axis '%s' has invalid value mode '%s'" % [tower_id, axis_id, value_mode])
	if cap <= 0.0: errors.append("tower '%s' axis '%s' has a non-positive cap" % [tower_id, axis_id])
	if allowed_target_kinds.is_empty(): errors.append("tower '%s' axis '%s' has no allowed target kinds" % [tower_id, axis_id])
	return errors
