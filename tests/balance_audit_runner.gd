extends Node

const AUDIT_REPORT_SCHEMA_VERSION := 20
const META_FIXTURE_ID := "starter_discovery_v1"
const PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"
const SCENARIOS := {
	"royal_armament": {"core": &"emerald", "cursor": &"iron", "decree": &"orthodox_army"},
	"charm_combo": {"core": &"sapphire", "cursor": &"platinum", "decree": &"charmed_march"},
	"abyss_research": {"core": &"amethyst", "cursor": &"gold", "decree": &"abyss_collapse"},
	"necromancy_vanguard": {"core": &"jade", "cursor": &"vanguard", "decree": &"mass_revival"},
	"judgment_vanguard": {"core": &"obsidian", "cursor": &"vanguard", "decree": &"bell_of_judgment"},
}

var game: GameController
var scenario_name := "judgment_vanguard"
var audit_target_seconds := 600.0
var audit_seed := 1847
var audit_speed := 3
var build_policy_id: StringName = &"strong_synergy"
var skill_policy_id: StringName = &"high"
var bonus_mode: StringName = &"normal"
var artifact_mode: StringName = GameSession.ARTIFACT_MODE_DISABLED
var build_policy: BalanceAuditBuildPolicy
var skill_policy: BalanceAuditSkillPolicy
var movement_policy: BalanceAuditMovementPolicy
var active_policy: BalanceAuditActivePolicy
var placement_policy: BalanceAuditPlacementPolicy
var policy_action_counts: Dictionary = {"movement_commands": 0, "core_skill_casts": 0, "upgrade_selections": 0, "formation_placements": 0}
var policy_action_log: Array[Dictionary] = []
var command_accumulator := 0.0
var finished := false
var timed_out := false
var real_started_msec: int = 0
var final_boss_first_seen_at := -1.0
var final_boss_initial_health := 0.0
var final_boss_last_health := 0.0
var final_boss_core_health_at_spawn := 0.0
var controlled_final_boss_probe := false
var controlled_final_boss_elapsed := 0.0
var cleanup_frames_remaining := -1
var cleanup_exit_code := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	MetaProgressionService.set_testing_content_lock_bypass(true)
	# 편대 발견 보정은 개인 세이브의 플레이 이력에 따라 달라진다. 같은
	# 시나리오·시드가 언제 실행되더라도 동일하도록 신규 계정의 시작 병종
	# 발견 상태를 감사 전용 메모리 픽스처로 고정한다.
	SaveManager.discovered_tower_use_ids = SaveManager.STARTER_TOWER_IDS.duplicate()
	# 밸런스 감사는 오디오 동작을 검증하지 않는다. 고속 재생 중 발생하는
	# AudioStreamPlayback 잔여 참조가 종료 결과를 오염하지 않도록 처음부터 음소거한다.
	AudioManager.muted = true
	real_started_msec = Time.get_ticks_msec()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenario="):
			scenario_name = argument.trim_prefix("--scenario=")
		elif argument.begins_with("--audit-seconds="):
			audit_target_seconds = maxf(float(argument.trim_prefix("--audit-seconds=")), 30.0)
		elif argument.begins_with("--seed="):
			audit_seed = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--speed="):
			audit_speed = clampi(int(argument.trim_prefix("--speed=")), 1, 3)
		elif argument.begins_with("--build-policy="):
			build_policy_id = StringName(argument.trim_prefix("--build-policy="))
		elif argument.begins_with("--skill-policy="):
			skill_policy_id = StringName(argument.trim_prefix("--skill-policy="))
		elif argument.begins_with("--bonus-mode="):
			bonus_mode = StringName(argument.trim_prefix("--bonus-mode="))
		elif argument.begins_with("--artifact-mode="):
			artifact_mode = StringName(argument.trim_prefix("--artifact-mode="))
		elif argument == "--final-boss-probe":
			controlled_final_boss_probe = true
	if not SCENARIOS.has(scenario_name) or build_policy_id not in BalanceAuditBuildPolicy.IDS or skill_policy_id not in BalanceAuditSkillPolicy.IDS or bonus_mode not in EnemySpawnDirector.BONUS_MODES or artifact_mode not in GameSession.ARTIFACT_MODES or not ConceptService.load_profile(PROFILE_PATH):
		push_error("BALANCE AUDIT SETUP FAILED: %s" % scenario_name)
		get_tree().quit(2)
		return
	build_policy = BalanceAuditBuildPolicy.new(build_policy_id)
	skill_policy = BalanceAuditSkillPolicy.new(skill_policy_id)
	movement_policy = BalanceAuditMovementPolicy.new(skill_policy_id)
	active_policy = BalanceAuditActivePolicy.new(skill_policy_id)
	placement_policy = BalanceAuditPlacementPolicy.new(skill_policy_id)
	var scenario: Dictionary = SCENARIOS[scenario_name]
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate_for_core(scenario.core)
	if candidate == null:
		push_error("BALANCE AUDIT CANDIDATE MISSING")
		get_tree().quit(2)
		return
	SaveManager.candidate_support[String(candidate.id)] = candidate.support_required_for_election
	if String(candidate.id) not in SaveManager.elected_candidate_ids:
		SaveManager.elected_candidate_ids.append(String(candidate.id))
	SaveManager.candidate_decree_ids[String(candidate.id)] = String(scenario.decree)
	SaveManager.governance_approval[String(candidate.id)] = 50
	GameSession.selected_core_id = scenario.core
	GameSession.selected_cursor_id = scenario.cursor
	GameSession.selected_decree_id = scenario.decree
	GameSession.selected_challenge_level = 0
	GameSession.artifact_mode = artifact_mode
	game = (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	game.testing_mode = true
	game.testing_random_seed = audit_seed
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	if game.game_phase == GameTypes.GamePhase.PREPARATION and game.preparation_panel.visible:
		game.preparation_panel._confirm()
		await get_tree().process_frame
	if not game.block_board_active or game.game_phase != GameTypes.GamePhase.RUNNING:
		push_error("BALANCE AUDIT BLOCK BOARD SETUP FAILED")
		_cleanup_and_quit(2)
		return
	game.enemy_spawner.spawn_director.configure_bonus_mode(bonus_mode)
	if controlled_final_boss_probe:
		_configure_controlled_final_boss_probe()
	game.game_speed_index = audit_speed - 1
	game._apply_game_speed(true)
	print("BALANCE AUDIT START %s · %s + %s · seed %d · %s/%s/%s · artifact %s · %dx" % [scenario_name, scenario.core, scenario.cursor, audit_seed, build_policy_id, skill_policy_id, bonus_mode, artifact_mode, audit_speed])

func _physics_process(delta: float) -> void:
	if cleanup_frames_remaining >= 0:
		cleanup_frames_remaining -= 1
		if cleanup_frames_remaining <= 0:
			get_tree().quit(cleanup_exit_code)
		return
	if finished or game == null or not is_instance_valid(game):
		return
	if Time.get_ticks_msec() - real_started_msec >= 260000:
		timed_out = true
		_finish_audit()
		return
	if controlled_final_boss_probe:
		controlled_final_boss_elapsed += delta
	if game.game_finished:
		if game.game_phase == GameTypes.GamePhase.VICTORY:
			final_boss_last_health = 0.0
		_finish_audit()
		return
	_track_final_boss()
	var stage_duration := game.stage_data.duration_seconds
	if controlled_final_boss_probe and controlled_final_boss_elapsed >= 90.0:
		_finish_audit()
		return
	if not controlled_final_boss_probe and audit_target_seconds < stage_duration and game.enemy_spawner.elapsed >= audit_target_seconds:
		_finish_audit()
		return
	# 최종 보스는 타임라인 종료 시점에 등장한다. 600초 감사에서는 등장 즉시
	# 종료하지 않고 실제 처치/돌파와 결과창 전환을 확인할 시간을 준다.
	if not controlled_final_boss_probe and audit_target_seconds >= stage_duration and game.enemy_spawner.elapsed >= stage_duration + 90.0:
		_finish_audit()
		return
	if game.selecting_upgrade:
		_resolve_upgrade()
		return
	if game.game_phase != GameTypes.GamePhase.RUNNING:
		return
	command_accumulator += delta
	if command_accumulator < movement_policy.command_interval():
		return
	command_accumulator = 0.0
	var movement := movement_policy.choose_destination(game)
	if not movement.is_empty():
		var destination := movement.position as Vector2
		game.target_cursor.set_destination(destination)
		_record_policy_action(&"movement", String(movement.reason), {"target_enemy_id": String(movement.get("target_enemy_id", "")), "target_orb_channel": String(movement.get("target_orb_channel", "")), "destination_x": snappedf(destination.x, 0.001), "destination_y": snappedf(destination.y, 0.001)})
	var core_ready := game.core.skill_charge >= game.core.data.skill_charge_seconds and not game.core.is_skill_casting()
	if active_policy.should_cast_core_skill(core_ready, game.enemy_spawner.elapsed):
		game._request_core_skill()
		_record_policy_action(&"core_skill", "public charge ready", {})

func _track_final_boss() -> void:
	if game.boss_plan == null:
		return
	var candidates := game._active_enemies()
	if game.current_boss != null and is_instance_valid(game.current_boss) and game.current_boss not in candidates:
		candidates.append(game.current_boss)
	for enemy in candidates:
		if enemy.data == null or enemy.data.id != game.boss_plan.final_boss_id:
			continue
		if final_boss_first_seen_at < 0.0:
			final_boss_first_seen_at = game.enemy_spawner.elapsed
			final_boss_initial_health = enemy.get_max_health()
			final_boss_core_health_at_spawn = game.core.current_health
		final_boss_last_health = enemy.current_health
		return

func _configure_controlled_final_boss_probe() -> void:
	game.enemy_spawner.stop()
	# 후보 친위대는 준비 단계에서 이미 배치됐다. 일반 편대만 현재 보드의
	# 실제 유효 위치를 사용해 추가하여 블록 전장의 결전 구성을 만든다.
	for formation_id: StringName in [&"execution", &"precision", &"balanced"]:
		var formation := DataRegistry.get_formation(formation_id)
		var placements := game.loadout.get_valid_board_placements(formation)
		if placements.is_empty():
			continue
		var placement := placements[placements.size() / 2] as Dictionary
		game.loadout.place_formation_block(formation, placement.anchor as Vector2i, bool(placement.vertical_flipped))
	game.loadout.claim_candidate_fixed_upgrade(0)
	var execution_branches := game.loadout.get_candidate_branch_choices()
	for branch_choice in execution_branches:
		if branch_choice.data_id == &"judaginda_death_affinity":
			game.loadout.apply_candidate_branch(branch_choice)
			break
	game.loadout.claim_candidate_fixed_upgrade(2)
	_apply_track_to_level_four(&"cursor_level", &"cursor_branch", &"vanguard_hunt")
	_apply_tower_to_level_seven(&"execute", &"execute_cycle")
	_apply_tower_to_level_seven(&"pierce", &"pierce_execute")
	game._apply_runtime_loadout_stats()
	game.experience.level = 25
	game.enemy_spawner.elapsed = game.stage_data.duration_seconds
	game.metrics.update_time(game.enemy_spawner.elapsed)
	var final_data := game.enemy_spawner.boss_pool.back() as EnemyData
	game._on_spawn_requested(0.14, final_data, game.stage_data.boss_health_multiplier_at(1.0), game.stage_data.speed_multiplier_at(1.0))
	_track_final_boss()

func _apply_track_to_level_four(level_category: StringName, branch_category: StringName, branch_id: StringName) -> void:
	game.loadout.apply_upgrade(UpgradeData.new().configure(level_category, "결전 성장 2", "controlled audit", &"track"))
	game.loadout.apply_upgrade(UpgradeData.new().configure(level_category, "결전 성장 3", "controlled audit", &"track"))
	game.loadout.apply_upgrade(UpgradeData.new().configure(branch_category, "결전 특화", "controlled audit", branch_id))

func _apply_tower_to_level_seven(tower_id: StringName, branch_id: StringName) -> void:
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"tower_type_level", "결전 타워 2", "controlled audit", tower_id))
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"tower_type_level", "결전 타워 3", "controlled audit", tower_id))
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"tower_branch", "결전 타워 특화", "controlled audit", branch_id))
	for next_level in range(5, 8):
		game.loadout.apply_upgrade(UpgradeData.new().configure(&"tower_type_level", "결전 타워 %d" % next_level, "controlled audit", tower_id))

