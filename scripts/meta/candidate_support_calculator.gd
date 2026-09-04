class_name CandidateSupportCalculator
extends RefCounted

const FULL_PROGRESS_SUPPORT := 60.0
const SUPPORT_PER_BOSS := 5
const VICTORY_SUPPORT := 15
const CHALLENGE_BONUS_PER_LEVEL := 0.03

static func calculate(result: Dictionary) -> Dictionary:
	var candidate_id := String(result.get("candidate_id", ""))
	if candidate_id.is_empty():
		return empty_breakdown()
	var duration := maxf(float(result.get("stage_duration_seconds", 600.0)), 1.0)
	var elapsed := clampf(float(result.get("elapsed", 0.0)), 0.0, duration)
	var progress_ratio := elapsed / duration
	var progress_support := roundi(FULL_PROGRESS_SUPPORT * (0.20 * progress_ratio + 0.80 * pow(progress_ratio, 1.65)))
	var defeated_rivals := _defeated_rival_candidate_ids(result)
	var boss_support := defeated_rivals.size() * SUPPORT_PER_BOSS
	var victory_support := VICTORY_SUPPORT if bool(result.get("victory", false)) else 0
	var challenge_level := ChallengeRules.clamp_level(int(result.get("challenge_level", 0)))
	var challenge_multiplier := 1.0 + float(challenge_level) * CHALLENGE_BONUS_PER_LEVEL
	var subtotal := progress_support + boss_support + victory_support
	return {
		"candidate_id": candidate_id,
		"support_required": maxi(int(result.get("support_required_for_election", 0)), 0),
		"progress_ratio": progress_ratio,
		"progress_support": progress_support,
		"boss_support": boss_support,
		"victory_support": victory_support,
		"challenge_multiplier": challenge_multiplier,
		"total_support": roundi(float(subtotal) * challenge_multiplier),
		"defeated_rival_candidate_ids": defeated_rivals,
	}

static func _defeated_rival_candidate_ids(result: Dictionary) -> Array[String]:
	var defeated_boss_ids := _string_set(result.get("boss_kill_ids", []))
	var defeated: Array[String] = []
	var boss_plan_value: Variant = result.get("boss_plan", {})
	if boss_plan_value is Dictionary:
		var slots_value: Variant = (boss_plan_value as Dictionary).get("slots", [])
		if slots_value is Array:
			var rival_ids_value: Variant = result.get("rival_candidate_ids", [])
			var rival_ids: Array = rival_ids_value if rival_ids_value is Array else []
			for index in slots_value.size():
				var slot_value: Variant = slots_value[index]
				if slot_value is not Dictionary:
					continue
				var slot := slot_value as Dictionary
				var boss_id := String(slot.get("boss_id", ""))
				var rival_id := String(rival_ids[index]) if index < rival_ids.size() else ""
				if boss_id in defeated_boss_ids and not rival_id.is_empty() and rival_id not in defeated:
					defeated.append(rival_id)
	if defeated.is_empty():
		var explicit_value: Variant = result.get("defeated_rival_candidate_ids", [])
		if explicit_value is Array:
			for rival_id in explicit_value:
				var id_text := String(rival_id)
				if not id_text.is_empty() and id_text not in defeated:
					defeated.append(id_text)
	return defeated

static func _string_set(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	for item in value:
		var text := String(item)
		if not text.is_empty() and text not in result:
			result.append(text)
	return result

static func empty_breakdown() -> Dictionary:
	return {
		"candidate_id": "",
		"support_required": 0,
		"progress_ratio": 0.0,
		"progress_support": 0,
		"boss_support": 0,
		"victory_support": 0,
		"challenge_multiplier": 1.0,
		"total_support": 0,
		"defeated_rival_candidate_ids": [],
	}
