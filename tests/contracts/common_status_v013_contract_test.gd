class_name CommonStatusV013ContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(CommonStatusCatalog.STATUS_IDS == [&"poison", &"bleed", &"shock", &"burn"], "v0.13 must expose the four common damage statuses in a stable order", failures)
	_expect(GameTypes.StatusType.has("POISON"), "poison must be part of the public runtime status vocabulary", failures)
	var poison_profile := CommonStatusCatalog.profile_at_level(&"poison", 0)
	_expect(int(poison_profile.max_stacks) == 3 and float(poison_profile.duration) >= 7.0, "base poison must have three shared initial stacks and a long duration", failures)
	_expect(int(CommonStatusCatalog.legacy_v010_profile_at_level(&"burn", 4).max_stacks) == 4 and int(CommonStatusCatalog.legacy_v010_profile_at_level(&"bleed", 7).max_stacks) == 12, "the v0.10 burn and bleed tuning baseline must remain reproducible for comparison", failures)

	var tactics_modifiers := {"tactics_poison_damage": 6.0, "tactics_bleed_ratio": 0.006}
	var fire_zone_modifiers := {"fire_zone_burn_ratio": 0.08}
	_expect(StatusSourceRegistry.branch_is_source(tactics_modifiers, &"poison") and StatusSourceRegistry.branch_is_source(tactics_modifiers, &"bleed"), "goblin tactics must qualify poison and bleed growth cards", failures)
	_expect(not StatusSourceRegistry.branch_applies_on_hit(tactics_modifiers, &"poison") and StatusSourceRegistry.branch_is_source(fire_zone_modifiers, &"burn") and not StatusSourceRegistry.branch_applies_on_hit(fire_zone_modifiers, &"burn"), "periodic status sources must not become automatic per-hit applications", failures)

	var poison_enemy := _enemy_at(Vector2.ZERO)
	_expect(poison_enemy.apply_common_poison(10.0, 7.0, 3), "the first poison stack must apply", failures)
	poison_enemy.apply_common_poison(10.0, 7.0, 3)
	poison_enemy.apply_common_poison(10.0, 7.0, 3)
	poison_enemy._update_common_ailments(1.0)
	var poison_health := poison_enemy.current_health
	poison_enemy.apply_common_poison(10.0, 7.0, 3)
	_expect(poison_enemy.get_common_ailment_stacks(&"poison") == 3 and is_equal_approx(float(poison_enemy.common_ailments[&"poison"].remaining), 7.0), "poison must share its stack cap and refresh duration at the cap", failures)
	poison_enemy._update_common_ailments(0.5)
	_expect(is_equal_approx(poison_health - poison_enemy.current_health, 15.0), "poison must deal fixed DPS for every shared stack", failures)

	var bleed_enemy := _enemy_at(Vector2.ZERO)
	bleed_enemy.apply_common_bleed(&"ki2_saw_bleed", 0.01, 4.5, 2, 1000.0)
	bleed_enemy.apply_common_bleed(&"ki2_saw_bleed", 0.01, 4.5, 2, 1000.0)
	bleed_enemy.apply_common_bleed(&"goblin_tactics_bleed", 0.02, 4.5, 2, 1000.0)
	bleed_enemy.apply_common_bleed(&"goblin_tactics_bleed", 0.02, 4.5, 2, 1000.0)
	bleed_enemy.apply_common_bleed(&"ki2_saw_bleed", 0.05, 4.5, 2, 1000.0)
	var bleed_health := bleed_enemy.current_health
	bleed_enemy._update_common_ailments(0.5)
	_expect(bleed_enemy.get_common_ailment_stacks(&"bleed") == 4 and bleed_enemy.get_common_ailment_source_count(&"bleed") == 2, "bleed must cap stacks independently for each stable source type", failures)
	_expect(is_equal_approx(bleed_health - bleed_enemy.current_health, 100.0), "bleed source stacks must preserve their own max-health damage ratios", failures)

	var burn_enemy := _enemy_at(Vector2.ZERO)
	burn_enemy.apply_common_burn(&"tower_a", 8.0, 4.0, 2)
	burn_enemy.apply_common_burn(&"tower_b", 4.0, 4.0, 2)
	var burn_health := burn_enemy.current_health
	burn_enemy._update_common_ailments(0.5)
	var first_burn_tick := burn_health - burn_enemy.current_health
	burn_health = burn_enemy.current_health
	burn_enemy._update_common_ailments(0.5)
	var second_burn_tick := burn_health - burn_enemy.current_health
	_expect(first_burn_tick > second_burn_tick and not burn_enemy.common_ailments[&"burn"].has("sources"), "burn must use source-agnostic stacks with front-loaded decay", failures)
	burn_enemy.apply_common_burn(&"tower_c", 6.0, 4.0, 2)
	_expect(is_zero_approx(float(burn_enemy.common_ailments[&"burn"].elapsed)), "burn reapplication must reset the decay timeline", failures)

	var shock_origin := _enemy_at(Vector2(0.0, 0.0))
	var shock_middle := _enemy_at(Vector2(50.0, 0.0))
	var shock_end := _enemy_at(Vector2(120.0, 0.0))
	shock_middle.apply_common_shock(4.0, 3)
	shock_end.apply_common_shock(4.0, 3)
	var shock_index := EnemySpatialIndex.new()
	shock_index.register_enemy(shock_origin)
	shock_index.register_enemy(shock_middle)
	shock_index.register_enemy(shock_end)
	var shock_service := TowerStatusApplicationService.new()
	shock_service.configure(null, null, shock_index, Callable())
	var origin_health := shock_origin.current_health
	var middle_health := shock_middle.current_health
	var end_health := shock_end.current_health
	var transferred := shock_service._resolve_shock_discharge(shock_origin, 100.0, 2, 80.0, 0.70)
	_expect(transferred == 2 and is_equal_approx(origin_health - shock_origin.current_health, 100.0) and is_equal_approx(middle_health - shock_middle.current_health, 70.0) and is_equal_approx(end_health - shock_end.current_health, 49.0), "shock must traverse an unvisited sequential chain with decaying snapshot damage", failures)
	_expect(shock_middle.get_common_ailment_stacks(&"shock") == 1 and shock_end.get_common_ailment_stacks(&"shock") == 1, "shock discharge must not create stacks or recurse on transfer targets", failures)

	var control_enemy := _enemy_at(Vector2.ZERO)
	control_enemy.apply_slow(&"weak_aura", 5.0, 0.25)
	control_enemy.apply_slow(&"strong_burst", 1.0, 0.50)
	_expect(is_equal_approx(float(control_enemy.statuses[&"slow"].power), 0.50), "only the strongest active slow source must affect movement", failures)
	control_enemy._update_statuses(1.1)
	_expect(is_equal_approx(float(control_enemy.statuses[&"slow"].power), 0.25), "a weaker slow source must resume after the stronger source expires", failures)
	_expect(control_enemy.apply_status(&"stun", 1.0, 1.0) and not control_enemy.apply_status(&"stun", 2.0, 1.0), "active stun must reject reapplication", failures)
	control_enemy._update_statuses(1.0)
	_expect(not control_enemy.apply_status(&"stun", 1.0, 1.0), "stun must resist reapplication during recovery", failures)
	control_enemy._update_control_recovery(0.35)
	_expect(control_enemy.apply_status(&"stun", 1.0, 1.0), "stun must become applicable after recovery", failures)
	var logic_1x := _status_logic_result(0.5)
	var logic_2x := _status_logic_result(0.25)
	var logic_3x := _status_logic_result(1.0 / 6.0)
	_expect(is_equal_approx(float(logic_1x.health), float(logic_2x.health)) and is_equal_approx(float(logic_1x.health), float(logic_3x.health)) and logic_1x.stacks == logic_2x.stacks and logic_1x.stacks == logic_3x.stacks, "common status logic must be frame-step equivalent for 1x, 2x, and 3x simulation cadences", failures)

	for enemy in [poison_enemy, bleed_enemy, burn_enemy, shock_origin, shock_middle, shock_end, control_enemy]:
		enemy.free()
	return failures

