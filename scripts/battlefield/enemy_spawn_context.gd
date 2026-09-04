class_name EnemySpawnContext
extends RefCounted

var enemy_id: StringName = &""
var packet_id: StringName = &""
var channel: StringName = &"base"
var spawn_time: float = 0.0
var faction_id: StringName = &""
var prelude_tier: int = 0
var group_id: StringName = &""
var cohort_id: StringName = &""
var wave_index: int = 0
var formation_index: int = 0
var spawn_delay: float = 0.0
var spawn_y_ratio: float = 0.5
var destination_y_ratio: float = -1.0
var encounter_kind: StringName = &""
var artifact_reward_tier: int = 0

func is_artifact_elite() -> bool:
	return encounter_kind == &"artifact_elite" and artifact_reward_tier > 0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if enemy_id == &"":
		errors.append("enemy spawn context has no enemy id")
	if channel not in [&"base", &"bonus"]:
		errors.append("enemy spawn context has unsupported channel '%s'" % channel)
	if spawn_time < 0.0:
		errors.append("enemy spawn context has a negative spawn time")
	if spawn_y_ratio < 0.0 or spawn_y_ratio > 1.0:
		errors.append("enemy spawn context has an invalid spawn Y ratio")
	if not is_equal_approx(destination_y_ratio, -1.0) and (destination_y_ratio < 0.0 or destination_y_ratio > 1.0):
		errors.append("enemy spawn context has an invalid destination Y ratio")
	if prelude_tier < 0 or prelude_tier > 3:
		errors.append("enemy spawn context has an invalid prelude tier")
	if (faction_id == &"") != (prelude_tier == 0):
		errors.append("enemy spawn context has inconsistent faction prelude fields")
	if wave_index < 0:
		errors.append("enemy spawn context has a negative wave index")
	if formation_index < 0:
		errors.append("enemy spawn context has a negative formation index")
	if spawn_delay < 0.0:
		errors.append("enemy spawn context has a negative spawn delay")
	if encounter_kind not in [&"", &"artifact_elite"]:
		errors.append("enemy spawn context has unsupported encounter kind '%s'" % encounter_kind)
	if (encounter_kind == &"artifact_elite") != (artifact_reward_tier > 0):
		errors.append("enemy spawn context has inconsistent artifact elite fields")
	return errors

func to_snapshot() -> Dictionary:
	return {
		"enemy_id": String(enemy_id),
		"packet_id": String(packet_id),
		"channel": String(channel),
		"spawn_time": spawn_time,
		"faction_id": String(faction_id),
		"prelude_tier": prelude_tier,
		"group_id": String(group_id),
		"cohort_id": String(cohort_id),
		"wave_index": wave_index,
		"formation_index": formation_index,
		"spawn_delay": spawn_delay,
		"spawn_y_ratio": spawn_y_ratio,
		"destination_y_ratio": destination_y_ratio,
		"encounter_kind": String(encounter_kind),
		"artifact_reward_tier": artifact_reward_tier,
	}
