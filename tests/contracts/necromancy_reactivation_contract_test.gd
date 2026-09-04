class_name NecromancyReactivationContractTest
extends RefCounted

static func run(host: Node) -> Array[String]:
	var failures: Array[String] = []
	var jade := DataRegistry.get_core(&"jade")
	var undead_guard := DataRegistry.get_tower(&"jade_roulette")
	_expect(jade.necromancy_profile != null and jade.necromancy_profile.get_validation_errors().is_empty(), "Jade must expose a valid data-driven necromancy profile", failures)
	_expect(undead_guard.reactivation_profile != null and undead_guard.reactivation_profile.get_validation_errors().is_empty(), "the undead guard must expose a valid isolated reactivation profile", failures)
	_expect(DataRegistry.get_tower(&"rapid").reactivation_profile == null, "ordinary towers must not inherit the retainer lifecycle component", failures)
	_expect(undead_guard.display_name == "망자 부활진" and DataRegistry.get_formation(&"jade_gambit").display_name == "부활 시체 친위대", "stable Jade IDs must expose the v0.10 necromancy guard names", failures)
	var title_probe := GameController.new()
	var title_loadout := LoadoutManager.new()
	title_loadout.candidate_progression.configure(ConceptService.get_election_campaign().candidate(&"irelai").growth_data)
	title_probe.loadout = title_loadout
	_expect(title_probe._core_skill_title(jade) == "죽음의 파도", "Jade's candidate active display name must communicate Irelai's progressing death wave", failures)
	title_loadout.free()
	title_probe.free()
	var label_probe := LoadoutManager.new()
	var modifier_labels := label_probe._modifier_stat_lines({"spirit_gain_chance_bonus": 0.15, "spirit_capacity_bonus": 2, "retainer_health": 1.45, "reactivation_speed": 1.35})
	_expect("일반 적 사령 확률 +15%p" in modifier_labels and "사령 상한 2" in modifier_labels and "친위대 체력 ×1.45" in modifier_labels and "친위대 재가동 속도 ×1.35" in modifier_labels, "necromancy specialization cards must render their affected values with readable units", failures)
	label_probe.free()

	var source := Node2D.new()
	host.add_child(source)
	var summon_service := SummonService.new()
	host.add_child(summon_service)
	var necromancy := NecromancyController.new()
	host.add_child(necromancy)
	necromancy.setup(source, jade.necromancy_profile, summon_service)
	var normal_enemy := DataRegistry.get_enemy(&"civilian_slime")
	var elite_enemy := DataRegistry.get_enemy(&"steel_golem")
	var boss_enemy := DataRegistry.bosses[0]
	_expect(necromancy.record_defeat(normal_enemy, Vector2(300.0, 200.0), 0.90) == 0, "normal defeats above the configured chance must not grant spirit charge", failures)
	_expect(necromancy.record_defeat(normal_enemy, Vector2(310.0, 200.0), 0.10) == 1, "normal defeats inside the configured chance must grant one spirit charge", failures)
	_expect(necromancy.record_defeat(elite_enemy, Vector2(320.0, 200.0), 0.99) == 1, "configured elite defeats must guarantee one spirit charge", failures)
	_expect(necromancy.record_defeat(boss_enemy, Vector2(330.0, 200.0), 0.99, 3) == 2 and necromancy.charges == 4, "boss gains must respect the four-charge cap even when the rolled reward is larger", failures)
	var released := necromancy.request_summons(9, Vector2.ZERO)
	_expect(released.size() == 4 and necromancy.charges == 0 and necromancy.active_summon_lifetimes.size() == 4 and summon_service.active_count(&"irelai_spirit") == 4, "spirit release must consume charges and obey both the local and shared summon caps", failures)
	necromancy.add_charges(4, Vector2(400.0, 200.0))
	_expect(necromancy.request_summons(4).is_empty() and necromancy.charges == 4, "a full summon pool must retain unspent spirit charges", failures)
	necromancy._physics_process(jade.necromancy_profile.summon_visual_duration + 0.01)
	_expect(necromancy.request_summons(4).size() == 4 and necromancy.charges == 0, "expired summon visuals must return all limited pool slots", failures)
	necromancy.apply_modifiers({"spirit_capacity_bonus": 4, "spirit_gain_chance_bonus": 0.25, "spirit_damage": 1.55, "spirit_simultaneous_bonus": 2})
	_expect(necromancy.maximum_charges == 8 and is_equal_approx(necromancy.normal_defeat_chance, 0.40) and necromancy.maximum_simultaneous_summons == 6, "Irelai completion modifiers must expand charge chance, capacity, damage, and pool size through data", failures)
	necromancy._physics_process(jade.necromancy_profile.summon_visual_duration + 0.01)
	necromancy.apply_modifiers({"spirit_duration": 1.5, "spirit_simultaneous_bonus": 2, "post_active_spirit_chance_bonus": 0.3})
	_expect(necromancy.maximum_simultaneous_summons == 6 and is_equal_approx(necromancy.summon_duration_multiplier, 1.5), "posthumous employment expansion must extend spirit lifetime and add two simultaneous pool slots", failures)
	necromancy.begin_active_window(8.0)
	_expect(necromancy.record_defeat(normal_enemy, Vector2(410.0, 200.0), 0.40) == 1, "mass reemployment must temporarily add its post-wave hiring chance", failures)
	var active_generated_entry := necromancy.request_summon_entries(1, Vector2.ZERO)
	_expect(active_generated_entry.size() == 1, "a post-wave hired spirit must enter the bounded active pool", failures)
	necromancy._physics_process(jade.necromancy_profile.summon_visual_duration * 1.5 + 8.01)
	_expect(necromancy.record_defeat(normal_enemy, Vector2(420.0, 200.0), 0.40) == 0, "the post-wave hiring bonus must end after its bounded duration", failures)
	necromancy.add_charges(1, Vector2(430.0, 200.0), 1.2)
	var strengthened_entry := necromancy.request_summon_entries(1, Vector2.ZERO)
	_expect(strengthened_entry.size() == 1 and is_equal_approx(float(strengthened_entry[0].damage_multiplier), 1.2), "death-wave-generated spirits must retain their own final-upgrade damage multiplier", failures)
	var expiration_events: Array[Dictionary] = []
	necromancy.summon_expired.connect(func(position: Vector2, damage: float) -> void: expiration_events.append({"position": position, "damage": damage}))
	necromancy.update_active_summon(int(strengthened_entry[0].id), Vector2(440.0, 210.0), 25.0)
	necromancy._physics_process(jade.necromancy_profile.summon_visual_duration * 1.5 + 0.01)
	_expect(expiration_events.size() == 1 and expiration_events[0].position == Vector2(440.0, 210.0) and is_equal_approx(float(expiration_events[0].damage), 25.0), "expired spirits must report their last target position and attack damage for the optional death blast", failures)
	necromancy.add_charges(1, Vector2(450.0, 220.0), 1.0, 2)
	var cursed_spirit_entry := necromancy.request_summon_entries(1, Vector2.ZERO)
	_expect(cursed_spirit_entry.size() == 1 and int(cursed_spirit_entry[0].curse_generation) == 2 and StringName(cursed_spirit_entry[0].owner_id) == &"irelai_spirit" and int(cursed_spirit_entry[0].budget_token) > 0 and IrelaiGuardController.next_curse_generation(1) == 2 and IrelaiGuardController.next_curse_generation(2) == 3 and IrelaiGuardController.next_curse_generation(3) == 0, "death-curse spirit metadata must preserve owner, budget token, and lineage while stopping after generation III", failures)
	necromancy._physics_process(jade.necromancy_profile.summon_visual_duration * 1.5 + 0.01)
	necromancy.add_charges(3, Vector2(460.0, 220.0))
	var single_reserved_entry := necromancy.request_summon_entries(1, Vector2.ZERO)
	_expect(single_reserved_entry.size() == 1 and necromancy.charges == 2, "reserving one spirit attack must consume only one charge so later target loss cannot waste the unused requests", failures)
	necromancy.clear_active_summons(false)
	_expect(summon_service.active_count(&"irelai_spirit") == 0, "clearing necromancy at run end must return every shared summon slot", failures)

	var summon_speed_one := NecromancyController.new()
	var summon_speed_two := NecromancyController.new()
	var summon_speed_three := NecromancyController.new()
	var summon_speed_probes: Array[NecromancyController] = [summon_speed_one, summon_speed_two, summon_speed_three]
	for probe in summon_speed_probes:
		host.add_child(probe)
		probe.setup(source, jade.necromancy_profile)
		probe.add_charges(1, Vector2(470.0, 220.0))
		probe.request_summon_entries(1, Vector2.ZERO)
	var summon_duration := jade.necromancy_profile.summon_visual_duration
	for _step in 6:
		summon_speed_one._physics_process(summon_duration * 0.125)
	for _step in 3:
		summon_speed_two._physics_process(summon_duration * 0.25)
	for _step in 2:
		summon_speed_three._physics_process(summon_duration * 0.375)
	var speed_one_remaining := summon_speed_one.active_summon_lifetimes[0] if not summon_speed_one.active_summon_lifetimes.is_empty() else -1.0
	var speed_two_remaining := summon_speed_two.active_summon_lifetimes[0] if not summon_speed_two.active_summon_lifetimes.is_empty() else -2.0
	var speed_three_remaining := summon_speed_three.active_summon_lifetimes[0] if not summon_speed_three.active_summon_lifetimes.is_empty() else -3.0
	_expect(speed_one_remaining > 0.0 and is_equal_approx(speed_one_remaining, speed_two_remaining) and is_equal_approx(speed_one_remaining, speed_three_remaining), "1x, 2x, and 3x stepping must preserve identical spirit lifetime progress for equal game time", failures)
	for probe in summon_speed_probes:
		probe._physics_process(summon_duration * 0.25 + 0.01)
	_expect(summon_speed_one.active_summon_lifetimes.is_empty() and summon_speed_two.active_summon_lifetimes.is_empty() and summon_speed_three.active_summon_lifetimes.is_empty(), "1x, 2x, and 3x spirit lifetimes must expire at the same game-time boundary", failures)
	for probe in summon_speed_probes:
		probe.queue_free()
	necromancy.queue_free()
	source.queue_free()

	var boss_curse_probe := GameController.new()
	var breached_boss := Enemy.new()
	host.add_child(breached_boss)
	breached_boss.setup(boss_enemy, Vector2(100.0, 100.0), 0, Vector2.ZERO, 1.0, 1.0)
	boss_curse_probe.game_finished = true
	_expect(boss_curse_probe.irelai_guard_controller.apply_curse(breached_boss, 1), "a live boss must accept Irelai's death curse", failures)
	boss_curse_probe._on_enemy_reached_core(0.0, breached_boss)
	_expect(boss_curse_probe.irelai_guard_controller.consume_curse_on_defeat(breached_boss) == 1, "a boss core breach must preserve its curse because the boss retreats instead of leaving combat", failures)
	breached_boss.free()
	boss_curse_probe.free()

	var wave_battlefield := Battlefield.new()
	host.add_child(wave_battlefield)
	var death_wave := DeathWaveController.new()
	host.add_child(death_wave)
	death_wave.setup(wave_battlefield, EnemySpatialIndex.new(), summon_service)
	var wave_finished_state := {"value": false}
	death_wave.wave_finished.connect(func() -> void: wave_finished_state.value = true)
	_expect(death_wave.launch(100.0, wave_battlefield.get_battle_rect().get_center().y, 180.0, 2.4, 1, 1.2, Color("9ddd55")) and death_wave.active and int(summon_service.budget_snapshot().active_cost) == 2, "Irelai's active must launch one bounded progressing death wave with its shared budget weight", failures)
	death_wave._physics_process(2.41)
	_expect(not death_wave.active and bool(wave_finished_state.value) and summon_service.active_count(&"irelai_death_wave") == 0, "the death wave must finish, return its shared slot, and publish its post-wave boundary after its configured game-time duration", failures)
	death_wave.queue_free()
	wave_battlefield.queue_free()
	summon_service.queue_free()

	var reactivation_profile := undead_guard.reactivation_profile
	var lifecycle := RetainerReactivationComponent.new()
	host.add_child(lifecycle)
	lifecycle.setup(null, -1, reactivation_profile, undead_guard.color)
	var health_before := lifecycle.current_health
	lifecycle._physics_process(1.0)
	_expect(lifecycle.current_health < health_before and lifecycle.can_attack(), "an active undead guard must lose passive health while remaining operational", failures)
	var health_before_attack := lifecycle.current_health
	_expect(lifecycle.consume_attack() and is_equal_approx(health_before_attack - lifecycle.current_health, reactivation_profile.attack_health_cost), "each actual guard attack must consume its own activity health", failures)
	lifecycle.force_deactivate()
	_expect(not lifecycle.can_attack() and is_equal_approx(lifecycle.reactivation_remaining, reactivation_profile.reactivation_seconds), "zero guard health must enter a timed non-attacking reactivation state", failures)
	for _step in 19:
		lifecycle._physics_process(0.3)
	lifecycle._physics_process(0.31)
	_expect(lifecycle.can_attack() and is_equal_approx(lifecycle.current_health, lifecycle.maximum_health), "the undead guard must reactivate at full health after six game-time seconds", failures)
	lifecycle.apply_modifiers({"retainer_health": 1.80, "retainer_passive_drain": 0.50, "retainer_attack_cost": 0.60, "reactivation_speed": 1.75})
	_expect(is_equal_approx(lifecycle.maximum_health, reactivation_profile.maximum_health * 1.80) and lifecycle.reactivation_seconds < reactivation_profile.reactivation_seconds, "afterlife-welfare and instant-rehire modifiers must alter only the isolated retainer lifecycle", failures)
	lifecycle.queue_free()

	var rescaled_lifecycle := RetainerReactivationComponent.new()
	host.add_child(rescaled_lifecycle)
	rescaled_lifecycle.setup(null, -1, reactivation_profile, undead_guard.color)
	rescaled_lifecycle.force_deactivate()
	rescaled_lifecycle._physics_process(reactivation_profile.reactivation_seconds * 0.25)
	rescaled_lifecycle.apply_modifiers({"reactivation_speed": 2.0})
	_expect(is_equal_approx(rescaled_lifecycle.reactivation_seconds, reactivation_profile.reactivation_seconds * 0.5) and is_equal_approx(rescaled_lifecycle.reactivation_remaining, reactivation_profile.reactivation_seconds * 0.375), "changing reactivation speed while inactive must preserve elapsed progress and immediately rescale the remaining game time", failures)
	rescaled_lifecycle.queue_free()

	var speed_one := RetainerReactivationComponent.new()
	var speed_three := RetainerReactivationComponent.new()
	host.add_child(speed_one)
	host.add_child(speed_three)
	speed_one.setup(null, -1, reactivation_profile, undead_guard.color)
	speed_three.setup(null, -1, reactivation_profile, undead_guard.color)
	speed_one.force_deactivate()
	speed_three.force_deactivate()
	for _step in 57:
		speed_one._physics_process(0.1)
	for _step in 19:
		speed_three._physics_process(0.3)
	_expect(not speed_one.can_attack() and not speed_three.can_attack() and is_equal_approx(speed_one.reactivation_remaining, speed_three.reactivation_remaining), "1x and 3x stepping must preserve identical reactivation progress for equal game time", failures)
	for _step in 6:
		speed_one._physics_process(0.1)
	for _step in 2:
		speed_three._physics_process(0.3)
	_expect(speed_one.can_attack() and speed_three.can_attack(), "1x and 3x stepping must finish reactivation at the same game-time boundary", failures)
	speed_one.queue_free()
	speed_three.queue_free()
	failures.append_array(_run_irelai_scene_lineage_contract(host, jade, undead_guard, normal_enemy))
	return failures

