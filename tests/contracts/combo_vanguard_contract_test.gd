class_name ComboVanguardContractTest
extends RefCounted

static func run(host: Node) -> Array[String]:
	var failures: Array[String] = []
	_validate_combat_visual_asset(ReaperSummon.VISUAL_TEXTURE_PATH, Vector2i(1024, 1024), Vector2(512.0, 512.0), 512, "Reaper summon", failures)
	_validate_combat_visual_asset(VanguardSquadComponent.MEMBER_TOKEN_PATH, Vector2i(512, 512), Vector2(256.0, 256.0), 256, "Death Vanguard member token", failures)
	_expect(ReaperSummon.DISPLAY_SIZE.x >= 220.0 and ReaperSummon.DISPLAY_SIZE.y >= 220.0, "the Reaper sprite must retain a strong combat-scale key pose", failures)
	_expect(VanguardSquadComponent.MEMBER_TOKEN_SIZE.x >= 18.0 and VanguardSquadComponent.MEMBER_TOKEN_SIZE.x <= 24.0, "the Vanguard stack token must remain legible without consuming the combat field", failures)
	var campaign := load("res://data/concepts/demon_election_campaign_v0_8.tres") as ElectionCampaignData
	var jugdied := campaign.retainer(&"jugdied")
	var vanguard := campaign.retainer(&"death_vanguard")
	_expect(jugdied != null and jugdied.combo_profile != null and jugdied.combo_profile.get_validation_errors().is_empty(), "Jugdied must expose a valid data-driven line-charge profile", failures)
	_expect(vanguard != null and vanguard.vanguard_stack_profile != null and vanguard.vanguard_stack_profile.get_validation_errors().is_empty(), "the Death Vanguard must expose a valid integer squad profile", failures)
	_expect(DataRegistry.validate_campaign(campaign).is_empty(), "the campaign must validate the required combo and squad profiles", failures)

	var near_a := _spawn_probe_enemy(host, Vector2(70.0, 8.0))
	var near_b := _spawn_probe_enemy(host, Vector2(145.0, -18.0))
	var outside := _spawn_probe_enemy(host, Vector2(100.0, 110.0))
	var enemies: Array[Enemy] = [near_b, outside, near_a]
	var combo := ComboAttackService.new()
	var combo_result := combo.resolve_line_charge(jugdied.combo_profile, Vector2.ZERO, Vector2(220.0, 0.0), enemies, 20.0)
	var combo_targets: Array[Enemy] = combo_result.targets
	_expect(combo_targets.size() == 2 and combo_targets[0] == near_a and combo_targets[1] == near_b, "line charge must hit and order only enemies inside the candidate-retainer path", failures)
	_expect(float(combo_result.damage) > 0.0 and outside.current_health == outside.get_max_health(), "line charge damage must not leak outside its configured path", failures)
	for enemy in enemies:
		enemy.queue_free()

	var reconstruction_cursor := TargetCursor.new()
	host.add_child(reconstruction_cursor)
	var reconstruction := RetainerReconstructionComponent.new()
	host.add_child(reconstruction)
	reconstruction.setup(reconstruction_cursor, jugdied.combo_profile, Color.WHITE)
	_expect(reconstruction.begin_reconstruction() and not reconstruction.can_attack(), "a completed combo must enter the explicit reconstruction state", failures)
	_expect(reconstruction_cursor.presentation_state == &"reconstructing" and is_zero_approx(reconstruction_cursor.presentation_state_progress), "the reconstruction lifecycle must immediately drive the retainer body presentation state", failures)
	_expect(reconstruction.allows_movement() and reconstruction.allows_collection(), "bone state must disable attacks without disabling movement or collection", failures)
	for _step in 49:
		reconstruction._physics_process(0.1)
	_expect(not reconstruction.can_attack(), "Jugdied must remain unable to attack before reconstruction time finishes", failures)
	reconstruction._physics_process(0.11)
	_expect(reconstruction.can_attack(), "Jugdied must resume attacks after reconstruction finishes", failures)
	_expect(reconstruction_cursor.presentation_state == &"ready" and is_equal_approx(reconstruction_cursor.presentation_state_progress, 1.0), "the retainer body must return to its ready presentation when reconstruction completes", failures)
	reconstruction.apply_modifiers({"reconstruction_speed": 1.40})
	_expect(reconstruction.reconstruction_seconds < jugdied.combo_profile.reconstruction_seconds, "reconstruction specialization must shorten only the explicit bone-state timer", failures)
	reconstruction.queue_free()
	reconstruction_cursor.queue_free()

	var reconstruction_one := RetainerReconstructionComponent.new()
	var reconstruction_three := RetainerReconstructionComponent.new()
	host.add_child(reconstruction_one)
	host.add_child(reconstruction_three)
	reconstruction_one.setup(null, jugdied.combo_profile, Color.WHITE)
	reconstruction_three.setup(null, jugdied.combo_profile, Color.WHITE)
	reconstruction_one.begin_reconstruction()
	reconstruction_three.begin_reconstruction()
	for _step in 45:
		reconstruction_one._physics_process(0.1)
	for _step in 15:
		reconstruction_three._physics_process(0.3)
	_expect(not reconstruction_one.can_attack() and not reconstruction_three.can_attack() and is_equal_approx(reconstruction_one.reconstruction_remaining, reconstruction_three.reconstruction_remaining), "1x and 3x reconstruction must preserve identical progress for equal game time", failures)
	reconstruction_one._physics_process(0.51)
	reconstruction_three._physics_process(0.51)
	_expect(reconstruction_one.can_attack() and reconstruction_three.can_attack(), "1x and 3x reconstruction must complete at the same game-time boundary", failures)
	reconstruction_one.queue_free()
	reconstruction_three.queue_free()

	var squad := VanguardSquadComponent.new()
	host.add_child(squad)
	squad.setup(null, vanguard.vanguard_stack_profile, Color.WHITE)
	_expect(squad.current_members == 3 and is_equal_approx(squad.get_damage_multiplier(), 0.999999), "three abstract vanguard members must contribute the full baseline attack power", failures)
	var execution_probe := _spawn_probe_enemy(host, Vector2(30.0, 0.0))
	execution_probe.current_health = execution_probe.get_max_health() * 0.10
	var judgment_service := JudgmentService.new()
	var elite_above_threshold := judgment_service.resolve(execution_probe, 1.0, &"vanguard_cursor", squad.execution_health_ratio)
	_expect(not bool(elite_above_threshold.executed), "the vanguard execution line must respect the shared reduced elite boundary", failures)
	execution_probe.current_health = execution_probe.get_max_health() * 0.05
	var execution_result := judgment_service.resolve(execution_probe, 1.0, &"vanguard_cursor", squad.execution_health_ratio)
	_expect(bool(execution_result.executed), "the vanguard execution line must execute an elite below the shared elite boundary", failures)
	_expect(squad.record_execution() and squad.current_members == 2 and squad.record_execution() and squad.current_members == 1, "successful executions must spend one member while preserving the captain", failures)
	_expect(not squad.record_execution() and squad.current_members == 1, "the vanguard captain must never be consumed", failures)
	for _step in 54:
		squad._physics_process(0.1)
	_expect(squad.current_members == 1, "reinforcement must not arrive before the configured game-time delay", failures)
	squad._physics_process(0.11)
	_expect(squad.current_members == 2, "reinforcement must restore exactly one abstract member per interval", failures)
	squad.apply_modifiers({"vanguard_member_bonus": 1, "vanguard_member_damage": 1.30, "vanguard_execute_bonus": 0.06, "reinforcement_speed": 1.75})
	_expect(squad.maximum_members == 4 and squad.current_members == 3 and squad.execution_health_ratio > vanguard.vanguard_stack_profile.execution_health_ratio and squad.reinforcement_seconds < vanguard.vanguard_stack_profile.reinforcement_seconds, "vanguard specialization must update capacity, member power, execution line, and reinforcement speed through data", failures)
	squad.queue_free()

	var reaper_squad := VanguardSquadComponent.new()
	host.add_child(reaper_squad)
	reaper_squad.setup(null, vanguard.vanguard_stack_profile, Color.WHITE, {
		"vanguard_reaper_circle": true,
		"vanguard_execute_bonus": 0.04,
	})
	var reaper_survivor := _spawn_probe_enemy(host, Vector2(50.0, 0.0))
	var reaper_executed := _spawn_probe_enemy(host, Vector2(90.0, 0.0))
	var reaper_inactive := _spawn_probe_enemy(host, Vector2(120.0, 0.0))
	reaper_inactive.active = false
	var reaper_targets: Array[Enemy] = [reaper_survivor, reaper_executed, reaper_inactive]
	var reaper_query := {"calls": 0, "center": Vector2.ZERO, "radius": 0.0}
	var reaper_judgments: Array[Dictionary] = []
	var reaper_query_callback := func(center: Vector2, radius: float) -> Array[Enemy]:
		reaper_query.calls += 1
		reaper_query.center = center
		reaper_query.radius = radius
		return reaper_targets
	var reaper_judgment_callback := func(enemy: Enemy, hit_damage: float, source: StringName, execute_ratio: float) -> Dictionary:
		reaper_judgments.append({"enemy": enemy, "damage": hit_damage, "source": source, "execute_ratio": execute_ratio})
		var executed := enemy == reaper_executed
		if executed:
			enemy.active = false
		return {"damage": hit_damage, "executed": executed}
	var reaper_service := VanguardReaperExecutionService.new()
	var reaper_result := reaper_service.execute(
		reaper_squad, 40.0, 1.5, Vector2(20.0, 10.0), 100.0,
		{"vanguard_reaper_damage": 2.0, "vanguard_reaper_knockback": 120.0},
		reaper_query_callback, reaper_judgment_callback
	)
	var reaper_hits: Array[Enemy] = []
	reaper_hits.assign(reaper_result.hit_targets as Array)
	var reaper_knockbacks: Array[Enemy] = []
	reaper_knockbacks.assign(reaper_result.knocked_targets as Array)
	_expect(bool(reaper_result.applied) and int(reaper_result.snapshot) == 3 and reaper_squad.current_members == 0, "the reaper circle must atomically consume the full vanguard snapshot", failures)
	_expect(is_equal_approx(float(reaper_result.damage), 360.0) and is_equal_approx(float(reaper_result.dealt), 720.0), "the reaper circle must scale damage by cursor stats, branch damage, and the consumed snapshot", failures)
	_expect(reaper_query.calls == 1 and reaper_query.center == Vector2(20.0, 10.0) and is_equal_approx(float(reaper_query.radius), 180.0), "the reaper circle must query the configured 1.8x cursor radius exactly once", failures)
	_expect(reaper_hits == [reaper_survivor, reaper_executed] and reaper_judgments.size() == 2, "the reaper circle must judge only active queried enemies in query order", failures)
	_expect(reaper_judgments.all(func(sample: Dictionary) -> bool: return sample.source == &"vanguard_reaper" and is_equal_approx(float(sample.execute_ratio), reaper_squad.execution_health_ratio)), "the reaper circle must use the shared vanguard execution line and stable damage source", failures)
	_expect(int(reaper_result.execution_count) == 1 and reaper_knockbacks == [reaper_survivor] and reaper_survivor.last_knockback_displacement > 0.0 and is_zero_approx(reaper_executed.last_knockback_displacement), "the reaper circle must count executions and knock back only targets still alive after judgment", failures)
	var exhausted_result := reaper_service.execute(reaper_squad, 40.0, 1.5, Vector2.ZERO, 100.0, {}, reaper_query_callback, reaper_judgment_callback)
	_expect(not bool(exhausted_result.applied) and reaper_query.calls == 1 and reaper_judgments.size() == 2, "an exhausted vanguard snapshot must not query or judge targets", failures)

	var invalid_reaper_squad := VanguardSquadComponent.new()
	host.add_child(invalid_reaper_squad)
	invalid_reaper_squad.setup(null, vanguard.vanguard_stack_profile, Color.WHITE, {"vanguard_reaper_circle": true})
	var invalid_reaper_result := reaper_service.execute(invalid_reaper_squad, 40.0, 1.0, Vector2.ZERO, 100.0, {}, Callable(), reaper_judgment_callback)
	_expect(not bool(invalid_reaper_result.applied) and invalid_reaper_squad.current_members == invalid_reaper_squad.maximum_members, "invalid reaper collaborators must fail before consuming the squad snapshot", failures)
	reaper_squad.queue_free()
	invalid_reaper_squad.queue_free()
	reaper_survivor.queue_free()
	reaper_executed.queue_free()
	reaper_inactive.queue_free()

	var squad_one := VanguardSquadComponent.new()
	var squad_three := VanguardSquadComponent.new()
	host.add_child(squad_one)
	host.add_child(squad_three)
	squad_one.setup(null, vanguard.vanguard_stack_profile, Color.WHITE)
	squad_three.setup(null, vanguard.vanguard_stack_profile, Color.WHITE)
	squad_one.record_execution()
	squad_three.record_execution()
	for _step in 51:
		squad_one._physics_process(0.1)
	for _step in 17:
		squad_three._physics_process(0.3)
	_expect(squad_one.current_members == 2 and squad_three.current_members == 2 and is_equal_approx(squad_one.reinforcement_remaining, squad_three.reinforcement_remaining), "reinforcement progress must depend on supplied game time rather than frame count", failures)
	squad_one._physics_process(0.41)
	squad_three._physics_process(0.41)
	_expect(squad_one.current_members == 3 and squad_three.current_members == 3, "1x and 3x reinforcement must finish at the same game-time boundary", failures)
	squad_one.queue_free()
	squad_three.queue_free()

	var label_probe := LoadoutManager.new()
	var labels := label_probe._modifier_stat_lines({"combo_damage": 1.50, "reconstruction_speed": 1.40, "vanguard_execute_bonus": 0.06, "reinforcement_speed": 1.75, "vanguard_member_bonus": 1})
	_expect("합동 공격 피해 ×1.50" in labels and "재구성 속도 ×1.40" in labels and "처형선 +6%p" in labels and "충원 속도 ×1.75" in labels and "최대 인원 1" in labels, "combo and squad specialization cards must show readable values and units", failures)
	label_probe.free()
	return failures