func _resolve_upgrade() -> void:
	var panel := game.level_up_panel
	if game.pending_artifact_choice != null:
		_resolve_artifact_inventory_choice()
		return
	if game.pending_block_formation_choice != null and game.preparation_panel.visible:
		var formation := DataRegistry.get_formation(game.pending_block_formation_choice.data_id)
		if formation == null:
			return
		if not game.loadout.can_place_formation_block(formation, game.preparation_panel.selected_anchor, game.preparation_panel.vertical_flipped):
			var placements := game.loadout.get_valid_board_placements(formation)
			if placements.is_empty():
				game.preparation_panel._confirm_abandon()
				return
			var placement := placements[placement_policy.placement_index(placements)] as Dictionary
			game.preparation_panel.selected_anchor = placement.anchor as Vector2i
			game.preparation_panel.vertical_flipped = bool(placement.vertical_flipped)
			game.preparation_panel._refresh_grid()
		_record_policy_action(&"formation_placement", placement_policy.selection_reason(), {"formation_id": String(formation.id)})
		game.preparation_panel._confirm()
		return
	if panel.choices.is_empty():
		return
	var best_choice := panel.choices[0]
	var best_score := _choice_score(best_choice)
	var best_tie_break_score := _choice_tie_break_score(best_choice)
	for choice in panel.choices:
		var score := _choice_score(choice)
		var tie_break_score := _choice_tie_break_score(choice)
		if score > best_score or (score == best_score and tie_break_score > best_tie_break_score):
			best_choice = choice
			best_score = score
			best_tie_break_score = tie_break_score
	_record_policy_action(&"upgrade_selection", build_policy.selection_reason(best_choice, _choice_context(best_choice)), {"category": String(best_choice.category), "data_id": String(best_choice.data_id), "score": best_score, "tie_break_score": best_tie_break_score})
	game._on_upgrade_selected(best_choice)

