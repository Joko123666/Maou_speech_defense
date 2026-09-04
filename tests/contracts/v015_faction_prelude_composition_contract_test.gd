class_name V015FactionPreludeCompositionContractTest
extends RefCounted

const TIER_TIMES: Array[float] = [240.0, 375.0, 510.0]
const EXPECTED_COSTS := {
	&"partason": [21.0, 46.0, 64.0],
	&"jiane": [25.0, 54.0, 54.0],
	&"kasuha": [28.0, 38.0, 66.0],
	&"irelai": [18.0, 34.0, 36.0],
	&"judaginda": [16.0, 32.0, 32.0],
}

static func run() -> Array[String]:
	var failures: Array[String] = []
	var stage := load("res://data/stages/standard_20m.tres") as StageData
	_expect(stage != null, "M4 requires the standard stage", failures)
	if stage == null:
		return failures
	_test_packet_catalog(stage, failures)
	_test_budget_ledger(failures)
	_test_runtime_replacement(stage, failures)
	_test_delayed_formations(stage, failures)
	return failures

static func _test_packet_catalog(stage: StageData, failures: Array[String]) -> void:
	_expect(stage.faction_spawn_packets.size() == 5 and stage.get_faction_spawn_packet_validation_errors().is_empty(), "M4 must define exactly one valid three-tier packet record per candidate faction", failures)
	var composer := FactionPreludePacketComposer.new()
	var seen_factions: Dictionary = {}
	for packet in stage.faction_spawn_packets:
		if packet == null:
			continue
		seen_factions[packet.faction_id] = true
		var faction_enemy := DataRegistry.get_enemy(packet.faction_enemy_id)
		var spawn_profile := DataRegistry.get_enemy_spawn_profile(packet.faction_enemy_id)
		_expect(faction_enemy != null and spawn_profile != null and spawn_profile.is_faction_enemy and spawn_profile.faction_id == packet.faction_id, "faction packet '%s' must resolve its single representative enemy and faction" % packet.id, failures)
		for tier in 3:
			var at_time := TIER_TIMES[tier]
			var phase := stage.spawn_phase_at(at_time)
			var plan := composer.compose(stage.faction_spawn_packets, DataRegistry.faction_enemies, _common_candidates(at_time), packet.faction_id, tier + 1, phase.max_packet_cost)
			_expect(not plan.is_empty(), "faction packet '%s' Tier %d must compose inside its Prelude phase budget" % [packet.id, tier + 1], failures)
			if plan.is_empty():
				continue
			var expected_costs := EXPECTED_COSTS.get(packet.id, []) as Array
			_expect(is_equal_approx(float(plan.cost), float(expected_costs[tier])) and float(plan.cost) <= phase.max_packet_cost + 0.0001, "faction packet '%s' Tier %d must preserve its reviewed replacement cost" % [packet.id, tier + 1], failures)
			var entries := plan.entries as Array[Dictionary]
			var faction_entries := entries.filter(func(entry: Dictionary) -> bool: return bool(entry.get("faction", false)))
			_expect(faction_entries.size() == 1 and (faction_entries[0].enemy as EnemyData).id == packet.faction_enemy_id and int(faction_entries[0].count) == packet.faction_count_for_tier(tier + 1), "faction packet '%s' Tier %d must contain only its declared representative count" % [packet.id, tier + 1], failures)
			_expect(int(plan.role_counts.get(&"heavy", 0)) <= (2 if tier + 1 == 3 else 1) and int(plan.role_counts.get(&"disable", 0)) <= tier + 1, "faction packet '%s' Tier %d must obey HEAVY and DISABLE density limits" % [packet.id, tier + 1], failures)
			_expect(not entries.any(func(entry: Dictionary) -> bool: return (entry.enemy as EnemyData).id == &"steel_golem"), "faction packet '%s' must not hide a repeated rare steel golem inside Prelude composition" % packet.id, failures)
			if faction_enemy != null and faction_enemy.formation_profile != null:
				_expect(packet.faction_count_for_tier(tier + 1) == faction_enemy.formation_profile.unit_count_for_tier(tier + 1), "group packet '%s' Tier %d must consume the M3 formation unit count exactly" % [packet.id, tier + 1], failures)
	_expect(seen_factions.size() == 5, "the packet catalog must cover all five candidate factions once", failures)