static func _spawn_probe_enemy(host: Node, position: Vector2) -> Enemy:
	var enemy := Enemy.new()
	host.add_child(enemy)
	enemy.setup(DataRegistry.get_enemy(&"steel_golem"), position, 0, Vector2(-200.0, position.y), 100.0, 1.0)
	return enemy

static func _validate_combat_visual_asset(path: String, source_size: Vector2i, imported_size: Vector2, size_limit: int, label: String, failures: Array[String]) -> void:
	_expect(FileAccess.file_exists(path), "%s must exist at its stable active path" % label, failures)
	var texture := load(path) as Texture2D
	_expect(texture != null and texture.get_size() == imported_size, "%s must import at its mobile size cap" % label, failures)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	_expect(image != null and image.get_size() == source_size and image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "%s must preserve its square alpha-capable source master" % label, failures)
	if image != null and not image.is_empty():
		var maximum := source_size - Vector2i.ONE
		var corners := [Vector2i.ZERO, Vector2i(maximum.x, 0), Vector2i(0, maximum.y), maximum]
		_expect(corners.all(func(point: Vector2i) -> bool: return image.get_pixelv(point).a <= 0.01), "%s must preserve truly transparent corners" % label, failures)
	var import_path := path + ".import"
	_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=%d" % size_limit), "%s import must preserve its explicit mobile cap" % label, failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