func _resolve_artifact_inventory_choice() -> void:
	var incoming := game.loadout.artifact_catalog.find_artifact(game.pending_artifact_choice.data_id) if game.loadout.artifact_catalog != null else null
	if incoming == null:
		game._on_artifact_discard_requested()
		return
	var incoming_utility := _artifact_utility(incoming)
	var weakest_index := -1
	var weakest_utility := INF
	var equipped := game.loadout.get_equipped_artifacts()
	for index in equipped.size():
		var utility := _artifact_utility(equipped[index])
		if utility < weakest_utility:
			weakest_utility = utility
			weakest_index = index
	if weakest_index >= 0 and incoming_utility > weakest_utility:
		_record_policy_action(&"artifact_resolution", "public effect utility replaces weakest equipped artifact", {"artifact_id": String(incoming.id), "slot_index": weakest_index, "incoming_utility": incoming_utility, "replaced_utility": weakest_utility})
		game._on_artifact_replacement_requested(weakest_index)
	else:
		_record_policy_action(&"artifact_resolution", "public effect utility keeps current inventory", {"artifact_id": String(incoming.id), "incoming_utility": incoming_utility, "weakest_utility": weakest_utility})
		game._on_artifact_discard_requested()

func _artifact_utility(artifact: ArtifactData) -> float:
	var utility := 0.0
	for effect in artifact.effects:
		if effect == null:
			continue
		var value := effect.value / 100.0 if effect.value_mode == ArtifactEffectData.FIXED_BONUS else effect.value
		utility += value
	if artifact.has_trade_off():
		utility -= 0.08
	return utility

