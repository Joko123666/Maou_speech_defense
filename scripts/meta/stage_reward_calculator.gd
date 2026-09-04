class_name StageRewardCalculator
extends RefCounted

static func calculate(
	result: Dictionary,
	reward_data: StageRewardData,
	stage_first_clear_claimed: bool = false,
	challenge_first_clear_claimed: bool = false
) -> Dictionary:
	if reward_data == null or not bool(result.get("eligible_for_meta_rewards", true)):
		return _empty_breakdown()

	var duration := maxf(float(result.get("stage_duration_seconds", reward_data.stage_duration_seconds)), 1.0)
	var elapsed := clampf(float(result.get("elapsed", 0.0)), 0.0, duration)
	var progress_ratio := elapsed / duration
	var curved_progress := 0.25 * progress_ratio + 0.75 * pow(progress_ratio, reward_data.progress_curve_power)
	var progress_funds := floori(float(reward_data.base_progress_funds) * curved_progress)

	var boss_funds := 0
	var rewarded_boss_ids: Array[String] = []
	var seen_boss_ids: Dictionary = {}
	var defeated_boss_ids: Variant = result.get("boss_kill_ids", [])
	if defeated_boss_ids is Array:
		for raw_id in defeated_boss_ids:
			var boss_id := String(raw_id)
			if boss_id.is_empty() or seen_boss_ids.has(boss_id):
				continue
			seen_boss_ids[boss_id] = true
			if reward_data.boss_funds_by_id.has(StringName(boss_id)):
				boss_funds += int(reward_data.boss_funds_by_id[StringName(boss_id)])
				rewarded_boss_ids.append(boss_id)
			elif reward_data.boss_funds_by_id.has(boss_id):
				boss_funds += int(reward_data.boss_funds_by_id[boss_id])
				rewarded_boss_ids.append(boss_id)

	var victory := bool(result.get("victory", false))
	var victory_funds := reward_data.victory_bonus if victory else 0
	var challenge_level := ChallengeRules.clamp_level(int(result.get("challenge_level", 0)))
	var challenge_multiplier := 1.0 + float(challenge_level) * reward_data.challenge_funds_per_level
	var repeatable_subtotal := progress_funds + boss_funds + victory_funds
	var repeatable_funds := floori(float(repeatable_subtotal) * challenge_multiplier)

	var stage_id := String(result.get("stage_id", reward_data.stage_id))
	var stage_first_reward_id := "stage:%s" % stage_id
	var stage_first_funds := reward_data.stage_first_clear_bonus if victory and not stage_first_clear_claimed else 0
	var challenge_first_reward_id := "challenge:%s:%d" % [stage_id, challenge_level]
	var challenge_first_funds := 0
	if victory and not challenge_first_clear_claimed:
		challenge_first_funds = int(reward_data.challenge_first_clear_funds.get(challenge_level, 0))

	return {
		"progress_ratio": progress_ratio,
		"progress_funds": progress_funds,
		"boss_funds": boss_funds,
		"rewarded_boss_ids": rewarded_boss_ids,
		"victory_funds": victory_funds,
		"challenge_level": challenge_level,
		"challenge_multiplier": challenge_multiplier,
		"repeatable_subtotal": repeatable_subtotal,
		"repeatable_funds": repeatable_funds,
		"stage_first_clear_funds": stage_first_funds,
		"stage_first_reward_id": stage_first_reward_id if stage_first_funds > 0 else "",
		"challenge_first_clear_funds": challenge_first_funds,
		"challenge_first_reward_id": challenge_first_reward_id if challenge_first_funds > 0 else "",
		"first_clear_funds": stage_first_funds + challenge_first_funds,
		"total_funds": repeatable_funds + stage_first_funds + challenge_first_funds,
	}

static func _empty_breakdown() -> Dictionary:
	return {
		"progress_ratio": 0.0,
		"progress_funds": 0,
		"boss_funds": 0,
		"rewarded_boss_ids": [],
		"victory_funds": 0,
		"challenge_level": 0,
		"challenge_multiplier": 1.0,
		"repeatable_subtotal": 0,
		"repeatable_funds": 0,
		"stage_first_clear_funds": 0,
		"stage_first_reward_id": "",
		"challenge_first_clear_funds": 0,
		"challenge_first_reward_id": "",
		"first_clear_funds": 0,
		"total_funds": 0,
	}
