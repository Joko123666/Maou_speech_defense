class_name EnemyDefeatPolicy
extends RefCounted

func build_plan(
	enemy_data: EnemyData,
	reward_value: float,
	is_final_boss: bool,
	soul_harvest_enabled: bool,
	core_skill_ready: bool,
	reward_chain_enabled: bool,
	resolving_death_wave: bool
) -> Dictionary:
	if enemy_data == null:
		return {"valid": false}
	var is_boss := enemy_data.is_boss
	return {
		"valid": true,
		"is_boss": is_boss,
		"is_final_boss": is_boss and is_final_boss,
		"record_candidate_soul": soul_harvest_enabled and core_skill_ready,
		"allow_random_necromancy": not resolving_death_wave,
		"reward_kind": &"boss_burst" if is_boss else &"orb",
		"trigger_reward_chain": reward_chain_enabled and reward_value > enemy_data.experience_value * 1.01,
		"splitter_child_count": 2 if enemy_data.behavior == &"splitter" else 0,
		"settle_boss": is_boss,
		"stop_timeline": is_boss and is_final_boss,
	}
