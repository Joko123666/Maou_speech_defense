class_name V015FactionEnemyContractTest
extends RefCounted

static func run(host: Node) -> Array[String]:
	var failures: Array[String] = []
	var faction_ids: Array[StringName] = []
	faction_ids.assign(DataRegistry.faction_enemies.map(func(enemy: EnemyData) -> StringName: return enemy.id))
	_expect(DataRegistry.faction_enemies.size() == 5 and _same_ids(faction_ids, EnemyCatalogV015.FACTION_IDS), "M3 must expose exactly one runtime EnemyData per candidate faction", failures)
	for enemy in DataRegistry.faction_enemies:
		var spawn_profile := DataRegistry.get_enemy_spawn_profile(enemy.id)
		_expect(spawn_profile != null and spawn_profile.is_faction_enemy and is_equal_approx(enemy.spawn_cost, spawn_profile.spawn_cost) and enemy.role_tags == spawn_profile.role_tags, "faction enemy '%s' must consume its staged spawn profile" % enemy.id, failures)

	var orc := DataRegistry.get_enemy(&"orc_shield")
	var shield := DataRegistry.get_enemy(&"partason_standard_shield")
	_expect(shield.max_health > orc.max_health and shield.move_speed > orc.move_speed and shield.knockback_resistance > orc.knockback_resistance, "Partason's standard shield must be a modest stat upgrade over the common orc frontline without an extra special action", failures)
	_expect(shield.behavior == &"faction_frontline" and shield.decay_profile == null and shield.death_effect_profile == null, "Partason's representative must express identity through stable frontline stats only", failures)

	_test_succubus_killer_contract(host, failures)
	_test_death_effect_service_contract(host, failures)
	_test_abyss_death_contract(host, failures)
	_test_formation_contracts(failures)
	_test_group_acceleration_contract(host, failures)
	return failures

static func _test_succubus_killer_contract(host: Node, failures: Array[String]) -> void:
	var succubus_data := DataRegistry.get_enemy(&"jiane_succubus_bewitcher")
	_expect(succubus_data.death_effect_profile != null and succubus_data.death_effect_profile.effect == &"disable_killer_normal_defender" and succubus_data.death_effect_profile.get_validation_errors().is_empty(), "Jiane's succubus must own an exact-killer defender-disable profile", failures)
	var column := _column_probe(host, false)
	var columns: Array[TowerColumn] = [column]
	var normal_context := EnemyDamageContext.normal_defender(column, 1, &"rapid")
	var normal_kill := _enemy_probe(host, succubus_data)
	var controller := GameController.new()
	controller._apply_tower_damage(normal_kill, 10000.0, &"rapid", false, column, 1, DataRegistry.get_tower(&"rapid"))
	var death_effect_service := EnemyDeathEffectService.new()
	var resolution := death_effect_service.resolve(succubus_data, normal_kill.global_position, normal_kill, columns)
	_expect(normal_kill.last_damage_context != null and bool(resolution.applied) and resolution.mechanic_id == EnemyDeathEffectService.KILLER_DISABLE_EVENT and resolution.targets == ["0:1:rapid"] and column.is_row_disabled(1) and normal_kill.last_death_cause == Enemy.DEATH_CAUSE_DIRECT_KILL, "the tower damage path must record a normal defender final blow and resolve exactly its row through the unified death-effect contract", failures)
	controller.free()

	var status_kill := _enemy_probe(host, succubus_data)
	status_kill.take_damage(1.0, &"rapid", false, normal_context)
	status_kill.take_damage(10000.0, &"common_burn", true)
	_expect(status_kill.last_damage_context == null and status_kill.last_death_cause == Enemy.DEATH_CAUSE_DAMAGE_OVER_TIME and not bool(death_effect_service.resolve(succubus_data, status_kill.global_position, status_kill, columns).applied), "a status final blow must clear an earlier defender context and never disable that defender", failures)

	var candidate_kill := _enemy_probe(host, succubus_data)
	candidate_kill.take_damage(10000.0, &"core")
	_expect(candidate_kill.last_damage_context == null and not bool(death_effect_service.resolve(succubus_data, candidate_kill.global_position, candidate_kill, columns).applied), "candidate, retainer, guard, status, and summon kills without a normal-defender context must not disable a defender", failures)

	var guard_column := _column_probe(host, true)
	var guard_columns: Array[TowerColumn] = [guard_column]
	var forged_guard_context := EnemyDamageContext.normal_defender(guard_column, 1, &"rapid")
	var guard_kill := _enemy_probe(host, succubus_data)
	guard_kill.take_damage(10000.0, &"guard_royal", false, forged_guard_context)
	_expect(not bool(death_effect_service.resolve(succubus_data, guard_kill.global_position, guard_kill, guard_columns).applied), "candidate guard rows must remain ineligible even if a malformed normal-defender context is supplied", failures)
	column.queue_free()
	guard_column.queue_free()

