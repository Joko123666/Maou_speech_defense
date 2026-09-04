class_name RetainerProgressionContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var campaign := ConceptService.get_election_campaign()
	_expect(campaign != null and campaign.candidates.size() == 5 and campaign.retainers.size() == 5, "retainer progression requires the five-by-five election roster", failures)
	if campaign == null:
		return failures

	var combination_count := 0
	var factory := CandidateMechanicsFactory.new()
	for candidate in campaign.candidates:
		for retainer in campaign.retainers:
			combination_count += 1
			var progression := RetainerProgressionService.new()
			progression.configure(retainer.growth_data, GrowthTrackState.new(retainer.cursor_id))
			_expect(progression.is_enabled() and progression.state.retainer_id == retainer.id and progression.state.legacy_cursor_id == retainer.cursor_id, "candidate '%s' must preserve retainer '%s' as the growth authority" % [candidate.id, retainer.id], failures)
			var component_plan := factory.component_plan(DataRegistry.get_core(candidate.core_id), retainer)
			var required_component: StringName = &"retainer_combat" if retainer.id in [&"kanda", &"given", &"jeomujeom"] else (&"retainer_reconstruction" if retainer.id == &"jugdied" else &"vanguard_squad")
			_expect(required_component in component_plan, "candidate '%s' must activate retainer '%s' through the same candidate-independent component contract" % [candidate.id, retainer.id], failures)
	_expect(combination_count == 25, "all 25 candidate-retainer combinations must construct a retainer-owned growth state", failures)

	for retainer in campaign.retainers:
		_expect(retainer.action_profile_id != &"" and retainer.growth_data != null, "retainer '%s' must reference action and growth profiles" % retainer.id, failures)
		if retainer.growth_data == null:
			continue
		_expect(retainer.growth_data.specialization_ids.size() == 3, "retainer '%s' must expose exactly three specializations" % retainer.id, failures)
		for specialization_id in retainer.growth_data.specialization_ids:
			var specialization := DataRegistry.get_specialization_branch(specialization_id)
			_expect(specialization != null and specialization.owner_id == retainer.cursor_id, "retainer '%s' specialization '%s' must preserve its legacy cursor owner" % [retainer.id, specialization_id], failures)

		var progression := RetainerProgressionService.new()
		progression.configure(retainer.growth_data, GrowthTrackState.new(retainer.cursor_id))
		var application := LoadoutUpgradeApplicationService.new()
		var state := {"cursor_state": progression.state}
		application.apply(UpgradeData.new().configure(&"cursor_level", "L2", "", retainer.cursor_id), state, true)
		application.apply(UpgradeData.new().configure(&"cursor_level", "L3", "", retainer.cursor_id), state, true)
		var selected_id := retainer.growth_data.specialization_ids[0]
		var branch_result := application.apply(UpgradeData.new().configure(&"cursor_branch", "L4", "", selected_id), state, true)
		_expect(bool(branch_result.applied) and progression.state.current_level == 4 and progression.state.selected_branch_id == selected_id, "retainer '%s' must select its specialization exactly once at level 4" % retainer.id, failures)
		for next_level in [5, 6, 7]:
			application.apply(UpgradeData.new().configure(&"cursor_level", "L%d" % next_level, "", retainer.cursor_id), state, true)
		_expect(progression.state.current_level == 7 and progression.state.selected_branch_id == selected_id, "retainer '%s' level 7 completion must match its level 4 specialization" % retainer.id, failures)

	var kanda := campaign.retainer(&"kanda")
	var given := campaign.retainer(&"given")
	var jeomujeom := campaign.retainer(&"jeomujeom")
	var jugdied := campaign.retainer(&"jugdied")
	var vanguard := campaign.retainer(&"death_vanguard")
	for retainer in [kanda, given, jeomujeom]:
		_expect(&"retainer_combat" in factory.component_plan(DataRegistry.get_core(&"emerald"), retainer), "retainer '%s' must use the candidate-independent combat controller" % retainer.id, failures)

	var given_controller := RetainerCombatController.new()
	given_controller.setup(given, null, DataRegistry.get_specialization_branch(&"silver_tracking").get_modifiers(false))
	var given_plan := given_controller.build_attack_plan(1)
	_expect(int(given_plan.strike_count) == 3 and int(given_plan.charm_rolls) == 1, "Given's triple strike must make one charm roll per sequence", failures)
	given_controller.apply_modifiers(DataRegistry.get_specialization_branch(&"silver_weakness").get_modifiers(true))
	var edge_plan := given_controller.build_attack_plan(1)
	var edge_enemy := Enemy.new()
	edge_enemy.position = Vector2(80.0, 0.0)
	_expect(given_controller.knockback_multiplier_for(edge_enemy, Vector2.ZERO, 100.0, edge_plan) > 1.0 and is_equal_approx(given_controller.knockback_multiplier_for(edge_enemy, Vector2(80.0, 0.0), 100.0, edge_plan), 1.0), "Given's long-whip branch must strengthen knockback only near the attack edge", failures)

	var kanda_controller := RetainerCombatController.new()
	kanda_controller.setup(kanda, null, DataRegistry.get_specialization_branch(&"iron_relay").get_modifiers(true))
	var kanda_plan := kanda_controller.build_attack_plan(4)
	_expect(bool(kanda_plan.force_area) and bool(kanda_plan.final_slash), "Kanda's completed whirlwind branch must add its forward finishing slash", failures)

	var jeomujeom_controller := RetainerCombatController.new()
	var fear_index := EnemySpatialIndex.new()
	jeomujeom_controller.setup(jeomujeom, null, DataRegistry.get_specialization_branch(&"gold_zone").get_modifiers(true), fear_index)
	var fear_plan := jeomujeom_controller.build_attack_plan(3)
	var fear_enemies: Array[Enemy] = []
	for position in [Vector2.ZERO, Vector2(55.0, 0.0), Vector2(105.0, 0.0)]:
		var fear_enemy := Enemy.new()
		fear_enemy.data = DataRegistry.get_enemy(&"normal")
		fear_enemy.active = true
		fear_enemy.position = position
		fear_enemies.append(fear_enemy)
		fear_index.register_enemy(fear_enemy)
	var fear_result := jeomujeom_controller.apply_on_hit(fear_enemies[0], fear_plan)
	_expect(bool(fear_plan.fear) and int(fear_result.fear_spread) == 2 and fear_enemies.all(func(enemy: Enemy) -> bool: return enemy.statuses.has(&"fear")), "Jeomujeom completed erosion must apply resistance-aware fear and spread it to two nearby targets", failures)
	jeomujeom_controller.apply_modifiers(DataRegistry.get_specialization_branch(&"gold_chain").get_modifiers(true))
	_expect(jeomujeom_controller.uses_resummon(), "Jeomujeom resummon branch must replace movement commands at level 4 and retain arrival effects at level 7", failures)

	var reconstruction := RetainerReconstructionComponent.new()
	reconstruction.profile = jugdied.combo_profile
	reconstruction.apply_modifiers(DataRegistry.get_specialization_branch(&"platinum_charge").get_modifiers(false))
	_expect(reconstruction.reconstruction_disabled and not reconstruction.begin_reconstruction() and reconstruction.can_attack(), "Jugdied persistent contract must remove reconstruction while retaining its damage penalty", failures)

	var squad := VanguardSquadComponent.new()
	squad.profile = vanguard.vanguard_stack_profile
	squad.apply_modifiers(DataRegistry.get_specialization_branch(&"vanguard_march").get_modifiers(false), true)
	var snapshot := squad.consume_for_reaper()
	_expect(snapshot == squad.maximum_members and squad.current_members == 0, "Vanguard reaper circle must snapshot all current members before sacrificing the squad", failures)
	var metric_probe := RunMetrics.new()
	metric_probe.record_cursor_damage(123.0)
	metric_probe.record_retainer_control(4)
	metric_probe.record_retainer_collection(18.0)
	metric_probe.record_mechanic_event(&"jeomujeom_resummon")
	var contribution := metric_probe.retainer_contribution_snapshot(&"jeomujeom")
	_expect(String(contribution.role) == "영역·공포" and int(contribution.control_applications) == 4 and is_equal_approx(float(contribution.collection_experience), 18.0) and int(contribution.unique_uses) == 1, "retainer results must summarize role-specific damage, control, collection, and unique actions", failures)
	for fear_enemy in fear_enemies:
		fear_index.unregister_enemy(fear_enemy)
		fear_enemy.free()
	edge_enemy.free()
	kanda_controller.free()
	given_controller.free()
	jeomujeom_controller.free()
	reconstruction.free()
	squad.free()
	metric_probe.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