static func _enemy_at(position: Vector2) -> Enemy:
	var data := EnemyData.new()
	data.id = &"common_status_contract"
	data.max_health = 1000.0
	data.move_speed = 10.0
	data.core_damage = 1.0
	var enemy := Enemy.new()
	enemy.setup(data, position, 0, Vector2(-1000.0, position.y), 1.0, 1.0)
	return enemy

static func _status_logic_result(step: float) -> Dictionary:
	var enemy := _enemy_at(Vector2.ZERO)
	enemy.apply_common_poison(10.0, 5.0, 3)
	enemy.apply_common_poison(10.0, 5.0, 3)
	enemy.apply_common_burn(&"logic_burn", 8.0, 4.0, 1)
	enemy.apply_common_bleed(&"logic_bleed", 0.01, 3.0, 2, 1000.0)
	enemy.apply_common_bleed(&"logic_bleed", 0.01, 3.0, 2, 1000.0)
	enemy.apply_common_shock(4.0, 3)
	for _index in roundi(2.0 / step):
		enemy._update_common_ailments(step)
	var result := {
		"health": enemy.current_health,
		"stacks": {
			"poison": enemy.get_common_ailment_stacks(&"poison"),
			"burn": enemy.get_common_ailment_stacks(&"burn"),
			"bleed": enemy.get_common_ailment_stacks(&"bleed"),
			"shock": enemy.get_common_ailment_stacks(&"shock"),
		},
	}
	enemy.free()
	return result

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