func _choice_score(choice: UpgradeData) -> int:
	return build_policy.score_choice(choice, _choice_context(choice))

func _choice_tie_break_score(choice: UpgradeData) -> int:
	return build_policy.tie_break_score(choice, _choice_context(choice))

func _choice_context(choice: UpgradeData) -> Dictionary:
	var valid := true
	var formation_score := 0
	var valid_position_count := 0
	if choice.requires_placement and choice.category == &"new_formation":
		var block_formation := DataRegistry.get_formation(choice.data_id)
		valid = block_formation != null
		if block_formation != null:
			formation_score = block_formation.formation_score
			valid_position_count = game.loadout.get_valid_board_placements(block_formation).size()
			valid = valid_position_count > 0
	var regular_formation_count := 0
	for placement in game.loadout.board_state.placements.values():
		if not bool((placement as Dictionary).get("is_guard", false)):
			regular_formation_count += 1
	return {
		"valid": valid,
		"regular_formation_count": regular_formation_count,
		"formation_score": formation_score,
		"valid_position_count": valid_position_count,
		"core_level": game.loadout.core_state.current_level,
		"cursor_level": game.loadout.cursor_state.current_level,
		"elapsed": game.enemy_spawner.elapsed,
		"scenario": scenario_name,
		"audit_seed": audit_seed,
		"selection_index": int(policy_action_counts.get("upgrade_selections", 0)),
		"artifact_inventory_count": game.loadout.artifact_inventory.artifact_ids.size(),
		"scenario_priority": _legacy_choice_score(choice, regular_formation_count),
	}