static func _test_budget_ledger(failures: Array[String]) -> void:
	var ledger := FactionPreludeBudgetLedger.new()
	var prelude := {
		"active": true,
		"boss_index": 1,
		"faction_id": &"irelai_faction",
		"tier": 1,
		"start_seconds": 240.0,
		"end_seconds": 300.0,
		"ratio_min": 0.15,
		"ratio_max": 0.25,
	}
	for _decision in 40:
		var use_faction := ledger.should_select_faction(22.0, 18.0, prelude, 270.0)
		ledger.record_spend(18.0 if use_faction else 22.0, use_faction, prelude)
	var snapshot := ledger.snapshot(prelude, 270.0)
	_expect(absf(float(snapshot.prelude_actual_ratio) - 0.20) <= 0.08, "the cumulative replacement ledger must converge near the active Prelude target without a second budget", failures)
	_expect(is_equal_approx(float(snapshot.prelude_total_cost), float(snapshot.prelude_common_cost) + float(snapshot.prelude_faction_cost)) and is_equal_approx(float(snapshot.prelude_total_cost), float(snapshot.lifetime_common_cost) + float(snapshot.lifetime_faction_cost)), "Prelude accounting must partition one total spend into common and faction cost", failures)

static func _test_runtime_replacement(stage: StageData, failures: Array[String]) -> void:
	var first := _runtime_signature(stage, 9127)
	var second := _runtime_signature(stage, 9127)
	_expect(first.signature == second.signature, "the same seed must preserve Prelude packet, group, cohort, destination Y, and spawn timing", failures)
	_expect(int(first.faction_count) > 0 and bool(first.only_expected_faction), "the Tier 1 runtime probe must spawn only the next boss faction", failures)
	_expect(is_equal_approx(float(first.initial_budget), float(first.remaining_budget) + float(first.spent_budget)), "Faction Prelude must replace spend inside the existing Base budget instead of adding a new budget", failures)
	_expect(is_equal_approx(float(first.spent_budget), float(first.ledger_total)), "runtime Prelude ledger cost must equal the director cost spent during the probe", failures)

static func _test_delayed_formations(stage: StageData, failures: Array[String]) -> void:
	var cavalry := _delayed_probe(stage, &"irelai_faction", 3, 510.0, 0.91, 31415)
	_expect(int(cavalry.immediate_count) == 3 and int(cavalry.pending_count) == 3 and int(cavalry.final_count) == 6, "Irelai Tier 3 must use the M3 planner as two 3-unit runtime waves", failures)
	_expect(int(cavalry.group_count) == 2 and bool(cavalry.has_delayed_wave), "Irelai Tier 3 runtime contexts must preserve two formations and a delayed cohort", failures)
	var applicants := _delayed_probe(stage, &"judaginda_faction", 3, 510.0, 1.51, 27182)
	_expect(int(applicants.immediate_count) == 4 and int(applicants.pending_count) == 4 and int(applicants.final_count) == 8, "Judaginda Tier 3 must use two runtime groups of four separated by about 1.5 seconds", failures)
	_expect(int(applicants.group_count) == 2 and bool(applicants.has_delayed_wave), "Judaginda delayed cohorts must retain distinct group ids so death acceleration cannot cross groups", failures)
	var boundary_spawner := _configured_spawner(stage, _plan_with_faction(stage, &"judaginda_faction", 3))
	boundary_spawner.elapsed = 598.6
	var boundary_prelude := boundary_spawner.get_faction_prelude_state(boundary_spawner.elapsed)
	var boundary_plan := boundary_spawner._compose_faction_plan(boundary_prelude, boundary_spawner.get_regular_spawn_candidates(boundary_spawner.elapsed), 80.0, EnemySpawnDirector.BASE_CHANNEL)
	_expect(boundary_plan.is_empty(), "a delayed faction wave that would cross the boss frame must not be scheduled or charged", failures)
	boundary_spawner.free()

