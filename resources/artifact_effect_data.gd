class_name ArtifactEffectData
extends Resource

const MULTIPLIER_BONUS := &"multiplier_bonus"
const FIXED_BONUS := &"fixed_bonus"
const TARGET_GROUPS: Array[StringName] = [&"normal_defender", &"candidate", &"retainer", &"guard", &"status"]
const STAT_KEYS := {
	&"normal_defender": [&"power", &"speed", &"range"],
	&"candidate": [&"damage", &"skill"],
	&"retainer": [&"damage", &"action_speed", &"movement"],
	&"guard": [&"damage", &"action_speed", &"range"],
	&"status": [&"damage"],
}

@export var target_group: StringName
@export var stat_key: StringName
@export var axis_id: StringName = &""
@export var status_id: StringName = &""
@export var value_mode: StringName = MULTIPLIER_BONUS
@export var value: float = 0.0

func get_validation_errors(owner_id: StringName = &"") -> PackedStringArray:
	var errors := PackedStringArray()
	var prefix := "artifact '%s' effect" % owner_id
	if target_group not in TARGET_GROUPS: errors.append("%s has invalid target group '%s'" % [prefix, target_group])
	if stat_key == &"": errors.append("%s has no stat key" % prefix)
	elif target_group in STAT_KEYS and stat_key not in (STAT_KEYS[target_group] as Array): errors.append("%s has invalid stat key '%s' for '%s'" % [prefix, stat_key, target_group])
	if value_mode not in [MULTIPLIER_BONUS, FIXED_BONUS]: errors.append("%s has invalid value mode '%s'" % [prefix, value_mode])
	if is_zero_approx(value): errors.append("%s has a zero value" % prefix)
	if axis_id != &"" and axis_id not in DefenseStatCatalogData.REQUIRED_AXIS_IDS: errors.append("%s has invalid axis '%s'" % [prefix, axis_id])
	if target_group == &"normal_defender" and axis_id != stat_key: errors.append("%s must map its normal-defender stat to the matching defense axis" % prefix)
	if target_group != &"normal_defender" and axis_id != &"": errors.append("%s declares a defense axis outside the normal-defender target" % prefix)
	if target_group == &"status" and status_id not in CommonStatusCatalog.STATUS_IDS: errors.append("%s has invalid status '%s'" % [prefix, status_id])
	if target_group != &"status" and status_id != &"": errors.append("%s declares a status outside the status target" % prefix)
	return errors

func value_text() -> String:
	if value_mode == FIXED_BONUS:
		return "%+.0f" % value
	return "%+.0f%%" % (value * 100.0)