func _legacy_choice_score(choice: UpgradeData, regular_formation_count: int) -> int:
	if scenario_name == "royal_armament":
		if choice.category == &"candidate_branch" and choice.data_id == &"partason_elitism":
			return 127
		if choice.category == &"candidate_branch":
			return 121
		if choice.category == &"cursor_specialization_entry":
			return 119
		if choice.category in [&"cursor_branch", &"cursor_level"]:
			return 117
	elif scenario_name == "necromancy_vanguard":
		if choice.category == &"candidate_branch" and choice.data_id == &"irelai_soul_harvest":
			return 127
		if choice.category == &"candidate_branch":
			return 121
		if choice.category == &"core_branch" and choice.data_id == &"jade_stable":
			return 121
		if choice.category == &"core_specialization_entry":
			return 119
		if choice.category == &"core_level":
			return 118 if game.loadout.core_state.current_level < 4 or game.enemy_spawner.elapsed >= 240.0 else 105
		if choice.category in [&"cursor_specialization_entry", &"cursor_branch", &"cursor_level"]:
			return 117 if game.loadout.core_state.current_level < 4 or game.enemy_spawner.elapsed >= 240.0 else 100
	elif scenario_name == "charm_combo":
		if choice.category == &"candidate_branch" and choice.data_id == &"jiane_betraying_love":
			return 126
		if choice.category == &"candidate_branch":
			return 120
		if choice.category == &"cursor_branch" and choice.data_id == &"platinum_charge":
			return 121
		if choice.category == &"cursor_specialization_entry":
			return 119
		if choice.category == &"cursor_level":
			return 118 if game.loadout.cursor_state.current_level < 4 or game.enemy_spawner.elapsed >= 240.0 else 105
		if choice.category in [&"core_specialization_entry", &"core_branch", &"core_level"]:
			return 117 if game.loadout.cursor_state.current_level < 4 or game.enemy_spawner.elapsed >= 240.0 else 100
	elif scenario_name == "abyss_research":
		if choice.category == &"candidate_branch" and choice.data_id == &"kasuha_mass_summoning":
			return 127
		if choice.category == &"candidate_branch":
			return 121
		if choice.category == &"cursor_specialization_entry":
			return 119
		if choice.category in [&"cursor_branch", &"cursor_level"]:
			return 117
	elif scenario_name == "judgment_vanguard":
		if choice.category == &"candidate_branch" and choice.data_id == &"judaginda_death_affinity":
			return 127
		if choice.category == &"candidate_branch":
			return 121
		if choice.category == &"cursor_specialization_entry" and choice.data_id == &"vanguard":
			return 125
		if choice.category == &"cursor_branch" and choice.data_id == &"vanguard_hunt":
			return 123
	match choice.category:
		&"formation_set": return 130 if regular_formation_count < 4 else 90
		&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry": return 115
		&"tower_branch", &"core_branch", &"cursor_branch": return 112
		&"candidate_branch": return 114
		&"tower_type_level": return 108
		&"core_level": return 116 if game.loadout.core_state.current_level < 4 else 100
		&"cursor_level": return 116 if game.loadout.cursor_state.current_level < 4 else 100
		# 한 편대만 7레벨까지 올리는 감사 결과는 실제 선택 전략을 대표하지 못한다.
		# 최소 네 열을 확보한 뒤 종류 강화에 들어가도록 자동 선택 기준을 잡는다.
		&"new_formation":
			var formation := DataRegistry.get_formation(choice.data_id)
			if formation == null:
				return -100
			var valid_positions := game.loadout.get_valid_board_placements(formation).size()
			return 120 + roundi(float(formation.formation_score) / 20.0) + mini(valid_positions, 12)
		&"status_upgrade": return 88
		&"global_upgrade": return 84
		_: return 60