static func _test_death_effect_service_contract(host: Node, failures: Array[String]) -> void:
	var battlefield := Battlefield.new()
	battlefield.visible = false
	host.add_child(battlefield)
	var near_column := TowerColumn.new()
	var special_column := TowerColumn.new()
	var far_column := TowerColumn.new()
	for column in [near_column, special_column, far_column]:
		column.visible = false
		host.add_child(column)
	near_column.setup(2, 180.0, battlefield)
	special_column.setup(3, 180.0, battlefield)
	far_column.setup(5, 500.0, battlefield)
	near_column.row_towers.resize(Battlefield.LANE_COUNT)
	near_column.row_towers.fill(null)
	near_column.row_towers[1] = DataRegistry.get_tower(&"rapid")
	special_column.row_towers.resize(Battlefield.LANE_COUNT)
	special_column.row_towers.fill(null)
	special_column.row_towers[1] = DataRegistry.get_tower(&"unique_random")
	far_column.row_towers.resize(Battlefield.LANE_COUNT)
	far_column.row_towers.fill(null)
	far_column.row_towers[1] = DataRegistry.get_tower(&"rapid")
	var columns: Array[TowerColumn] = [near_column, special_column, far_column]
	var area_profile := EnemyDeathEffectProfileData.new()
	area_profile.effect = &"disable_normal_defenders"
	area_profile.radius = 40.0
	area_profile.duration = 3.25
	var area_enemy := EnemyData.new()
	area_enemy.id = &"contract_area_death"
	area_enemy.death_effect_profile = area_profile
	var service := EnemyDeathEffectService.new()
	var area_result := service.resolve(area_enemy, near_column.get_attack_origin(1), null, columns)
	_expect(bool(area_result.applied) and area_result.mechanic_id == EnemyDeathEffectService.AREA_DISABLE_EVENT and area_result.targets == ["2:1:rapid"] and is_equal_approx(float(area_result.duration), 3.25), "area death effects must return one stable metric target for each nearby normal defender", failures)
	_expect(near_column.is_row_disabled(1) and not special_column.is_row_disabled(1) and not far_column.is_row_disabled(1) and is_equal_approx(float(area_result.burst_radius), 40.0), "area death effects must exclude non-normal and distant defenders while preserving their presentation radius", failures)
	area_profile.radius = 0.0
	_expect(not bool(service.resolve(area_enemy, near_column.get_attack_origin(1), null, columns).applied) and not bool(service.resolve(null, Vector2.ZERO, null, columns).applied), "death effects must reject invalid profiles and missing enemy data without reporting false applications", failures)
	near_column.free()
	special_column.free()
	far_column.free()
	battlefield.free()

