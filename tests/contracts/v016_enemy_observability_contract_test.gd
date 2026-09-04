class_name V016EnemyObservabilityContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var metrics := RunMetrics.new()
	metrics.update_time(247.5)
	var enemy := DataRegistry.get_enemy(&"jiane_succubus_bewitcher")
	var context := EnemySpawnContext.new()
	context.enemy_id = enemy.id
	context.packet_id = &"jiane"
	context.channel = &"bonus"
	context.spawn_time = 247.5
	context.faction_id = &"jiane_faction"
	context.prelude_tier = 1
	context.group_id = &"jiane:g0:t1:s1"
	context.cohort_id = &"jiane:c0:t1:s1"
	context.wave_index = 0
	metrics.record_enemy_spawn(2, enemy, context)
	metrics.record_enemy_acceleration(enemy, context, &"group_death", 2, 0.16, 2.5)
	var disable_targets: Array[String] = ["1:2:rapid"]
	metrics.record_defender_disable(enemy, context, &"succubus_killer_disable", 3.0, disable_targets)
	metrics.record_enemy_defeat(2, enemy, context, Enemy.DEATH_CAUSE_DAMAGE_OVER_TIME)
	metrics.record_enemy_breach(2, enemy, context)
	var activity := metrics.enemy_activity_snapshot()
	var spawn := (activity.spawns as Array)[0] as Dictionary
	var death := (activity.exits as Array)[0] as Dictionary
	_expect(int(activity.spawn_count) == 1 and int(activity.death_count) == 1 and int(activity.breach_count) == 1, "v0.16 enemy activity must count spawn, death, and breach separately", failures)
	_expect(String(spawn.enemy_id) == String(enemy.id) and String(spawn.faction_id) == "jiane_faction" and int(spawn.prelude_tier) == 1 and String(spawn.channel) == "bonus", "enemy spawn events must preserve ID, faction, Prelude Tier, and budget channel", failures)
	_expect(String(spawn.group_id) == "jiane:g0:t1:s1" and String(spawn.cohort_id) == "jiane:c0:t1:s1" and int(spawn.wave_index) == 0, "enemy spawn events must preserve group, cohort, and wave identity", failures)
	_expect(String(death.death_cause) == "damage_over_time" and int((activity.accelerations as Array).size()) == 1, "enemy exit and acceleration events must preserve their cause and stack transition", failures)
	var disable := (activity.defender_disables as Array)[0] as Dictionary
	_expect(int(disable.target_count) == 1 and is_equal_approx(float(disable.effective_seconds), 3.0) and String((disable.targets as Array)[0]) == "1:2:rapid", "defender disable events must preserve target identity and effective duration", failures)

	var ledger := FactionPreludeBudgetLedger.new()
	var prelude := {"active": true, "boss_index": 1, "faction_id": &"jiane_faction", "tier": 1, "start_seconds": 240.0, "end_seconds": 300.0, "ratio_min": 0.15, "ratio_max": 0.25}
	ledger.record_spend(10.0, false, prelude, &"base")
	ledger.record_spend(4.0, true, prelude, &"base")
	ledger.record_spend(3.0, true, prelude, &"bonus")
	var budget := ledger.snapshot(prelude, 250.0)
	var base_cost := (budget.prelude_cost_by_channel as Dictionary).get("base", {}) as Dictionary
	var bonus_cost := (budget.prelude_cost_by_channel as Dictionary).get("bonus", {}) as Dictionary
	_expect(is_equal_approx(float(base_cost.common_cost), 10.0) and is_equal_approx(float(base_cost.faction_cost), 4.0) and is_equal_approx(float(bonus_cost.faction_cost), 3.0), "Prelude budget accounting must split common/faction spend by Base and Bonus channel", failures)
	var window := (budget.prelude_windows as Array)[0] as Dictionary
	_expect(String(window.faction_id) == "jiane_faction" and int(window.tier) == 1 and is_equal_approx(float(window.total_cost), 17.0) and float(window.actual_ratio) > 0.0, "completed Prelude windows must retain faction, Tier, target range, and actual cost ratio after the active window ends", failures)

	var codex_entry := (CodexService.new().get_entries(&"enemy") as Array).filter(func(entry: Dictionary) -> bool: return entry.id == enemy.id).front() as Dictionary
	var related_text := " / ".join(codex_entry.related as Array[String])
	_expect(related_text.contains("Faction Prelude") and related_text.contains("특수행동") and related_text.contains("정상 대응") and related_text.contains("소속"), "enemy codex must explain faction window, special action, response, and affiliation", failures)
	metrics.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