func _record_policy_action(kind: StringName, reason: String, details: Dictionary) -> void:
	var count_key: String = String({&"movement": "movement_commands", &"core_skill": "core_skill_casts", &"upgrade_selection": "upgrade_selections", &"formation_placement": "formation_placements"}.get(kind, String(kind)))
	policy_action_counts[count_key] = int(policy_action_counts.get(count_key, 0)) + 1
	if policy_action_log.size() >= 256:
		return
	var event := {"elapsed": game.enemy_spawner.elapsed, "kind": String(kind), "reason": reason}
	event.merge(details, true)
	policy_action_log.append(event)

func _finish_audit() -> void:
	finished = true
	Engine.time_scale = 1.0
	var metrics := game.metrics
	_track_final_boss()
	var final_boss_killed_at := float(metrics.boss_kill_times.get(String(game.boss_plan.final_boss_id), -1.0))
	var measured_final_boss_ttk := final_boss_killed_at - final_boss_first_seen_at if final_boss_killed_at >= 0.0 and final_boss_first_seen_at >= 0.0 else -1.0
	if controlled_final_boss_probe and game.game_phase == GameTypes.GamePhase.VICTORY:
		measured_final_boss_ttk = controlled_final_boss_elapsed
	var runtime_performance := metrics._runtime_performance_snapshot()
	var spawn_snapshot := game.enemy_spawner.spawn_budget_snapshot()
	var generated_experience := float(spawn_snapshot.get("base_spawn_experience", 0.0)) + float(spawn_snapshot.get("bonus_spawn_experience", 0.0))
	var orb_experience := metrics.experience_attribution_snapshot()
	var orb_channels := orb_experience.get("by_channel", {}) as Dictionary
	var base_orbs := orb_channels.get("base", {}) as Dictionary
	var bonus_orbs := orb_channels.get("bonus", {}) as Dictionary
	var report := {
		"audit_schema_version": AUDIT_REPORT_SCHEMA_VERSION,
		"build_policy_revision": BalanceAuditBuildPolicy.REVISION,
		"rng_revision": RunRng.REVISION,
		"artifact_mode": String(artifact_mode),
		"scenario": scenario_name,
		"seed": audit_seed,
		"game_speed": audit_speed,
		"selection_policy": String(build_policy_id),
		"build_policy": String(build_policy_id),
		"skill_policy": String(skill_policy_id),
		"skill_policy_components": skill_policy.component_ids(),
		"bonus_mode": String(bonus_mode),
		"policy_actions": policy_action_counts.duplicate(true),
		"policy_action_log": policy_action_log.duplicate(true),
		"audit_meta_fixture": {
			"id": META_FIXTURE_ID,
			"discovered_tower_use_ids": SaveManager.STARTER_TOWER_IDS.duplicate(),
		},
		"block_board": game.block_board_active,
		"audit_target_seconds": audit_target_seconds,
		"elapsed": game.enemy_spawner.elapsed,
		"timed_out": timed_out,
		"victory": game.game_phase == GameTypes.GamePhase.VICTORY,
		"game_finished": game.game_finished,
		"result_visible": game.hud.result_panel.visible,
		"controlled_final_boss_probe": controlled_final_boss_probe,
		"level": game.experience.level,
		"total_experience": game.experience.total_experience,
		"current_experience": game.experience.current_experience,
		"required_experience": game.experience.required_experience,
		"experience_curve": {
			"late_start_level": ExperienceManager.LATE_CURVE_START_LEVEL,
			"late_growth_multiplier": ExperienceManager.LATE_CURVE_GROWTH_MULTIPLIER,
		},
		"experience_attribution": {
			"base_generated": float(spawn_snapshot.get("base_spawn_experience", 0.0)),
			"bonus_generated": float(spawn_snapshot.get("bonus_spawn_experience", 0.0)),
			"non_boss_generated": generated_experience,
			"base_dropped": float(base_orbs.get("dropped", 0.0)),
			"bonus_dropped": float(bonus_orbs.get("dropped", 0.0)),
			"base_collected_raw": float(base_orbs.get("collected_raw", 0.0)),
			"bonus_collected_raw": float(bonus_orbs.get("collected_raw", 0.0)),
			"base_collection_rate": float(base_orbs.get("collection_rate", 0.0)),
			"bonus_collection_rate": float(bonus_orbs.get("collection_rate", 0.0)),
			"collected": game.experience.total_experience,
			"generated_collection_ratio": game.experience.total_experience / generated_experience if generated_experience > 0.0 else 0.0,
			"collection_ratio": float(orb_experience.get("collection_rate", 0.0)),
			"orbs": orb_experience,
		},
		"growth_timeline": metrics.growth_timeline_snapshot(),
		"enemy_removal": metrics.enemy_removal_snapshot(),
		"control_effectiveness": metrics.control_effectiveness_snapshot(),
		"kills": game.kill_count,
		"boss_kills": game.boss_kill_count,
		"core_health": game.core.current_health,
		"core_max_health": game.core.max_health,
		"runtime_performance": runtime_performance,
		"performance_budget": RuntimePerformanceBudget.assess(runtime_performance),
		"spawn_director": spawn_snapshot,
		"outcome_summary": RunOutcomeSummary.build(game.stage_data, metrics, game.loadout, spawn_snapshot),
		"mechanic_events": metrics.mechanic_events,
		"mechanic_totals": metrics.mechanic_totals,
		"mechanic_sample_averages": metrics._mechanic_sample_averages(),
		"mechanic_sample_peaks": metrics.mechanic_sample_peaks,
		"selected_upgrades": metrics.selected_upgrades,
		"upgrade_choice_metrics": metrics.upgrade_choice_metrics_snapshot(),
		"artifact_metrics": metrics.artifact_metrics_snapshot(game.loadout),
		"artifacts": game.loadout.get_artifact_snapshot(),
		"formation_metrics": metrics.formation_metrics_snapshot(),
		"guard_combat": metrics.guard_combat,
		"formation_board": game.loadout.get_board_snapshot(),
		"tower_score_efficiency": _tower_score_efficiency_snapshot(metrics),
		"rerolls_used": GameController.LEVEL_UP_REROLL_LIMIT - game.level_up_rerolls_remaining,
		"loadout_summary": game.loadout.get_build_summary(),
		"tower_damage": metrics.tower_damage,
		"cursor_damage": metrics.cursor_damage,
		"boss_damage": metrics.boss_damage,
		"final_boss_id": String(game.boss_plan.final_boss_id),
		"final_boss_first_seen_at": final_boss_first_seen_at,
		"final_boss_challenged": final_boss_first_seen_at >= 0.0,
		"final_boss_initial_health": final_boss_initial_health,
		"final_boss_last_health": final_boss_last_health,
		"final_boss_damage_dealt": maxf(final_boss_initial_health - final_boss_last_health, 0.0),
		"final_boss_core_health_at_spawn": final_boss_core_health_at_spawn,
		"final_boss_survival_seconds": controlled_final_boss_elapsed if controlled_final_boss_probe else (maxf(game.enemy_spawner.elapsed - final_boss_first_seen_at, 0.0) if final_boss_first_seen_at >= 0.0 else 0.0),
		"final_boss_killed_at": final_boss_killed_at,
		"final_boss_ttk": measured_final_boss_ttk,
	}
	var report_json := JSON.stringify(report)
	print("BALANCE_AUDIT_RESULT %s" % report_json)
	# Windows 자식 프로세스 캡처는 콘솔 코드페이지에 따라 한글 JSON을 손상시킬 수 있다.
	# 사람이 읽는 원문은 유지하고 매트릭스 집계에는 ASCII 안전 전송 라인을 제공한다.
	print("BALANCE_AUDIT_RESULT_B64 %s" % Marshalls.utf8_to_base64(report_json))
	call_deferred("_cleanup_and_quit", 0)