static func _runtime_signature(stage: StageData, seed_value: int) -> Dictionary:
	RunRng.begin_run(true, seed_value)
	var plan := _plan_with_faction(stage, &"partason_faction", 1)
	var spawner := _configured_spawner(stage, plan)
	spawner.elapsed = 240.0
	var initial_budget := 280.0
	spawner.spawn_director.base_budget = initial_budget
	var signature: PackedStringArray = []
	var faction_count := [0]
	var only_expected := [true]
	spawner.spawn_requested.connect(func(_ratio: float, enemy: EnemyData, _health: float, _speed: float, context: EnemySpawnContext) -> void:
		signature.append("%s|%s|%d|%s|%s|%s|%.3f|%.3f" % [enemy.id, context.faction_id, context.prelude_tier, context.packet_id, context.group_id, context.cohort_id, context.spawn_delay, context.spawn_y_ratio])
		if context.prelude_tier > 0:
			faction_count[0] += 1
			only_expected[0] = only_expected[0] and context.faction_id == &"partason_faction"
	)
	for _spawn in 10:
		if not spawner._spawn_from_budget(EnemySpawnDirector.BASE_CHANNEL, 0.4):
			break
	var snapshot := spawner.spawn_budget_snapshot()
	var result := {
		"signature": signature,
		"faction_count": faction_count[0],
		"only_expected_faction": only_expected[0],
		"initial_budget": initial_budget,
		"remaining_budget": spawner.spawn_director.base_budget,
		"spent_budget": spawner.spawn_director.base_budget_spent,
		"ledger_total": snapshot.prelude_total_cost,
	}
	spawner.free()
	return result

static func _delayed_probe(stage: StageData, faction_id: StringName, tier: int, at_time: float, advance_seconds: float, seed_value: int) -> Dictionary:
	RunRng.begin_run(true, seed_value)
	var plan := _plan_with_faction(stage, faction_id, tier)
	var spawner := _configured_spawner(stage, plan)
	spawner.elapsed = at_time
	var prelude := spawner.get_faction_prelude_state(at_time)
	var faction_plan := spawner._compose_faction_plan(prelude, spawner.get_regular_spawn_candidates(at_time), 80.0, EnemySpawnDirector.BASE_CHANNEL)
	var contexts: Array[EnemySpawnContext] = []
	spawner.spawn_requested.connect(func(_ratio: float, _enemy: EnemyData, _health: float, _speed: float, context: EnemySpawnContext) -> void:
		if context.prelude_tier > 0:
			contexts.append(context)
	)
	spawner._spawn_faction_packet(faction_plan, at_time / stage.duration_seconds, EnemySpawnDirector.BASE_CHANNEL, prelude)
	var immediate_count := contexts.size()
	var pending_count := spawner.pending_faction_spawns.size()
	spawner.elapsed += advance_seconds
	spawner._flush_pending_faction_spawns()
	var groups: Dictionary = {}
	for context in contexts:
		groups[context.group_id] = true
	var result := {
		"immediate_count": immediate_count,
		"pending_count": pending_count,
		"final_count": contexts.size(),
		"group_count": groups.size(),
		"has_delayed_wave": contexts.any(func(context: EnemySpawnContext) -> bool: return context.spawn_delay > 0.0 and context.wave_index == 1),
	}
	spawner.free()
	return result

static func _configured_spawner(stage: StageData, plan: StageRuntimeBossPlan) -> EnemySpawner:
	var spawner := EnemySpawner.new()
	spawner.stage_data = stage
	spawner.boss_plan = plan
	spawner.enemy_pool.assign(DataRegistry.enemies)
	spawner.faction_enemy_pool.assign(DataRegistry.faction_enemies)
	spawner.spawn_director.configure(stage, 0)
	return spawner

static func _plan_with_faction(stage: StageData, faction_id: StringName, boss_index: int) -> StageRuntimeBossPlan:
	var factions: Array[StringName] = [&"partason_faction", &"jiane_faction", &"kasuha_faction", &"irelai_faction"]
	if faction_id == &"judaginda_faction":
		factions[0] = faction_id
	var source_index := factions.find(faction_id)
	if source_index >= 0:
		var displaced := factions[boss_index]
		factions[boss_index] = faction_id
		factions[source_index] = displaced
	var plan := StageRuntimeBossPlan.new()
	plan.id = &"m4-contract-plan"
	plan.source = StageRuntimeBossPlan.SOURCE_CAMPAIGN
	plan.final_boss_id = stage.default_boss_ids.back()
	for index in stage.boss_times.size():
		plan.slots.append({"boss_id": stage.default_boss_ids[index], "faction_id": factions[index], "time": stage.boss_times[index]})
	return plan

static func _common_candidates(at_time: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy in DataRegistry.enemies:
		var profile := DataRegistry.get_enemy_spawn_profile(enemy.id)
		if profile != null and profile.unlock_time <= at_time:
			result.append({"enemy": enemy, "weight": 1.0})
	return result

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
