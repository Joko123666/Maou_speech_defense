class_name CatalogGrowthRuntimeContractTest
extends RefCounted

var failures: Array[String] = []

static func run(host: Node) -> Array[String]:
	var suite := CatalogGrowthRuntimeContractTest.new()
	suite._run(host)
	return suite.failures

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run(host: Node) -> void:
	var default_stage := ConceptService.get_default_stage()
	var paced_tower := DataRegistry.get_tower(&"rapid")
	var paced_chain_tower := DataRegistry.get_tower(&"chain")
	var paced_core := DataRegistry.get_core(&"emerald")
	var paced_cursor := DataRegistry.get_cursor(&"silver")
	var paced_enemy := DataRegistry.get_enemy(&"normal")
	var paced_boss := DataRegistry.get_enemy(&"boss_5")
	var paced_summon := DataRegistry.get_tower_branch(&"slow_power").level_7_modifiers
	_check(is_equal_approx(CombatPace.ATTACK_SPEED_SCALE, 0.5) and is_equal_approx(CombatPace.ATTACK_DAMAGE_SCALE, 2.0) and is_equal_approx(CombatPace.MOVEMENT_SPEED_SCALE, 0.5) and is_equal_approx(CombatPace.ENEMY_MOVEMENT_SPEED_SCALE, 1.0), "the combat pace contract must separate defender and enemy movement speeds")
	_check(is_equal_approx(paced_tower.damage, 24.0) and is_equal_approx(paced_tower.attack_interval, 0.92) and is_equal_approx(paced_tower.damage / paced_tower.attack_interval, 12.0 / 0.46), "tower catalog pacing must preserve unarmored DPS with half as many attacks")
	_check(is_equal_approx(paced_chain_tower.damage, 52.0) and is_equal_approx(paced_chain_tower.attack_interval, 2.0), "chain tower pacing must preserve the tuned sustained-network damage baseline")
	_check(is_equal_approx(paced_core.damage, 26.0) and is_equal_approx(paced_core.attack_interval, 1.30) and is_equal_approx(paced_cursor.damage, 32.0) and is_equal_approx(paced_cursor.attack_interval, 0.34), "core and cursor normal attacks must use the same global pace and damage compensation")
	_check(is_equal_approx(paced_cursor.movement_speed, 235.0) and is_equal_approx(paced_enemy.move_speed, 58.0), "defender movement must remain halved while spawned enemies retain source speed")
	_check(is_equal_approx(paced_boss.move_speed, 30.0), "boss movement must use the enemy pace and be twice the previous paced speed")
	_check(is_equal_approx(paced_enemy.move_speed * default_stage.speed_multiplier_at(1.0) * ChallengeRules.enemy_speed_multiplier(10), 103.385), "stage progression and challenge speed multipliers must still stack after the restored enemy pace")
	_check(is_equal_approx(float(paced_summon.summon_damage), 84.0) and is_equal_approx(float(paced_summon.summon_interval), 1.10) and is_equal_approx(paced_boss.core_damage, 56.0) and is_equal_approx(CombatPace.attack_interval(1.2), 2.4), "independent summon attacks and repeated boss breaches must follow the global attack pace and damage compensation")
	var cursor_texture_paths: Dictionary = {}
	for cursor_data in DataRegistry.cursors:
		_check(cursor_data.texture != null, "every target cursor type must load its own generated image: %s" % cursor_data.id)
		if cursor_data.texture != null:
			cursor_texture_paths[cursor_data.texture.resource_path] = true
	_check(cursor_texture_paths.size() == 5, "all five target cursor types must use distinct image resources")
	_check(DataRegistry.towers.size() == 15, "tower catalog must contain nine regular and six candidate-exclusive guard unit types")
	var tower_hit_styles: Dictionary = {}
	for tower_data in DataRegistry.towers:
		var hit_effect := CombatEffect.new()
		host.add_child(hit_effect)
		hit_effect.setup_tower_hit(Vector2.ZERO, tower_data.color, tower_data.behavior, Vector2.RIGHT, 0.5, 28.0)
		tower_hit_styles[hit_effect.effect_style] = true
		_check(hit_effect.effect_style == StringName("hit_%s" % tower_data.behavior), "tower hits must route to their own generated effect profile: %s" % tower_data.id)
		hit_effect.queue_free()
	_check(tower_hit_styles.size() >= 12, "regular and core-exclusive tower attacks must retain the complete hit effect style set")
	var candidate_effect_styles: Dictionary = {}
	for effect_id in [&"jiane_dream_barrier", &"judaginda_verdict_seal"]:
		var candidate_effect_texture := ConceptService.optional_content_texture(&"effects", effect_id)
		var candidate_effect := CombatEffect.new()
		host.add_child(candidate_effect)
		candidate_effect.setup_candidate_stamp(Vector2.ZERO, candidate_effect_texture, Color.WHITE, 64.0, effect_id, 0.8, 0.6)
		candidate_effect_styles[candidate_effect.effect_style] = candidate_effect.stamp_texture
		_check(candidate_effect.stamp_texture == candidate_effect_texture and candidate_effect.effect_style == effect_id, "candidate presentation '%s' must preserve its dedicated texture and effect style" % effect_id)
		candidate_effect.queue_free()
	_check(candidate_effect_styles.size() == 2, "Jiane protection and Judaginda execution must expose two distinct runtime effect styles")
	_check(DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return &"reinforcement" in formation.role_tags).size() == 1, "formation catalog must expose exactly one hidden candidate-trait reinforcement recipe")
	var regular_cell_formations := DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique())
	var two_dimensional_formations := regular_cell_formations.filter(func(formation: TowerFormationData) -> bool: return formation.get_bounds().size.x > 1 and formation.get_bounds().size.y > 1)
	var formation_sizes: Dictionary = {}
	for formation in regular_cell_formations:
		formation_sizes[formation.cells.size()] = int(formation_sizes.get(formation.cells.size(), 0)) + 1
	_check(two_dimensional_formations.size() == 22, "the regular catalog must retain 22 executable two-dimensional formations")
	_check(regular_cell_formations.all(func(formation: TowerFormationData) -> bool: return not FormationBoardState.new().valid_placements(formation).is_empty()), "every regular formation must remain placeable on an empty 4x6 board")
	var formation_score_ranges := {2: Vector2i(140, 240), 3: Vector2i(230, 330), 4: Vector2i(300, 400)}
	var formation_scores_in_range := true
	for formation in regular_cell_formations:
		var score_range := formation_score_ranges.get(formation.cells.size(), Vector2i.ZERO) as Vector2i
		if formation.formation_score < score_range.x or formation.formation_score > score_range.y:
			formation_scores_in_range = false
	_check(formation_scores_in_range, "every reviewed regular formation must stay inside the v0.14 raw score guide for its block size")
	var execution_formation := DataRegistry.get_formation(&"execution")
	_check(execution_formation.cells.size() == 2 and execution_formation.formation_score == 230, "execution-mark formation must use the documented 140+90 two-cell recipe")
	_check(not TowerFormationData.new().get_property_list().any(func(property: Dictionary) -> bool: return String(property.name) == "tower_ids"), "formation content must expose cells as its only defender-layout schema")
	_check(DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique()).all(func(formation: TowerFormationData) -> bool: return absi(formation.get_normalized_power(DataRegistry.FORMATION_TARGET_POWER) - 100) <= 1), "regular formation normalization must keep every repeatable recipe near the same expected budget")
	var guard_formations := DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return formation.is_unique())
	_check(guard_formations.filter(func(formation: TowerFormationData) -> bool: return formation.id != &"emerald_guard_reinforcement").all(func(formation: TowerFormationData) -> bool: return absi(formation.get_normalized_power(DataRegistry.FORMATION_TARGET_POWER) - 120) <= 1), "starting guard formations must share the same 120-percent power budget")
	_check(absi(DataRegistry.get_formation(&"emerald_guard_reinforcement").get_normalized_power(DataRegistry.FORMATION_TARGET_POWER) - 60) <= 1, "the optional two-cell royal reinforcement must use half a starting guard power budget")
	_check(DataRegistry.get_formation(&"emerald_guard").cells.size() == 4 and DataRegistry.get_formation(&"emerald_guard").get_bounds().size == Vector2i(1, 4), "Partason's v0.10 royal guard must occupy a vertical four-cell column")
	_check(DataRegistry.get_formation(&"sapphire_spearhead").cells.size() == 4 and DataRegistry.get_formation(&"sapphire_spearhead").get_bounds().size == Vector2i(2, 4), "Jiane's v0.10 fanatic guard must occupy its staggered four-cell shape")
	_check(DataRegistry.get_formation(&"amethyst_bastion").cells.size() == 4 and DataRegistry.get_formation(&"amethyst_bastion").get_bounds().size == Vector2i(2, 2), "Kasuha's v0.10 abyss guard must occupy a two-by-two four-cell block")
	_check(DataRegistry.get_formation(&"jade_gambit").cells.size() == 6 and DataRegistry.get_formation(&"jade_gambit").get_bounds().size == Vector2i(2, 4) and DataRegistry.get_formation(&"jade_gambit").get_shape_errors().is_empty(), "Irelai's v0.10 resurrected guard must occupy six cells in its documented two-by-four sparse block")
	var judaginda_formation := DataRegistry.get_formation(&"obsidian_tribunal")
	var judaginda_layout: Dictionary = {}
	for guard_cell in judaginda_formation.cells:
		judaginda_layout[guard_cell.offset] = guard_cell.tower_id
	_check(judaginda_formation.cells.size() == 4 and judaginda_formation.get_bounds().size == Vector2i(2, 2) and judaginda_formation.get_tower_ids().count(&"obsidian_inquisitor") == 2 and judaginda_formation.get_tower_ids().count(&"obsidian_verdict") == 2 and not &"execute" in judaginda_formation.get_tower_ids(), "Judaginda's execution guard must occupy a two-by-two block made only from Death Church guards")
	_check(judaginda_layout.get(Vector2i(0, 0)) == &"obsidian_inquisitor" and judaginda_layout.get(Vector2i(0, 1)) == &"obsidian_inquisitor" and judaginda_layout.get(Vector2i(1, 0)) == &"obsidian_verdict" and judaginda_layout.get(Vector2i(1, 1)) == &"obsidian_verdict", "Judaginda's rear column must use ranged inquisitors and its front column melee judges")
	_check(guard_formations.filter(func(formation: TowerFormationData) -> bool: return formation.id != &"emerald_guard_reinforcement").all(func(formation: TowerFormationData) -> bool: return formation.cells.size() in [4, 6]), "all five v0.10 starting guards must use their candidate-specific four- or six-cell templates")
	_check(DataRegistry.get_tower(&"sapphire_lance").attack_range_cells >= 5.0 and DataRegistry.get_tower(&"jade_roulette").attack_range_cells >= 4.0, "long-line and multi-target guard towers must retain the audited battlefield reach needed to express their roles")
	_check(DataRegistry.tower_branches.size() == 27, "all nine tower types must each expose three level-4 branches")
	_check(DataRegistry.specialization_branches.size() == 30, "five cores and five cursors must expose 30 owner-specific specialization branches")
	_check(DataRegistry.get_tower_branch(&"rapid_burn").display_name == "고블린 수 증가" and int(DataRegistry.get_tower_branch(&"rapid_burn").level_7_modifiers.get("volley_shots", 0)) == 3, "goblin numbers branch must produce a bounded three-shot final volley")
	_check(DataRegistry.get_tower_branch(&"rapid_ricochet").level_7_modifiers.has_all(["damage", "range", "speed", "warcry_interval", "warcry_damage"]) and DataRegistry.get_tower_branch(&"rapid_mark").level_7_modifiers.has_all(["tactics_cycle", "tactics_mark", "tactics_bleed_ratio", "tactics_poison_damage", "tactics_poison_chance"]), "elite and tactics goblins must expose their documented vertical and poison-or-bleed support contracts")
	_check(DataRegistry.get_tower_branch(&"area_power").level_7_modifiers.has_all(["fire_zone_duration", "fire_zone_radius", "fire_zone_burn_ratio"]), "skeleton firebomb branch must expose a persistent once-per-zone burn contract")
	_check(int(DataRegistry.get_tower_branch(&"area_shrapnel").level_7_modifiers.get("bone_shard_count", 0)) == 8 and bool(DataRegistry.get_tower_branch(&"area_stun").level_7_modifiers.get("shock", false)), "skeleton bone-bomb and lightning branches must preserve bounded projectile spread and shock synergy")
	_check(DataRegistry.get_tower_branch(&"pierce_power").display_name == "장궁부대" and float(DataRegistry.get_tower_branch(&"pierce_power").level_7_modifiers.range) >= 1.9, "longbow orcs must exchange attack speed for substantially longer piercing range")
	_check(int(DataRegistry.get_tower_branch(&"pierce_execute").level_7_modifiers.get("power_shot_hits", 0)) == 5 and bool(DataRegistry.get_tower_branch(&"pierce_rail").level_7_modifiers.get("explosive_arrow", false)), "high-orc power shots and explosive-rune arrows must preserve their distinct attack conversions")
	_check(float(DataRegistry.get_tower_branch(&"execute_power").level_7_modifiers.get("speed", 1.0)) > 2.0 and bool(DataRegistry.get_tower_branch(&"execute_threshold").level_7_modifiers.get("armor_pierce", false)), "loader and armor-piercing troll branches must preserve single-target sniper identity")
	_check(int(DataRegistry.get_tower_branch(&"execute_cycle").level_7_modifiers.get("ricochet_count", 0)) == 3, "troll ricochet final trait must preserve its documented three-target propagation behavior")
	_check(DataRegistry.get_tower_branch(&"slow_power").level_7_modifiers.has_all(["sacrifice_required", "summon_cap", "summon_duration", "summon_damage"]) and int(DataRegistry.get_tower_branch(&"slow_power").level_7_modifiers.summon_cap) == 2, "abyss sacrifice ritual must expose a bounded summon contract")
	_check(int(DataRegistry.get_tower_branch(&"slow_lock").level_7_modifiers.get("erosion_cycle", 0)) == 4 and float(DataRegistry.get_tower_branch(&"slow_range").level_7_modifiers.get("slow_multiplier", 1.0)) >= 1.5, "abyss erosion and giant-pillar branches must preserve their control identities")
	_check(float(DataRegistry.get_tower_branch(&"mark_amp").level_7_modifiers.get("hex_slow", 0.0)) > 0.0 and float(DataRegistry.get_tower_branch(&"mark_amp").level_7_modifiers.get("mark_duration", 0.0)) >= 8.0, "shock-and-fear hexers must combine long vulnerability with control")
	_check(float(DataRegistry.get_tower_branch(&"mark_power").level_7_modifiers.get("mark", 0.0)) >= 0.6 and float(DataRegistry.get_tower_branch(&"mark_power").level_7_modifiers.get("mark_duration", 99.0)) < 3.0, "weakness exposure must trade duration for substantially stronger vulnerability")
	_check(float(DataRegistry.get_tower_branch(&"mark_spread").level_7_modifiers.get("speed", 1.0)) >= 2.5 and float(DataRegistry.get_tower_branch(&"mark_spread").level_7_modifiers.get("mark_duration", 0.0)) >= 7.5, "shift-work hexers must rotate long marks at substantially higher cadence")
	_check(float(DataRegistry.get_tower_branch(&"chain_power").level_7_modifiers.get("network_damage_per_relay", 0.0)) == 0.16 and float(DataRegistry.get_tower_branch(&"chain_power").level_7_modifiers.get("damage", 0.0)) == 1.65, "high-voltage relays must strengthen both base beam damage and bounded network growth")
	_check(float(DataRegistry.get_tower_branch(&"chain_cycle").level_7_modifiers.get("relay_return", 0.0)) == 0.52 and float(DataRegistry.get_tower_branch(&"chain_cycle").level_7_modifiers.get("relay_return_falloff", 0.0)) == 0.94 and float(DataRegistry.get_tower_branch(&"chain_mark").level_7_modifiers.get("speed", 0.0)) == 2.0, "resonance and superconducting relays must retain distinct return-beam and cadence contracts")
	_check(float(DataRegistry.get_tower_branch(&"push_force").level_7_modifiers.get("speed", 1.0)) >= 3.0 and int(DataRegistry.get_tower_branch(&"push_force").level_7_modifiers.get("overheat_cycle", 0)) > 0, "KI-II turbo engine must trade extreme rotation speed for periodic overheat")
	_check(int(DataRegistry.get_tower_branch(&"push_mark").level_7_modifiers.get("saw_fixed", 0)) == 1 and float(DataRegistry.get_tower_branch(&"push_mark").level_7_modifiers.get("saw_size", 1.0)) >= 2.0 and int(DataRegistry.get_tower_branch(&"push_wave").level_7_modifiers.get("saw_fixed", 0)) == 8, "KI-II alternate chassis must expose one giant saw or exactly eight covering saws")
	for core_data in DataRegistry.cores:
		var core_specializations := DataRegistry.get_specialization_branches(&"core", core_data.id)
		_check(core_specializations.size() == 3 and core_specializations.all(func(branch: SpecializationBranchData) -> bool: return branch.owner_id == core_data.id), "every core must expose exactly three unique specializations: %s" % core_data.id)
		var unique_tower := DataRegistry.get_tower(core_data.unique_tower_id)
		var unique_formation := DataRegistry.get_formation(core_data.unique_formation_id)
		_check(unique_tower.is_unique() and unique_tower.unique_core_id == core_data.id and unique_tower.max_level == 1 and unique_tower.id in unique_formation.get_tower_ids() and unique_formation.unique_core_id == core_data.id, "every core must own one fixed-level unique tower and a matching unique formation: %s" % core_data.id)
	for cursor_data in DataRegistry.cursors:
		var cursor_specializations := DataRegistry.get_specialization_branches(&"cursor", cursor_data.id)
		_check(cursor_specializations.size() == 3 and cursor_specializations.all(func(branch: SpecializationBranchData) -> bool: return branch.owner_id == cursor_data.id), "every cursor must expose exactly three unique specializations: %s" % cursor_data.id)
	_check(DataRegistry.specialization_branches.all(func(branch: SpecializationBranchData) -> bool: return not branch.level_4_description.is_empty() and not branch.level_7_description.is_empty() and not branch.level_4_modifiers.is_empty() and not branch.level_7_modifiers.is_empty()), "every owner-specific branch must define both level-4 and level-7 gameplay data and descriptions")
	var specialization_router := LoadoutManager.new()
	host.add_child(specialization_router)
	for core_data in DataRegistry.cores:
		specialization_router.core_state = GrowthTrackState.new(core_data.id)
		specialization_router.core_state.current_level = 3
		var routed_core_choices := specialization_router._track_branch_choices(false)
		_check(routed_core_choices.size() == 3 and routed_core_choices.all(func(choice: UpgradeData) -> bool: return DataRegistry.get_specialization_branch(choice.data_id).owner_id == core_data.id), "core choice routing must use the selected core id: %s" % core_data.id)
	for cursor_data in DataRegistry.cursors:
		specialization_router.cursor_state = GrowthTrackState.new(cursor_data.id)
		specialization_router.cursor_state.current_level = 3
		var routed_cursor_choices := specialization_router._track_branch_choices(true)
		_check(routed_cursor_choices.size() == 3 and routed_cursor_choices.all(func(choice: UpgradeData) -> bool: return DataRegistry.get_specialization_branch(choice.data_id).owner_id == cursor_data.id), "cursor choice routing must use the selected cursor id: %s" % cursor_data.id)
	specialization_router.queue_free()
	var formation_tower_ids: Dictionary = {}
	for formation_data in DataRegistry.formations:
		for tower_id in formation_data.get_tower_ids():
			if tower_id != &"":
				formation_tower_ids[tower_id] = true
	for tower_data in DataRegistry.towers:
		_check(formation_tower_ids.has(tower_data.id), "every tower must be reachable through a formation: %s" % tower_data.id)
		_check(tower_data.formation_power_rating > 0.0, "every tower must have a quantified formation power rating: %s" % tower_data.id)
		var tower_branch_count := DataRegistry.tower_branches.filter(func(branch: TowerBranchData) -> bool: return branch.tower_id == tower_data.id).size()
		_check(tower_branch_count == (0 if tower_data.is_unique() else 3), "regular towers need three branches while fixed unique towers need none: %s" % tower_data.id)
	_check(is_equal_approx(DataRegistry.get_tower(&"rapid").attack_range_cells, 1.0), "normal rapid tower must start with a 1-cell acquisition range")
	_check(DataRegistry.get_tower(&"knockback").attack_range_cells <= DataRegistry.get_tower(&"rapid").attack_range_cells, "knockback tower must retain the documented short role-specific range")
	_check(DataRegistry.get_tower(&"area").attack_range_cells > DataRegistry.get_tower(&"rapid").attack_range_cells, "area tower must have a wider role-specific range")
	_check(DataRegistry.get_tower(&"pierce").attack_range_cells > DataRegistry.get_tower(&"area").attack_range_cells * 2.0, "sniper tower must have a distinctly long role-specific range")
	_check(DataRegistry.get_cursor(&"iron").attack_radius <= 64.0 and DataRegistry.get_cursor(&"iron").knockback >= 48.0, "target cursors must trade a narrower base area for stronger focused control")
	_check(DataRegistry.get_cursor(&"gold").attack_radius < 100.0 and DataRegistry.get_cursor(&"gold").knockback > 0.0, "even the zone cursor must use a focused controllable base footprint")
	_check(DataRegistry.bosses.size() == 5, "boss catalog must contain five candidate bosses while runtime plans keep four milestones")
	var final_boss_data := DataRegistry.get_enemy(&"final_boss")
	var final_stage_data := load("res://data/stages/standard_20m.tres") as StageData
	_check(final_stage_data.artifact_elite_times() == [120.0, 240.0, 360.0, 480.0] and final_stage_data.artifact_elite_enemy_id == &"steel_golem", "the standard run must schedule exactly four artifact elites at two-minute intervals before the final boss")
	_check(final_stage_data.artifact_elite_health_multipliers == [3.0, 5.0, 8.0, 12.0], "artifact elite health tiers must increase monotonically across the run")
	var artifact_elite_spawner := EnemySpawner.new()
	host.add_child(artifact_elite_spawner)
	var artifact_elite_spawns: Array[Dictionary] = []
	artifact_elite_spawner.spawn_requested.connect(func(_ratio: float, enemy_data: EnemyData, health_multiplier: float, _speed_multiplier: float, context: EnemySpawnContext) -> void:
		if context != null and context.is_artifact_elite():
			artifact_elite_spawns.append({"enemy": enemy_data, "health_multiplier": health_multiplier, "context": context})
	)
	artifact_elite_spawner.start(final_stage_data, DataRegistry.enemies, DataRegistry.bosses, Battlefield.LANE_COUNT, 0, null, DataRegistry.faction_enemies, true)
	artifact_elite_spawner.set_regular_schedule_enabled(false)
	artifact_elite_spawner.set_boss_schedule_enabled(false)
	artifact_elite_spawner.set_physics_process(false)
	artifact_elite_spawner._physics_process(480.0)
	var artifact_elite_tiers := artifact_elite_spawns.map(func(entry: Dictionary) -> int: return (entry.context as EnemySpawnContext).artifact_reward_tier)
	_check(artifact_elite_spawns.size() == 4 and artifact_elite_tiers == [1, 2, 3, 4], "crossing the four schedule boundaries must emit each artifact elite once and in tier order")
	_check(artifact_elite_spawns.all(func(entry: Dictionary) -> bool:
		var enemy_data := entry.enemy as EnemyData
		var context := entry.context as EnemySpawnContext
		return enemy_data != null and enemy_data.is_elite and not enemy_data.is_boss and context.get_validation_errors().is_empty()
	), "scheduled artifact carriers must remain non-boss elites with explicit valid encounter metadata")
	var first_elite_multiplier := final_stage_data.health_multiplier_at(0.2) * 3.0
	var fourth_elite_multiplier := final_stage_data.health_multiplier_at(0.8) * 12.0
	_check(is_equal_approx(float(artifact_elite_spawns[0].health_multiplier), first_elite_multiplier) and is_equal_approx(float(artifact_elite_spawns[3].health_multiplier), fourth_elite_multiplier), "artifact elite health must combine stage-time growth with its explicit tier curve")
	artifact_elite_spawner._physics_process(120.0)
	_check(artifact_elite_spawns.size() == 4, "the 600-second final boss boundary must not emit a fifth artifact elite")
	artifact_elite_spawner.stop()
	artifact_elite_spawner.queue_free()
	var challenge_spawner := EnemySpawner.new()
	host.add_child(challenge_spawner)
	challenge_spawner.start(final_stage_data, DataRegistry.enemies, DataRegistry.bosses, Battlefield.LANE_COUNT, 10)
	var challenge_spawn_limits := challenge_spawner.spawn_director.phase_limits(0.0)
	var opening_spawn_phase := final_stage_data.spawn_phases[0]
	_check(challenge_spawner.challenge_level == 10 and is_equal_approx(float(challenge_spawn_limits.max_packet_cost), opening_spawn_phase.max_packet_cost * ChallengeRules.spawn_rate_multiplier(10)) and is_equal_approx(float(challenge_spawn_limits.target_alive_pressure), opening_spawn_phase.target_alive_pressure * ChallengeRules.spawn_rate_multiplier(10)), "enemy spawner must migrate challenge acceleration to packet and target-pressure budgets from the beginning of a run")
	challenge_spawner.stop()
	challenge_spawner.queue_free()
	var representative_boss_dps := 750.0
	var final_boss_target_ttk := final_boss_data.max_health * final_stage_data.final_health_multiplier / representative_boss_dps
	_check(final_boss_target_ttk >= 45.0 and final_boss_target_ttk <= 55.0, "final boss runtime health must fit the calculated 45-55 second kill window for a representative level-25 build")
	_check(final_stage_data.boss_health_multiplier_at(0.25) < final_stage_data.health_multiplier_at(0.25), "early bosses must use a gentler back-loaded health curve than regular enemies")
	_check(is_equal_approx(final_stage_data.boss_health_multiplier_at(1.0), final_stage_data.final_health_multiplier), "the boss health curve must preserve the final boss target health")
	_check(final_boss_data.armor <= 12.0 and final_boss_data.status_resistance <= 0.56 and final_boss_data.knockback_resistance <= 0.87, "final boss defenses must leave rapid, status, and control builds meaningful counterplay")
	var enemy_texture_paths: Dictionary = {}
	for enemy_data in DataRegistry.enemies + DataRegistry.bosses:
		_check(enemy_data.texture != null, "every enemy archetype must have a dedicated texture: %s" % enemy_data.id)
		if enemy_data.texture != null:
			enemy_texture_paths[enemy_data.texture.resource_path] = true
	_check(enemy_texture_paths.size() >= 11, "the active common-enemy and boss catalogs must retain distinct art apart from the approved boss alias")
	var experience_observation := {"count": 0, "current": 0.0, "level": 0}
	var observed_experience := ExperienceManager.new()
	host.add_child(observed_experience)
	observed_experience.experience_changed.connect(func(current: float, _required: float, level: int) -> void:
		experience_observation.count += 1
		experience_observation.current = current
		experience_observation.level = level
	)
	observed_experience.reset()
	experience_observation.count = 0
	observed_experience.add_experience(1.0)
	_check(experience_observation.count == 1 and is_equal_approx(experience_observation.current, 1.0), "ordinary experience gains must refresh the HUD before a level-up")
	observed_experience.queue_free()
	var late_curve_experience := ExperienceManager.new()
	host.add_child(late_curve_experience)
	late_curve_experience.reset()
	_check(is_equal_approx(late_curve_experience._required_for(24), 160.0) and is_equal_approx(late_curve_experience._required_for(25), 281.35), "the late experience curve must preserve levels through 24 and begin its audited ramp at level 25")
	late_curve_experience.add_experience(12742.2)
	_check(late_curve_experience.level == 30 and late_curve_experience.current_experience < late_curve_experience.required_experience, "the approved full-run experience ceiling must remain at the upper edge of the level-25 target band")
	late_curve_experience.queue_free()
	var uncapped_experience := ExperienceManager.new()
	host.add_child(uncapped_experience)
	uncapped_experience.reset()
	uncapped_experience.add_experience(1000000.0)
	_check(uncapped_experience.level > 25, "experience progression must continue beyond the former level-25 cap")
	_check(uncapped_experience.current_experience < uncapped_experience.required_experience, "uncapped experience processing must retain a valid progress-bar remainder")
	uncapped_experience.queue_free()
	var metric_sample := RunMetrics.new()
	metric_sample.record_tower_hit(&"area", 120.0, 3)
	_check(int(metric_sample.tower_kills.get("area", 0)) == 3, "multi-target tower attacks must record every kill")
	metric_sample.record_tower_attack(&"obsidian_verdict", &"obsidian_tribunal")
	metric_sample.record_tower_hit(&"obsidian_verdict", 180.0, 2, 3, 0, &"obsidian_tribunal", 3)
	var guard_combat_sample := metric_sample.guard_combat.get("obsidian_tribunal", {}) as Dictionary
	var guard_tower_combat_sample := (guard_combat_sample.by_tower as Dictionary).get("obsidian_verdict", {}) as Dictionary
	_check(int(guard_combat_sample.attacks) == 1 and is_equal_approx(float(guard_combat_sample.damage), 180.0) and int(guard_combat_sample.kills) == 2 and int(guard_combat_sample.control_applications) == 3 and is_equal_approx(float(guard_tower_combat_sample.damage), 180.0), "guard combat metrics must remain separate from shared tower ids and retain per-tower attribution")
	metric_sample.configure_lanes(2)
	_check(metric_sample.lane_spawns.size() == 2 and metric_sample.lane_reaches.size() == 2 and metric_sample.cursor_lane_seconds.size() == 2, "run metrics lane arrays must follow the configured battlefield")
	metric_sample.record_runtime_frame(0.05, 1.0 / 60.0, 3.0)
	metric_sample.record_runtime_frame(0.12, 0.04, 3.0)
	metric_sample.record_scene_load(24, 18, 31, 7, 9)
	metric_sample.record_mechanic_event(&"combo_targets", 4.0)
	metric_sample.record_mechanic_sample(&"vanguard_members", 3.0)
	metric_sample.record_mechanic_sample(&"vanguard_members", 1.0)
	var performance_snapshot := metric_sample._runtime_performance_snapshot()
	var mechanic_averages := metric_sample._mechanic_sample_averages()
	_check(int(performance_snapshot.frame_count) == 2 and int(performance_snapshot.frames_over_33_ms) == 1 and int(performance_snapshot.peak_active_enemies) == 24 and int(performance_snapshot.peak_summons) == 7 and int(performance_snapshot.peak_summon_budget_cost) == 9, "runtime metrics must retain frame-budget overruns, summon pressure, and peak scene load for 3x audits")
	_check(is_equal_approx(float(metric_sample.mechanic_totals.combo_targets), 4.0) and is_equal_approx(float(mechanic_averages.vanguard_members), 2.0), "candidate mechanic metrics must retain event totals and sampled operating averages")
	metric_sample.free()