func _tower_score_efficiency_snapshot(metrics: RunMetrics) -> Dictionary:
	var installed_counts: Dictionary = {}
	for column in game.loadout.columns:
		if column.is_guard_formation:
			continue
		for tower in column.row_towers:
			if tower == null:
				continue
			var tower_key := String(tower.id)
			installed_counts[tower_key] = int(installed_counts.get(tower_key, 0)) + 1
	var result: Dictionary = {}
	var score_minutes_by_tower := _formation_score_minutes_by_tower(metrics.formation_selection_events, game.enemy_spawner.elapsed)
	var guard_damage_by_tower: Dictionary = {}
	for guard_value in metrics.guard_combat.values():
		var guard := guard_value as Dictionary
		for tower_key in (guard.get("by_tower", {}) as Dictionary):
			var tower_sample := (guard.by_tower as Dictionary)[tower_key] as Dictionary
			guard_damage_by_tower[tower_key] = float(guard_damage_by_tower.get(tower_key, 0.0)) + float(tower_sample.get("damage", 0.0))
	var measured_minutes := maxf(game.enemy_spawner.elapsed / 60.0, 1.0 / 60.0)
	for tower_key in installed_counts:
		var tower := DataRegistry.get_tower(StringName(tower_key))
		if tower == null:
			continue
		var installed_count := int(installed_counts[tower_key])
		var score_budget := tower.formation_power_rating * installed_count
		var score_minutes := float(score_minutes_by_tower.get(tower_key, score_budget * measured_minutes))
		var damage := maxf(float(metrics.tower_damage.get(tower_key, 0.0)) - float(guard_damage_by_tower.get(tower_key, 0.0)), 0.0)
		result[tower_key] = {
			"installed": installed_count,
			"formation_score_budget": score_budget,
			"formation_score_minutes": score_minutes,
			"damage": damage,
			"damage_per_score_minute": damage / maxf(score_minutes, 1.0),
			"efficiency_role": _tower_efficiency_role(tower.behavior),
			"efficiency_cohort": _tower_efficiency_cohort(tower.behavior),
		}
	return result

