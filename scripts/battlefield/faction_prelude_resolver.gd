class_name FactionPreludeResolver
extends RefCounted

static func resolve(stage: StageData, boss_plan: StageRuntimeBossPlan, at_time: float) -> Dictionary:
	var inactive := {
		"active": false,
		"boss_index": -1,
		"faction_id": &"",
		"tier": 0,
		"start_seconds": 0.0,
		"end_seconds": 0.0,
		"ratio_min": 0.0,
		"ratio_max": 0.0,
	}
	if stage == null or boss_plan == null:
		return inactive
	for prelude in stage.faction_preludes:
		if prelude == null or prelude.boss_index >= boss_plan.slots.size():
			continue
		var boss_time := boss_plan.time_at(prelude.boss_index)
		if not prelude.contains(at_time, boss_time):
			continue
		var faction_id := boss_plan.faction_id_at(prelude.boss_index)
		if faction_id == &"":
			return inactive
		return {
			"active": true,
			"boss_index": prelude.boss_index,
			"faction_id": faction_id,
			"tier": prelude.tier,
			"start_seconds": prelude.start_seconds(boss_time),
			"end_seconds": boss_time,
			"ratio_min": prelude.faction_budget_ratio_min,
			"ratio_max": prelude.faction_budget_ratio_max,
		}
	return inactive