static func _run_irelai_scene_lineage_contract(host: Node, jade: CoreData, undead_guard: TowerData, normal_enemy: EnemyData) -> Array[String]:
	var failures: Array[String] = []
	var flow_host := Node2D.new()
	host.add_child(flow_host)
	var battlefield := Battlefield.new()
	flow_host.add_child(battlefield)
	var column := TowerColumn.new()
	flow_host.add_child(column)
	column.setup(0, 220.0, battlefield)
	column.formation_data = DataRegistry.get_formation(&"jade_gambit")
	column.is_guard_formation = true
	column.row_towers.resize(battlefield.lane_count)
	column.row_towers.fill(null)
	column.row_towers[0] = undead_guard

	var flow_loadout := LoadoutManager.new()
	var irelai := ConceptService.get_election_campaign().candidate(&"irelai")
	flow_loadout.guard_progression.configure(irelai.guard_growth_data)
	flow_loadout.guard_progression.train()
	flow_loadout.guard_progression.select_specialization(&"irelai_guard_death_curse")
	var flow_metrics := RunMetrics.new()
	flow_host.add_child(flow_metrics)
	var effects := Node2D.new()
	flow_host.add_child(effects)
	var source := Node2D.new()
	flow_host.add_child(source)
	var flow_summon_service := SummonService.new()
	flow_host.add_child(flow_summon_service)
	var flow_necromancy := NecromancyController.new()
	flow_host.add_child(flow_necromancy)
	flow_necromancy.setup(source, jade.necromancy_profile, flow_summon_service)

	var probe := GameController.new()
	probe.game_finished = true
	probe.loadout = flow_loadout
	probe.metrics = flow_metrics
	probe.effect_container = effects
	probe.summon_service = flow_summon_service
	probe.necromancy_controller = flow_necromancy
	var lifecycle := probe._get_retainer_reactivation_component(column, 0, undead_guard)
	_expect(lifecycle != null, "the scene coordinator must create the undead guard's bounded reactivation component", failures)
	if lifecycle == null:
		probe.free()
		flow_loadout.free()
		flow_host.free()
		return failures
	lifecycle.force_deactivate()
	lifecycle._physics_process(lifecycle.reactivation_seconds + 0.01)
	_expect(lifecycle.can_attack() and int(flow_metrics.mechanic_events.get("retainer_reactivated", 0)) == 1 and int(flow_metrics.mechanic_events.get("irelai_guard_curse_readied", 0)) == 1, "reactivation must reach the game coordinator and ready exactly one first-attack death curse", failures)

	var first_enemy := _lineage_enemy(flow_host, normal_enemy, Vector2(420.0, 220.0))
	probe.spatial_index.register_enemy(first_enemy)
	probe._apply_unique_random_first_target_curse(column, 0, undead_guard, first_enemy)
	var defeat_plan := probe.enemy_defeat_policy.build_plan(normal_enemy, normal_enemy.experience_value, false, false, false, false, false)
	probe._resolve_irelai_defeat_reactions(first_enemy, normal_enemy, first_enemy.global_position, defeat_plan)
	_expect(flow_necromancy.charges == 1 and flow_necromancy.charge_curse_generations == [2] and int(flow_metrics.mechanic_events.get("irelai_guard_first_attack_curse", 0)) == 1, "the first post-reactivation hit and defeat must create one generation-II spirit charge", failures)
	first_enemy.active = false

	var second_enemy := _lineage_enemy(flow_host, normal_enemy, Vector2(500.0, 220.0))
	probe.spatial_index.register_enemy(second_enemy)
	var second_release := probe._release_single_spirit_attack(Vector2(420.0, 220.0), 1.0)
	probe._resolve_irelai_defeat_reactions(second_enemy, normal_enemy, second_enemy.global_position, defeat_plan)
	_expect(bool(second_release.get("released", false)) and flow_necromancy.charges == 1 and flow_necromancy.charge_curse_generations == [3] and is_equal_approx(float(flow_metrics.mechanic_totals.get("irelai_guard_spirit_curse", 0.0)), 2.0), "the generation-II spirit hit and defeat must propagate exactly one generation-III charge through the scene flow", failures)
	second_enemy.active = false

	var third_enemy := _lineage_enemy(flow_host, normal_enemy, Vector2(580.0, 220.0))
	probe.spatial_index.register_enemy(third_enemy)
	var third_release := probe._release_single_spirit_attack(Vector2(500.0, 220.0), 1.0)
	probe._resolve_irelai_defeat_reactions(third_enemy, normal_enemy, third_enemy.global_position, defeat_plan)
	_expect(bool(third_release.get("released", false)) and flow_necromancy.charges == 1 and flow_necromancy.charge_curse_generations == [0] and int(flow_metrics.mechanic_events.get("irelai_guard_spirit_curse", 0)) == 2 and is_equal_approx(float(flow_metrics.mechanic_totals.get("irelai_guard_spirit_curse", 0.0)), 5.0), "generation III must still hire a final spirit while clearing its lineage so a fourth curse generation cannot propagate", failures)

	probe.spatial_index.clear()
	flow_necromancy.clear_active_summons(false)
	probe.free()
	flow_loadout.free()
	flow_host.free()
	return failures

static func _lineage_enemy(host: Node, enemy_data: EnemyData, position: Vector2) -> Enemy:
	var enemy := Enemy.new()
	host.add_child(enemy)
	enemy.setup(enemy_data, position, 0, Vector2(100.0, position.y), 1.0, 1.0)
	return enemy

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
