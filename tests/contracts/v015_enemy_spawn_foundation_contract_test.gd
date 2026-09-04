class_name V015EnemySpawnFoundationContractTest
extends RefCounted

const EXPECTED_COSTS := {
	&"civilian_slime": 3.0,
	&"goblin_raider": 5.0,
	&"skeleton_raider": 8.0,
	&"orc_shield": 12.0,
	&"hound_light_infantry": 11.0,
	&"wraith_raider": 14.0,
	&"steel_golem": 26.0,
	&"partason_standard_shield": 15.0,
	&"jiane_succubus_bewitcher": 16.0,
	&"kasuha_abyss_creature": 22.0,
	&"irelai_skeleton_cavalry": 6.0,
	&"judaginda_cult_applicant": 4.0,
}

static func run() -> Array[String]:
	var failures: Array[String] = []
	var target_ids := EnemyCatalogV015.all_ids()
	_expect(EnemyCatalogV015.COMMON_IDS.size() == 7 and EnemyCatalogV015.FACTION_IDS.size() == 5 and target_ids.size() == 12, "v0.15 must freeze exactly seven common and five faction enemy IDs", failures)
	_expect(_unique_count(target_ids) == 12, "v0.15 target enemy IDs must be unique", failures)
	_expect(EnemyCatalogV015.LEGACY_IDS.size() == 18 and _unique_count(EnemyCatalogV015.LEGACY_IDS) == 18, "the v0.15 migration boundary must enumerate all eighteen legacy enemy IDs", failures)
	_expect(EnemyCatalogV015.LEGACY_REFERENCE_MIGRATION.size() == 18, "every legacy enemy reference must have a reviewed v0.15 replacement", failures)
	for legacy_id in EnemyCatalogV015.LEGACY_IDS:
		_expect(EnemyCatalogV015.LEGACY_REFERENCE_MIGRATION.has(legacy_id), "legacy enemy '%s' must exist in the migration table" % legacy_id, failures)
		_expect(StringName(EnemyCatalogV015.LEGACY_REFERENCE_MIGRATION.get(legacy_id, &"")) in target_ids, "legacy enemy '%s' must map to a target v0.15 ID" % legacy_id, failures)

	var campaign := ConceptService.get_election_campaign()
	var faction_ids: Dictionary = {}
	if campaign != null:
		for faction in campaign.factions:
			if faction != null:
				faction_ids[faction.id] = true
	var profiles := DataRegistry.enemy_spawn_profiles
	var profile_ids: Array[StringName] = []
	profile_ids.assign(profiles.map(func(profile: EnemySpawnProfileData) -> StringName: return profile.enemy_id))
	_expect(profiles.size() == 12 and _same_ids(profile_ids, target_ids), "DataRegistry must expose the complete staged v0.15 spawn profile catalog", failures)
	var active_enemy_ids: Array[StringName] = []
	active_enemy_ids.assign(DataRegistry.enemies.map(func(enemy: EnemyData) -> StringName: return enemy.id))
	_expect(DataRegistry.enemies.size() == 7 and _same_ids(active_enemy_ids, EnemyCatalogV015.COMMON_IDS), "M2 must expose exactly the seven v0.15 common enemies as the active automatic pool", failures)
	var faction_counts: Dictionary = {}
	for profile in profiles:
		_expect(profile.get_validation_errors(faction_ids).is_empty(), "spawn profile '%s' must satisfy the v0.15 schema" % profile.enemy_id, failures)
		_expect(is_equal_approx(profile.spawn_cost, float(EXPECTED_COSTS.get(profile.enemy_id, -1.0))), "spawn profile '%s' must preserve the reviewed draft cost" % profile.enemy_id, failures)
		_expect(DataRegistry.get_enemy_spawn_profile(profile.enemy_id) == profile, "spawn profile '%s' must resolve through the registry lookup" % profile.enemy_id, failures)
		if profile.is_faction_enemy:
			faction_counts[profile.faction_id] = int(faction_counts.get(profile.faction_id, 0)) + 1
			_expect(profile.faction_id == StringName(EnemyCatalogV015.FACTION_BY_ENEMY_ID.get(profile.enemy_id, &"")), "faction enemy '%s' must use its declared campaign faction" % profile.enemy_id, failures)
	_expect(faction_counts.size() == 5 and faction_counts.values().all(func(count: Variant) -> bool: return int(count) == 1), "each candidate faction must own exactly one v0.15 representative enemy", failures)
	_expect(DataRegistry.get_enemy_spawn_profile(&"steel_golem").rare_spawn_cooldown > 0.0, "steel golem must declare a positive rare spawn cooldown", failures)
	for enemy in DataRegistry.enemies:
		var runtime_profile := DataRegistry.get_enemy_spawn_profile(enemy.id)
		_expect(runtime_profile != null and is_equal_approx(enemy.spawn_cost, runtime_profile.spawn_cost) and enemy.role_tags == runtime_profile.role_tags and is_equal_approx(enemy.available_from_seconds, runtime_profile.unlock_time), "active enemy '%s' must consume its v0.15 spawn profile authority" % enemy.id, failures)
	_expect(DataRegistry.get_enemy(&"skeleton_raider").movement_profile != null and DataRegistry.get_enemy(&"skeleton_raider").movement_profile.kind == &"fixed_diagonal", "skeleton raider must own a fixed-diagonal movement profile", failures)
	_expect(is_equal_approx(DataRegistry.get_enemy_spawn_profile(&"skeleton_raider").rare_spawn_cooldown, 6.0), "fixed-diagonal skeleton groups must use the six-second specialist cooldown", failures)
	_expect(DataRegistry.get_enemy(&"hound_light_infantry").acceleration_profile != null and DataRegistry.get_enemy(&"hound_light_infantry").acceleration_profile.maximum_stacks == 5, "hound infantry must own its reviewed five-stack acceleration profile", failures)
	_expect(DataRegistry.get_enemy(&"wraith_raider").death_effect_profile != null and DataRegistry.get_enemy(&"wraith_raider").death_effect_profile.effect == &"disable_normal_defenders", "wraith raider must own a distance-based defender-disable death profile", failures)
	_expect(DataRegistry.get_enemy(&"steel_golem").knockback_resistance > 0.0 and DataRegistry.get_enemy(&"steel_golem").knockback_resistance < 1.0, "steel golem must use partial knockback resistance", failures)
	_expect(DataRegistry.get_enemy_spawn_profile(&"irelai_skeleton_cavalry").group_min == 3 and DataRegistry.get_enemy_spawn_profile(&"judaginda_cult_applicant").group_min == 4, "group enemies must preserve their minimum Tier 1 cohort sizes", failures)
	var cooldown_spawner := EnemySpawner.new()
	cooldown_spawner.stage_data = load("res://data/stages/standard_20m.tres") as StageData
	cooldown_spawner.enemy_pool.assign(DataRegistry.enemies)
	cooldown_spawner.elapsed = 450.0
	var golem := DataRegistry.get_enemy(&"steel_golem")
	_expect(cooldown_spawner.get_regular_spawn_candidates(450.0).any(func(entry: Dictionary) -> bool: return entry.enemy == golem), "steel golem must become eligible at 450 seconds", failures)
	cooldown_spawner._record_profile_spawn(golem)
	_expect(not cooldown_spawner.get_regular_spawn_candidates(479.99).any(func(entry: Dictionary) -> bool: return entry.enemy == golem), "steel golem must not spawn consecutively inside its rare cooldown", failures)
	_expect(cooldown_spawner.get_regular_spawn_candidates(480.0).any(func(entry: Dictionary) -> bool: return entry.enemy == golem), "steel golem must become eligible when its rare cooldown expires", failures)
	cooldown_spawner.free()

	var legacy_profile := EnemySpawnProfileData.from_enemy_data(DataRegistry.enemies[0])
	_expect(legacy_profile != null and legacy_profile.enemy_id == DataRegistry.enemies[0].id and not legacy_profile.is_faction_enemy, "legacy content must derive a common compatibility spawn profile without opting into Prelude", failures)
	var partial_profile_pack := ContentPackData.new()
	partial_profile_pack.id = &"partial-profile-contract"
	partial_profile_pack.cores.assign(DataRegistry.cores)
	partial_profile_pack.cursors.assign(DataRegistry.cursors)
	partial_profile_pack.towers.assign(DataRegistry.towers)
	partial_profile_pack.formations.assign(DataRegistry.formations)
	partial_profile_pack.tower_branches.assign(DataRegistry.tower_branches)
	partial_profile_pack.specialization_branches.assign(DataRegistry.specialization_branches)
	partial_profile_pack.enemies.assign(DataRegistry.enemies)
	partial_profile_pack.bosses.assign(DataRegistry.bosses)
	partial_profile_pack.enemy_spawn_profiles.append(legacy_profile)
	_expect("\n".join(partial_profile_pack.get_validation_errors()).contains("missing its explicit spawn profile"), "an external content pack that opts into explicit profiles must profile every enemy", failures)
	var profileless_pack := partial_profile_pack.duplicate(true) as ContentPackData
	profileless_pack.id = &"profileless-contract"
	profileless_pack.enemy_spawn_profiles.clear()
	var registry_probe: Variant = (load("res://autoload/data_registry.gd") as Script).new()
	registry_probe._load_content_pack(profileless_pack)
	_expect(
		registry_probe.enemy_spawn_profiles.size() == profileless_pack.enemies.size()
		and registry_probe.enemy_spawn_profiles.all(func(profile: EnemySpawnProfileData) -> bool: return profile != null and not profile.is_faction_enemy)
		and registry_probe.enemies.size() == profileless_pack.enemies.size()
		and registry_probe.faction_enemies.is_empty(),
		"an external content pack without explicit spawn profiles must derive one common compatibility profile per loaded enemy",
		failures
	)
	registry_probe.free()
	var empty_roles: Array[StringName] = []
	var invalid_profile := EnemySpawnProfileData.new().configure(&"invalid", 0.0, empty_roles, -1.0, &"missing_faction", 3, 2, -1.0)
	_expect(invalid_profile.get_validation_errors(faction_ids).size() >= 5, "spawn profile validation must reject cost, roles, unlock, faction, group, and cooldown errors", failures)

	var stage := load("res://data/stages/standard_20m.tres") as StageData
	_expect(stage != null and stage.spawn_phases.size() == 6, "v0.15 M1 must retain the six budget phases", failures)
	if stage == null:
		return failures
	_expect(stage.faction_preludes.size() == 4 and stage.get_faction_prelude_validation_errors().is_empty(), "the standard stage must define one valid Prelude record for every boss slot", failures)
	var expected_windows := [
		[0, 0.0, 0, 0.0, 0.0],
		[1, 60.0, 1, 0.15, 0.25],
		[2, 75.0, 2, 0.25, 0.35],
		[3, 90.0, 3, 0.35, 0.45],
	]
	for expected in expected_windows:
		var prelude := stage.faction_prelude_for_boss_index(int(expected[0]))
		_expect(prelude != null and is_equal_approx(prelude.duration, float(expected[1])) and prelude.tier == int(expected[2]) and is_equal_approx(prelude.faction_budget_ratio_min, float(expected[3])) and is_equal_approx(prelude.faction_budget_ratio_max, float(expected[4])), "boss slot %d must preserve its reviewed v0.15 Prelude window and ratio" % int(expected[0]), failures)

	var dynamic_plan := CampaignStageResolver.resolve(stage, DataRegistry.bosses, campaign, &"obsidian", &"vanguard", 42731)
	_expect(dynamic_plan.source == StageRuntimeBossPlan.SOURCE_CAMPAIGN, "Prelude contract requires a campaign runtime boss plan", failures)
	_expect(not bool(FactionPreludeResolver.resolve(stage, dynamic_plan, 239.99).active), "no faction enemy may be eligible before the Tier 1 window", failures)
	_assert_prelude(stage, dynamic_plan, 240.0, 1, 1, failures)
	_expect(not bool(FactionPreludeResolver.resolve(stage, dynamic_plan, 300.0).active), "Tier 1 Prelude must end on the second boss spawn frame", failures)
	_assert_prelude(stage, dynamic_plan, 375.0, 2, 2, failures)
	_expect(not bool(FactionPreludeResolver.resolve(stage, dynamic_plan, 450.0).active), "Tier 2 Prelude must end on the third boss spawn frame", failures)
	_assert_prelude(stage, dynamic_plan, 510.0, 3, 3, failures)
	_expect(not bool(FactionPreludeResolver.resolve(stage, dynamic_plan, 600.0).active), "Tier 3 Prelude must end on the final boss spawn frame", failures)
	var fixed_plan := CampaignStageResolver.build_fixed_plan(stage, DataRegistry.bosses)
	_expect(not bool(FactionPreludeResolver.resolve(stage, fixed_plan, 240.0).active), "a fixed plan without explicit faction IDs must remain common-enemy-only", failures)

	var spawn_context := EnemySpawnContext.new()
	spawn_context.enemy_id = &"irelai_skeleton_cavalry"
	spawn_context.faction_id = &"irelai_faction"
	spawn_context.prelude_tier = 2
	spawn_context.group_id = &"group-a"
	spawn_context.cohort_id = &"cohort-a"
	spawn_context.spawn_time = 400.0
	spawn_context.spawn_y_ratio = 0.4
	spawn_context.destination_y_ratio = 0.7
	_expect(spawn_context.get_validation_errors().is_empty() and String(spawn_context.to_snapshot().group_id) == "group-a", "Spawn Context must preserve faction, tier, group, cohort, and fixed destination data", failures)
	spawn_context.faction_id = &""
	_expect(not spawn_context.get_validation_errors().is_empty(), "Spawn Context validation must reject a tier without a faction", failures)
	return failures

static func _assert_prelude(stage: StageData, plan: StageRuntimeBossPlan, at_time: float, boss_index: int, tier: int, failures: Array[String]) -> void:
	var resolved := FactionPreludeResolver.resolve(stage, plan, at_time)
	_expect(bool(resolved.active) and int(resolved.boss_index) == boss_index and int(resolved.tier) == tier and StringName(resolved.faction_id) == plan.faction_id_at(boss_index), "%.2f seconds must resolve only the next boss faction at Tier %d" % [at_time, tier], failures)

static func _same_ids(left: Array[StringName], right: Array[StringName]) -> bool:
	var left_sorted := left.duplicate()
	var right_sorted := right.duplicate()
	left_sorted.sort()
	right_sorted.sort()
	return left_sorted == right_sorted

static func _unique_count(ids: Array[StringName]) -> int:
	var unique: Dictionary = {}
	for id in ids:
		unique[id] = true
	return unique.size()

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
