class_name CandidateDecreeData
extends Resource

const ALLOWED_STAT_KEYS: Array[StringName] = [
	&"tower_damage", &"tower_speed", &"core_damage", &"core_health",
	&"core_skill_damage", &"core_attack_speed", &"skill_charge",
	&"cursor_damage", &"cursor_attack_speed", &"cursor_area",
	&"cursor_control", &"cursor_movement",
]

@export var id: StringName = &""
@export var candidate_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_summary: String = ""
@export var stat_multipliers: Dictionary = {}

func multiplier(stat_key: StringName) -> float:
	return maxf(float(stat_multipliers.get(stat_key, 1.0)), 0.01)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("candidate decree id is empty")
	if candidate_id == &"": errors.append("candidate decree '%s' has no candidate id" % id)
	if display_name.is_empty(): errors.append("candidate decree '%s' has no display name" % id)
	if description.is_empty(): errors.append("candidate decree '%s' has no description" % id)
	if effect_summary.is_empty(): errors.append("candidate decree '%s' has no effect summary" % id)
	var has_benefit := false
	var has_tradeoff := false
	for key_value in stat_multipliers:
		var key := StringName(key_value)
		var value: Variant = stat_multipliers[key_value]
		if key not in ALLOWED_STAT_KEYS:
			errors.append("candidate decree '%s' uses unsupported stat '%s'" % [id, key])
			continue
		if value is not int and value is not float:
			errors.append("candidate decree '%s' stat '%s' is not numeric" % [id, key])
			continue
		var multiplier_value := float(value)
		if multiplier_value < 0.5 or multiplier_value > 1.75:
			errors.append("candidate decree '%s' stat '%s' is outside 0.50..1.75" % [id, key])
		has_benefit = has_benefit or multiplier_value > 1.0
		has_tradeoff = has_tradeoff or multiplier_value < 1.0
	if not has_benefit or not has_tradeoff:
		errors.append("candidate decree '%s' must contain both a benefit and a tradeoff" % id)
	return errors