static func _test_abyss_death_contract(host: Node, failures: Array[String]) -> void:
	var abyss_data := DataRegistry.get_enemy(&"kasuha_abyss_creature")
	_expect(abyss_data.decay_profile != null and abyss_data.decay_profile.get_validation_errors().is_empty() and abyss_data.max_health > DataRegistry.get_enemy(&"steel_golem").max_health, "Kasuha's abyss creature must combine very high health with a finite self-decay profile", failures)
	var self_decay_reward := [0.0]
	var self_decay := _enemy_probe(host, abyss_data)
	self_decay.died.connect(func(value: float, _position: Vector2, _data: EnemyData, _lane: int) -> void: self_decay_reward[0] = value)
	self_decay._physics_process(abyss_data.decay_profile.lifetime_seconds + 0.01)
	_expect(self_decay.last_death_cause == Enemy.DEATH_CAUSE_SELF_DECAY and is_equal_approx(float(self_decay_reward[0]), abyss_data.experience_value), "self-decay and CC-delayed natural death must emit the full configured XP reward", failures)

	var direct_reward := [0.0]
	var direct := _enemy_probe(host, abyss_data)
	direct.died.connect(func(value: float, _position: Vector2, _data: EnemyData, _lane: int) -> void: direct_reward[0] = value)
	direct.take_damage(10000.0, &"core")
	_expect(direct.last_death_cause == Enemy.DEATH_CAUSE_DIRECT_KILL and is_equal_approx(float(direct_reward[0]), abyss_data.experience_value), "direct abyss-creature kills must retain 100 percent XP", failures)

	var dot_reward := [0.0]
	var dot := _enemy_probe(host, abyss_data)
	dot.died.connect(func(value: float, _position: Vector2, _data: EnemyData, _lane: int) -> void: dot_reward[0] = value)
	dot.take_damage(10000.0, &"common_poison", true)
	_expect(dot.last_death_cause == Enemy.DEATH_CAUSE_DAMAGE_OVER_TIME and is_equal_approx(float(dot_reward[0]), abyss_data.experience_value), "damage-over-time abyss-creature kills must retain 100 percent XP", failures)

	var breach_deaths := [0]
	var breach := _enemy_probe(host, abyss_data, Vector2(200.0, 100.0), Vector2(200.0, 100.0))
	breach.died.connect(func(_value: float, _position: Vector2, _data: EnemyData, _lane: int) -> void: breach_deaths[0] += 1)
	breach._physics_process(0.0)
	_expect(not breach.active and int(breach_deaths[0]) == 0 and breach.last_death_cause == Enemy.DEATH_CAUSE_NONE, "an abyss creature breach must remain a non-kill path with zero XP signal", failures)

static func _test_formation_contracts(failures: Array[String]) -> void:
	var cavalry := DataRegistry.get_enemy(&"irelai_skeleton_cavalry")
	var cavalry_profile := DataRegistry.get_enemy_spawn_profile(cavalry.id)
	var cavalry_tier_one := FactionEnemyFormationPlanner.build_contexts(cavalry, cavalry_profile, 1, 11, 0.5, 240.0)
	var cavalry_tier_two := FactionEnemyFormationPlanner.build_contexts(cavalry, cavalry_profile, 2, 12, 0.5, 380.0)
	var cavalry_tier_three := FactionEnemyFormationPlanner.build_contexts(cavalry, cavalry_profile, 3, 13, 0.5, 520.0)
	_expect(cavalry.formation_profile != null and cavalry.formation_profile.get_validation_errors().is_empty(), "Irelai cavalry must own a valid three-tier formation profile", failures)
	_expect(cavalry_tier_one.size() == 3 and _unique_values(cavalry_tier_one, &"cohort_id").size() == 1, "Irelai Tier 1 must spawn one simultaneous formation of at least three cavalry", failures)
	_expect(cavalry_tier_two.size() == 4 and _unique_values(cavalry_tier_two, &"cohort_id").size() == 2 and _unique_float_values(cavalry_tier_two, &"destination_y_ratio").size() > 1, "Irelai Tier 2 must support two reviewed forward axes", failures)
	_expect(cavalry_tier_three.size() == 6 and _unique_values(cavalry_tier_three, &"cohort_id").size() == 2 and cavalry_tier_three.any(func(context: EnemySpawnContext) -> bool: return context.wave_index == 1 and context.spawn_delay > 0.0), "Irelai Tier 3 must stage a second three-unit cavalry wave after a short delay", failures)

	var applicant := DataRegistry.get_enemy(&"judaginda_cult_applicant")
	var applicant_profile := DataRegistry.get_enemy_spawn_profile(applicant.id)
	var applicant_tier_one := FactionEnemyFormationPlanner.build_contexts(applicant, applicant_profile, 1, 21, 0.5, 240.0)
	var applicant_tier_three := FactionEnemyFormationPlanner.build_contexts(applicant, applicant_profile, 3, 22, 0.5, 520.0)
	_expect(applicant_tier_one.size() == 4 and _unique_values(applicant_tier_one, &"group_id").size() == 1, "Judaginda Tier 1 must spawn at least four applicants under one group id", failures)
	_expect(applicant_tier_three.size() == 8 and _unique_values(applicant_tier_three, &"group_id").size() == 2 and applicant_tier_three.any(func(context: EnemySpawnContext) -> bool: return is_equal_approx(context.spawn_delay, 1.5)), "Judaginda Tier 3 must separate two four-member groups by about 1.5 seconds", failures)
	_expect((cavalry_tier_one + cavalry_tier_two + cavalry_tier_three + applicant_tier_one + applicant_tier_three).all(func(context: EnemySpawnContext) -> bool: return context.get_validation_errors().is_empty()), "all M3 formation contexts must satisfy the SpawnContext schema", failures)

