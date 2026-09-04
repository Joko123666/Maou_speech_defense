class_name EnemyRuntimeStateContractTest
extends RefCounted

var failures: Array[String] = []

static func run(host: Node) -> Array[String]:
	var contract := EnemyRuntimeStateContractTest.new()
	contract._run(host)
	return contract.failures

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run(host: Node) -> void:
	var damage_sample := Enemy.new()
	host.add_child(damage_sample)
	damage_sample.set_process(false)
	damage_sample.set_physics_process(false)
	damage_sample.setup(DataRegistry.enemies[0], Vector2(80.0, 80.0), 0, Vector2.ZERO, 1.0, 1.0)
	var damage_sample_health := damage_sample.current_health
	_check(is_zero_approx(damage_sample.take_damage(0.0)) and is_equal_approx(damage_sample.current_health, damage_sample_health), "zero damage must not bypass armor as a forced one-point hit")
	damage_sample.current_health = 2.0
	var recorded_overkill := damage_sample.take_damage(1000.0, &"test")
	_check(is_equal_approx(recorded_overkill, 2.0), "damage reporting must record actual health loss instead of overkill input")
	damage_sample.queue_free()
	var catch_up_core := DefenseCore.new()
	host.add_child(catch_up_core)
	catch_up_core.set_process(false)
	catch_up_core.set_physics_process(false)
	catch_up_core.configure(DataRegistry.cores[0])
	catch_up_core.attack_accumulator = 0.0
	var catch_up_attacks := {"count": 0}
	catch_up_core.attack_requested.connect(func(_data: CoreData) -> void: catch_up_attacks.count += 1)
	catch_up_core._physics_process(catch_up_core.data.attack_interval * 2.5)
	_check(catch_up_attacks.count == 2 and is_equal_approx(catch_up_core.attack_accumulator, catch_up_core.data.attack_interval * 0.5), "attack timers must preserve remainder and catch up independently of frame length")
	catch_up_core.queue_free()
	var burn_tick_enemy := Enemy.new()
	host.add_child(burn_tick_enemy)
	burn_tick_enemy.set_process(false)
	burn_tick_enemy.set_physics_process(false)
	burn_tick_enemy.setup(DataRegistry.enemies[0], Vector2(90.0, 90.0), 0, Vector2.ZERO, 1.0, 1.0)
	burn_tick_enemy.apply_status(&"burn", 2.0, 1.0)
	var burn_health_before := burn_tick_enemy.current_health
	burn_tick_enemy._update_statuses(1.1)
	_check(is_equal_approx(burn_health_before - burn_tick_enemy.current_health, 6.0) and is_equal_approx(burn_tick_enemy.burn_accumulator, 0.1), "damage-over-time ticks must catch up while preserving fractional time")
	burn_tick_enemy._update_statuses(1.0)
	_check(is_equal_approx(burn_health_before - burn_tick_enemy.current_health, 12.0) and not burn_tick_enemy.statuses.has(&"burn") and is_zero_approx(burn_tick_enemy.burn_accumulator), "an expiring damage-over-time status must apply every tick inside its duration even across a long frame")
	burn_tick_enemy.queue_free()
	var burn_death_enemy := Enemy.new()
	host.add_child(burn_death_enemy)
	burn_death_enemy.set_process(false)
	burn_death_enemy.set_physics_process(false)
	var burn_death_events := {"died": 0, "reached": 0}
	burn_death_enemy.died.connect(func(_value: float, _position: Vector2, _data: EnemyData, _lane: int) -> void: burn_death_events.died += 1)
	burn_death_enemy.reached_core.connect(func(_damage: float) -> void: burn_death_events.reached += 1)
	burn_death_enemy.setup(DataRegistry.enemies[0], Vector2(100.0, 100.0), 0, Vector2(100.0, 100.0), 1.0, 1.0)
	burn_death_enemy.current_health = 1.0
	burn_death_enemy.apply_status(&"burn", 2.0, 10.0)
	burn_death_enemy._physics_process(0.5)
	_check(burn_death_events.died == 1 and burn_death_events.reached == 0, "an enemy killed by status damage must not reach the core in the same frame")
	burn_death_enemy.queue_free()
	var status_policy_enemy := Enemy.new()
	host.add_child(status_policy_enemy)
	status_policy_enemy.set_process(false)
	status_policy_enemy.set_physics_process(false)
	status_policy_enemy.setup(DataRegistry.enemies[0], Vector2(102.0, 102.0), 0, Vector2.ZERO, 1.0, 1.0)
	_check(status_policy_enemy.apply_status(&"mark", 5.0, 0.6), "a first status application must succeed")
	_check(not status_policy_enemy.apply_status(&"mark", 10.0, 0.2) and is_equal_approx(float(status_policy_enemy.statuses[&"mark"].power), 0.6) and is_equal_approx(float(status_policy_enemy.statuses[&"mark"].remaining), 5.0), "a weaker status must not downgrade or extend a stronger active effect")
	_check(status_policy_enemy.apply_status(&"mark", 7.0, 0.6) and is_equal_approx(float(status_policy_enemy.statuses[&"mark"].remaining), 7.0), "an equal-strength status must refresh to the longer duration")
	_check(status_policy_enemy.apply_status(&"mark", 2.0, 0.8) and is_equal_approx(float(status_policy_enemy.statuses[&"mark"].power), 0.8) and is_equal_approx(float(status_policy_enemy.statuses[&"mark"].remaining), 2.0), "a stronger status must replace a weaker effect while preserving its intended shorter duration tradeoff")
	status_policy_enemy.queue_free()
	var resistant_buff_data := EnemyData.new()
	resistant_buff_data.id = &"resistant_buff_test"
	resistant_buff_data.max_health = 100.0
	resistant_buff_data.move_speed = 10.0
	resistant_buff_data.status_resistance = 0.75
	var resistant_buff_enemy := Enemy.new()
	host.add_child(resistant_buff_enemy)
	resistant_buff_enemy.set_process(false)
	resistant_buff_enemy.set_physics_process(false)
	resistant_buff_enemy.setup(resistant_buff_data, Vector2(104.0, 104.0), 0, Vector2.ZERO, 1.0, 1.0)
	resistant_buff_enemy.apply_status(&"haste", 4.0, 0.2)
	resistant_buff_enemy.apply_status(&"fortify", 4.0, 5.0)
	resistant_buff_enemy.apply_status(&"mark", 4.0, 0.4)
	resistant_buff_enemy.apply_common_shock(4.0, 3)
	_check(is_equal_approx(float(resistant_buff_enemy.statuses[&"haste"].remaining), 4.0) and is_equal_approx(float(resistant_buff_enemy.statuses[&"haste"].power), 0.2) and is_equal_approx(float(resistant_buff_enemy.statuses[&"fortify"].power), 5.0), "beneficial enemy statuses must not be weakened by status resistance")
	resistant_buff_enemy.clear_statuses()
	_check(resistant_buff_enemy.statuses.has(&"haste") and resistant_buff_enemy.statuses.has(&"fortify") and not resistant_buff_enemy.statuses.has(&"mark") and resistant_buff_enemy.common_ailments.is_empty() and not resistant_buff_enemy.has_negative_status_effect(), "enemy cleansing must remove negative and common ailments while preserving allied buffs")
	resistant_buff_enemy.queue_free()
	var status_manager := LoadoutManager.new()
	host.add_child(status_manager)
	status_manager.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "독 Lv.1", "test", &"poison"))
	status_manager.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "화상 Lv.1", "test", &"burn"))
	status_manager.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "출혈 Lv.1", "test", &"bleed"))
	status_manager.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "출혈 Lv.2", "test", &"bleed"))
	status_manager.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "감전 Lv.1", "test", &"shock"))
	var poison_profile := status_manager.get_common_status_profile(&"poison")
	var burn_profile := status_manager.get_common_status_profile(&"burn")
	var bleed_profile := status_manager.get_common_status_profile(&"bleed")
	var shock_profile := status_manager.get_common_status_profile(&"shock")
	_check(int(poison_profile.max_stacks) == 3 and float(poison_profile.damage_per_second) > 0.0, "poison upgrades must retain shared initial stacks and increase fixed damage")
	_check(int(burn_profile.max_stacks) == 1 and float(burn_profile.damage_ratio) > 0.0, "burn upgrades must increase attack-based damage before later stack milestones")
	_check(int(bleed_profile.max_stacks) == 2 and float(bleed_profile.health_ratio) >= 0.004, "bleed upgrades must increase max-health damage with source-specific stack capacity")
	_check(int(shock_profile.transfers) == 1 and int(shock_profile.max_stacks) == 3, "shock upgrades must preserve the three-stack base while increasing transfer count")
	_check(status_manager.get_selected_global_effects().size() == 4, "acquired common ailments must appear in the global effect summary")
	for next_level in range(3, 8):
		status_manager.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "출혈 Lv.%d" % next_level, "test", &"bleed"))
	var completed_bleed_profile := status_manager.get_common_status_profile(&"bleed")
	_check(status_manager.get_status_upgrade_level(&"bleed") == 7 and int(completed_bleed_profile.max_stacks) == 5 and float(completed_bleed_profile.health_ratio) >= 0.008, "common ailments must progress through seven levels and receive a level-7 completion bonus")
	_check(status_manager._status_upgrade_description(&"bleed", 4).contains("Lv.4 특화 보너스") and status_manager._status_upgrade_description(&"bleed", 7).contains("Lv.7 완성 보너스"), "status cards must explicitly announce their level-4 and level-7 milestone bonuses")
	status_manager.queue_free()
	var expiring_common_burn_enemy := Enemy.new()
	host.add_child(expiring_common_burn_enemy)
	expiring_common_burn_enemy.set_process(false)
	expiring_common_burn_enemy.set_physics_process(false)
	expiring_common_burn_enemy.setup(DataRegistry.enemies[0], Vector2(115.0, 115.0), 0, Vector2.ZERO, 10.0, 1.0)
	var expiring_common_burn_health := expiring_common_burn_enemy.current_health
	expiring_common_burn_enemy.apply_common_burn(&"tower_a", 3.0, 2.0, 1)
	expiring_common_burn_enemy._update_common_ailments(2.0)
	_check(expiring_common_burn_health > expiring_common_burn_enemy.current_health and not expiring_common_burn_enemy.has_common_ailment(&"burn") and is_zero_approx(expiring_common_burn_enemy.common_ailment_accumulator), "expiring common damage-over-time ailments must apply decaying ticks inside their duration across a long frame")
	expiring_common_burn_enemy.queue_free()
	var common_bleed_enemy := Enemy.new()
	host.add_child(common_bleed_enemy)
	common_bleed_enemy.set_process(false)
	common_bleed_enemy.set_physics_process(false)
	common_bleed_enemy.setup(DataRegistry.enemies[0], Vector2(120.0, 120.0), 0, Vector2.ZERO, 10.0, 1.0)
	_check(common_bleed_enemy.apply_common_shock(4.0, 3) == 1 and common_bleed_enemy.apply_common_shock(4.0, 3) == 2 and common_bleed_enemy.apply_common_shock(4.0, 3) == 3 and common_bleed_enemy.apply_common_shock(4.0, 3) == 3, "shock must stack on application and stop at three stacks")
	common_bleed_enemy.queue_free()
	var mixed_bleed_data := EnemyData.new()
	mixed_bleed_data.id = &"mixed_bleed_test"
	mixed_bleed_data.max_health = 100.0
	mixed_bleed_data.move_speed = 10.0
	var mixed_bleed_enemy := Enemy.new()
	host.add_child(mixed_bleed_enemy)
	mixed_bleed_enemy.set_process(false)
	mixed_bleed_enemy.set_physics_process(false)
	mixed_bleed_enemy.setup(mixed_bleed_data, Vector2(122.0, 122.0), 0, Vector2.ZERO, 1.0, 1.0)
	mixed_bleed_enemy.apply_common_bleed(&"strong_bleed", 0.05, 0.5, 4, 1000.0)
	mixed_bleed_enemy.apply_common_bleed(&"weak_bleed", 0.02, 2.0, 4, 1.0)
	var mixed_bleed_health := mixed_bleed_enemy.current_health
	mixed_bleed_enemy._update_common_ailments(0.5)
	var mixed_bleed_first_tick := mixed_bleed_health - mixed_bleed_enemy.current_health
	var mixed_bleed_health_after_strong_expiry := mixed_bleed_enemy.current_health
	mixed_bleed_enemy._update_common_ailments(0.5)
	_check(is_equal_approx(mixed_bleed_first_tick, 6.0) and is_equal_approx(mixed_bleed_health_after_strong_expiry - mixed_bleed_enemy.current_health, 1.0) and mixed_bleed_enemy.get_common_ailment_stacks(&"bleed") == 1, "bleed source stacks must retain independent power and caps so an expired strong stack cannot empower weaker survivors")
	mixed_bleed_enemy.queue_free()
	_check(GameTypes.StatusType.has("POISON") and GameTypes.StatusType.has("BLEED") and GameTypes.StatusType.has("CHARM") and GameTypes.StatusType.has("HASTE") and GameTypes.StatusType.has("FORTIFY") and GameTypes.StatusType.has("SENTENCE") and not GameTypes.StatusType.has("VULNERABLE"), "the public status enum must match the runtime status vocabulary")