func _formation_score_minutes_by_tower(selection_events: Array[Dictionary], elapsed_seconds: float) -> Dictionary:
	var result: Dictionary = {}
	for event in selection_events:
		var formation := DataRegistry.get_formation(StringName(event.get("formation_id", "")))
		if formation == null or formation.is_guard:
			continue
		var active_minutes := maxf(elapsed_seconds - float(event.get("elapsed", elapsed_seconds)), 0.0) / 60.0
		for tower_id in formation.get_tower_ids():
			var tower := DataRegistry.get_tower(tower_id)
			if tower != null:
				result[String(tower_id)] = float(result.get(String(tower_id), 0.0)) + tower.formation_power_rating * active_minutes
	return result

func _tower_efficiency_role(behavior: StringName) -> String:
	match behavior:
		&"rapid", &"area", &"pierce", &"execute", &"chain":
			return "damage"
		&"knockback":
			return "hybrid_control"
		&"mark":
			return "support"
		&"slow", &"golem":
			return "control"
	return "other"

func _tower_efficiency_cohort(behavior: StringName) -> String:
	match behavior:
		&"rapid", &"area":
			return "sustained_damage"
		&"chain":
			return "network_damage"
		&"pierce", &"execute":
			return "precision_damage"
		&"knockback":
			return "hybrid_control"
		&"mark":
			return "support"
		&"slow", &"golem":
			return "control"
	return "other"

func _cleanup_and_quit(exit_code: int = 0) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	# 게임 노드 해제 중 발생할 수 있는 마지막 효과음 요청을 먼저 차단한다.
	AudioManager.muted = true
	if game != null and is_instance_valid(game):
		# 이미 지연 호출 경계에 있으므로 즉시 해제해 종료 시점에 SceneTree와
		# GDScriptFunctionState가 서로를 붙잡는 잔여 참조를 만들지 않는다.
		game.free()
	game = null
	AudioManager.release_voice_pool()
	# 오디오 믹서가 중지된 playback을 확실히 반납하도록 코루틴 참조 없이
	# 짧은 프레임 유예를 둔다. 3배속은 위에서 이미 1배속으로 복원했다.
	cleanup_exit_code = exit_code
	cleanup_frames_remaining = 6