static func _test_group_acceleration_contract(host: Node, failures: Array[String]) -> void:
	var data := DataRegistry.get_enemy(&"judaginda_cult_applicant")
	_expect(data.group_acceleration_profile != null and data.group_acceleration_profile.maximum_stacks == 4 and is_equal_approx(data.group_acceleration_profile.get_maximum_speed_bonus(), 0.32) and is_equal_approx(data.group_acceleration_profile.duration, 4.0), "cult applicants must use +8 percent, four stacks, +32 percent maximum, and four-second expiry", failures)
	var source := _enemy_probe(host, data, Vector2(300.0, 100.0), Vector2(-10000.0, 100.0), 0.0)
	var same_group := _enemy_probe(host, data, Vector2(300.0, 120.0), Vector2(-10000.0, 120.0), 0.0)
	var other_group := _enemy_probe(host, data, Vector2(300.0, 140.0), Vector2(-10000.0, 140.0), 0.0)
	source.set_spawn_context(_group_context(data.id, &"group-a"))
	same_group.set_spawn_context(_group_context(data.id, &"group-a"))
	other_group.set_spawn_context(_group_context(data.id, &"group-b"))
	source.active = false
	var peers: Array[Enemy] = [same_group, other_group]
	var accelerated := FactionGroupAccelerationResolver.resolve(source, peers)
	_expect(accelerated == 1 and same_group.get_group_acceleration_stack_count() == 1 and other_group.get_group_acceleration_stack_count() == 0, "a cult death buff must affect surviving applicants in the same group and never cross group ids", failures)
	for _stack in 5:
		same_group.apply_same_group_death_acceleration()
	_expect(same_group.get_group_acceleration_stack_count() == 4 and is_equal_approx(same_group.get_group_acceleration_speed_bonus(), 0.32), "cult death acceleration must cap at four stacks and +32 percent", failures)
	same_group._physics_process(4.01)
	_expect(same_group.get_group_acceleration_stack_count() == 0 and is_zero_approx(same_group.get_group_acceleration_speed_bonus()), "cult death acceleration must expire back to normal speed", failures)

static func _enemy_probe(host: Node, data: EnemyData, spawn_position: Vector2 = Vector2(300.0, 100.0), target_position: Vector2 = Vector2.ZERO, speed_multiplier: float = 1.0) -> Enemy:
	var enemy := Enemy.new()
	host.add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.setup(data, spawn_position, 0, target_position, 1.0, speed_multiplier)
	return enemy

static func _column_probe(host: Node, guard: bool) -> TowerColumn:
	var column := TowerColumn.new()
	column.visible = false
	host.add_child(column)
	column.set_process(false)
	column.set_physics_process(false)
	column.row_towers.resize(Battlefield.LANE_COUNT)
	column.row_towers.fill(null)
	column.row_towers[1] = DataRegistry.get_tower(&"rapid")
	column.row_disabled_remaining.resize(Battlefield.LANE_COUNT)
	column.row_disabled_remaining.fill(0.0)
	column.is_guard_formation = guard
	return column

static func _group_context(enemy_id: StringName, group_id: StringName) -> EnemySpawnContext:
	var context := EnemySpawnContext.new()
	context.enemy_id = enemy_id
	context.faction_id = &"judaginda_faction"
	context.prelude_tier = 1
	context.group_id = group_id
	return context

static func _unique_values(contexts: Array[EnemySpawnContext], property: StringName) -> Dictionary:
	var result: Dictionary = {}
	for context in contexts:
		result[context.get(property)] = true
	return result

static func _unique_float_values(contexts: Array[EnemySpawnContext], property: StringName) -> Dictionary:
	var result: Dictionary = {}
	for context in contexts:
		result[roundi(float(context.get(property)) * 10000.0)] = true
	return result

static func _same_ids(left: Array[StringName], right: Array[StringName]) -> bool:
	var left_sorted := left.duplicate()
	var right_sorted := right.duplicate()
	left_sorted.sort()
	right_sorted.sort()
	return left_sorted == right_sorted

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
