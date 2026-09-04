extends Node

const OUTPUT_DIR := "res://tests/ui_snapshots"

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("UI snapshot skipped: a rendered display is required")
		get_tree().quit(0)
		return
	AudioManager.muted = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var meta_state_backup := SaveManager._build_save_data()
	var cleared_stage_backup := SaveManager.cleared_stage_ids.duplicate()
	var highest_challenge_backup := SaveManager.highest_challenge_by_stage.duplicate(true)
	var selected_challenge_backup := SaveManager.selected_challenge_by_stage.duplicate(true)
	SaveManager.cleared_stage_ids.erase("standard_20m")
	SaveManager.highest_challenge_by_stage.erase("standard_20m")
	SaveManager.selected_challenge_by_stage.erase("standard_20m")
	SaveManager.defense_funds = 300
	SaveManager.legacy_full_unlock = false
	SaveManager.unlocked_ids.assign(["emerald", "iron"])
	SaveManager.candidate_first_clear_ids.clear()
	SaveManager.retainer_first_clear_ids.clear()
	SaveManager.discovered_shop_product_ids.clear()
	SaveManager.purchased_shop_product_ids.assign(["tower_slow"])
	SaveManager.unlocked_tower_ids.assign(SaveManager.STARTER_TOWER_IDS + ["slow"])
	SaveManager.unlocked_feature_ids.assign(SaveManager.STARTER_FEATURE_IDS + ["shop_system", "achievement_system", "codex_system"])
	SaveManager.completed_achievement_ids.assign(["unlock_meta_hub", "discover_tower_slow"])
	SaveManager.claimed_achievement_ids.assign(SaveManager.completed_achievement_ids)
	SaveManager.achievement_progress = {"discover_tower_mark": 4500.0, "unlock_status_growth_burn": 24.0}
	SaveManager.tutorial_completed = true
	var menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await _settle()
	_capture("title_screen")
	menu._enter_main_hub()
	await _settle()
	_capture("main_menu")
	(menu.get_node("%GameMenuButton") as Button).pressed.emit()
	await _settle()
	_capture("game_setup")
	_capture("challenge_locked")
	SaveManager.cleared_stage_ids.append("standard_20m")
	SaveManager.highest_challenge_by_stage["standard_20m"] = 4
	SaveManager.selected_challenge_by_stage["standard_20m"] = 5
	menu._configure_challenge_selector()
	menu._update_records()
	await _settle()
	_capture("challenge_unlocked")
	(menu.get_node("%GameBackButton") as Button).pressed.emit()
	(menu.get_node("%ShopMenuButton") as Button).pressed.emit()
	await _settle()
	_capture("shop")
	(menu.get_node("%ShopBackButton") as Button).pressed.emit()
	(menu.get_node("%AchievementMenuButton") as Button).pressed.emit()
	await _settle()
	_capture("achievements")
	(menu.get_node("%AchievementBackButton") as Button).pressed.emit()
	(menu.get_node("%CodexMenuButton") as Button).pressed.emit()
	await _settle()
	menu._select_codex_category(&"core")
	await _settle()
	_capture("codex_candidates")
	menu._select_codex_category(&"tower")
	await _settle()
	_capture("codex")
	menu._select_codex_category(&"formation")
	await _settle()
	_capture("codex_formations")
	menu._select_codex_category(&"terms")
	await _settle()
	_capture("codex_terms")
	SaveManager.legacy_full_unlock = true
	menu._select_codex_category(&"enemy")
	await _settle()
	var faction_codex_entry := menu.codex_browser.entries.filter(func(entry: Dictionary) -> bool: return entry.id == &"jiane_succubus_bewitcher").front() as Dictionary
	menu.codex_browser._select_entry(faction_codex_entry)
	await _settle()
	_capture("codex_faction_enemy")
	SaveManager.legacy_full_unlock = false
	menu.queue_free()
	await get_tree().process_frame
	var default_concept_path := ConceptService.active_path
	ConceptService.load_profile("res://data/concepts/example_arcane_reskin.tres")
	var reskin_menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(reskin_menu)
	await _settle()
	reskin_menu._enter_main_hub()
	await _settle()
	_capture("concept_reskin_example")
	reskin_menu.queue_free()
	await get_tree().process_frame
	ConceptService.load_profile("res://data/concepts/demon_election_vertical_slice.tres")
	SaveManager.candidate_support["judaginda"] = 1000
	if "judaginda" not in SaveManager.elected_candidate_ids:
		SaveManager.elected_candidate_ids.append("judaginda")
	SaveManager.candidate_decree_ids["judaginda"] = "bell_of_judgment"
	SaveManager.governance_approval["judaginda"] = 86
	var election_menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(election_menu)
	await _settle()
	election_menu._enter_main_hub()
	await _settle()
	_capture("demon_election_vertical_slice")
	(election_menu.get_node("%GameMenuButton") as Button).pressed.emit()
	await _settle()
	var fifth_candidate_option := election_menu.get_node("%CoreOption") as OptionButton
	var fifth_retainer_option := election_menu.get_node("%CursorOption") as OptionButton
	fifth_candidate_option.select(4)
	fifth_retainer_option.select(4)
	fifth_candidate_option.item_selected.emit(4)
	fifth_retainer_option.item_selected.emit(4)
	await _settle()
	var setup_detail_scroll := election_menu.get_node("%GameSetupPage/PageShell/Surface/Layout/Body/SetupScroll") as ScrollContainer
	setup_detail_scroll.scroll_vertical = roundi(setup_detail_scroll.get_v_scroll_bar().max_value)
	await _settle()
	_capture("demon_election_game_setup")
	election_menu.queue_free()
	await get_tree().process_frame
	GameSession.configure_tutorial()
	var tutorial_wrapper := (load("res://scenes/tutorial/tutorial_game.tscn") as PackedScene).instantiate()
	var tutorial_game := tutorial_wrapper.get_node("Game") as GameController
	tutorial_game.testing_mode = true
	add_child(tutorial_wrapper)
	await _settle()
	_capture("tutorial_movement")
	tutorial_game.tutorial_director.record_movement(TutorialDirector.MOVE_DISTANCE_REQUIRED)
	await _settle()
	_capture("tutorial_formation_placement")
	get_tree().paused = false
	tutorial_wrapper.queue_free()
	await get_tree().process_frame
	GameSession.end_tutorial_run()
	GameSession.selected_core_id = &"emerald"
	GameSession.selected_cursor_id = &"iron"
	GameSession.selected_decree_id = &""
	var orthodox_game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	orthodox_game.testing_mode = true
	await _add_running_block_game(orthodox_game)
	_capture("demon_election_partason_kanda_combat")
	orthodox_game.audience_stage.react(&"skill_release", Color("fff0a8"), 1.0, 1.8)
	await get_tree().create_timer(0.12).timeout
	_capture("audience_skill_release")
	orthodox_game.audience_stage.clear_reaction()
	orthodox_game.audience_stage.set_threat_level(AudienceReactionStage.THREAT_DANGER)
	await get_tree().create_timer(0.12).timeout
	_capture("audience_enemy_danger")
	orthodox_game.audience_stage.set_threat_level(AudienceReactionStage.THREAT_CLEAR)
	orthodox_game.audience_stage.set_reduced_motion_enabled(true)
	orthodox_game.audience_stage.react(&"skill_release", Color("fff0a8"), 1.0, 1.8)
	await get_tree().create_timer(0.12).timeout
	_capture("audience_reduced_motion_skill")
	orthodox_game.audience_stage.set_reduced_motion_enabled(false)
	orthodox_game.queue_free()
	await get_tree().process_frame
	GameSession.selected_core_id = &"sapphire"
	GameSession.selected_cursor_id = &"silver"
	GameSession.selected_decree_id = &""
	var charm_game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	charm_game.testing_mode = true
	await _add_running_block_game(charm_game)
	_capture("demon_election_jiane_given_combat")
	charm_game.loadout.candidate_progression.claim_fixed_slot(0)
	var charm_breach_position := charm_game.battlefield.get_core_goal_position(charm_game.battlefield.get_lane_y(2))
	var charm_breach_enemy := charm_game._spawn_enemy(DataRegistry.get_enemy(&"normal"), charm_breach_position, 2, 1.0, 1.0)
	charm_breach_enemy.set_process(false)
	charm_breach_enemy.set_physics_process(false)
	charm_game._present_core_breach(charm_breach_enemy)
	await get_tree().create_timer(0.12).timeout
	_capture("demon_election_jiane_dream_barrier")
	charm_breach_enemy.queue_free()
	charm_game.queue_free()
	await get_tree().process_frame
	GameSession.selected_core_id = &"amethyst"
	GameSession.selected_cursor_id = &"gold"
	GameSession.selected_decree_id = &""
	var abyss_game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	abyss_game.testing_mode = true
	await _add_running_block_game(abyss_game)
	_capture("demon_election_kasuha_jeomujeom_combat")
	abyss_game.queue_free()
	await get_tree().process_frame
	GameSession.selected_core_id = &"obsidian"
	GameSession.selected_cursor_id = &"vanguard"
	GameSession.selected_decree_id = &"bell_of_judgment"
	var election_game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	election_game.testing_mode = true
	await _add_running_block_game(election_game)
	election_game.enemy_spawner.set_physics_process(false)
	election_game.enemy_spawner.elapsed = 510.0
	election_game._update_faction_prelude_hud()
	await _settle()
	_capture("demon_election_faction_prelude_hud")
	election_game.hud.update_faction_prelude({"active": false})
	var verdict_position := election_game.battlefield.get_battle_rect().position + election_game.battlefield.get_battle_rect().size * Vector2(0.72, 0.5)
	election_game._record_candidate_execution({"executed": true}, verdict_position)
	await get_tree().create_timer(0.12).timeout
	_capture("demon_election_judaginda_verdict_seal")
	if election_game.vanguard_squad_component != null:
		election_game.vanguard_squad_component.record_execution()
	await get_tree().create_timer(0.12).timeout
	_capture("demon_election_vanguard_squad")
	election_game._on_boss_warning(DataRegistry.bosses[0], 0.34, 30.0)
	await _settle()
	_capture("demon_election_boss_warning")
	election_game.hud.warning_label.visible = false
	var faction_showcase_ids: Array[StringName] = [&"normal", &"fast", &"swarm", &"regenerator", &"charger"]
	var faction_showcase_rect := election_game.battlefield.get_battle_rect()
	for faction_index in faction_showcase_ids.size():
		var faction_enemy_data := DataRegistry.get_enemy(faction_showcase_ids[faction_index])
		var faction_enemy_position := Vector2(
			faction_showcase_rect.position.x + faction_showcase_rect.size.x * (0.38 + faction_index * 0.11),
			faction_showcase_rect.position.y + faction_showcase_rect.size.y * (0.18 + faction_index * 0.16)
		)
		var faction_enemy := election_game._spawn_enemy(faction_enemy_data, faction_enemy_position, election_game.battlefield.world_to_lane(faction_enemy_position), 1.0, 1.0)
		faction_enemy.set_process(false)
		faction_enemy.set_physics_process(false)
	var exit_faction := ConceptService.get_election_campaign().faction(&"jiane_faction")
	election_game._show_pattern_effect(
		faction_showcase_rect.position + faction_showcase_rect.size * Vector2(0.75, 0.54),
		exit_faction.primary_color,
		62.0,
		&"campaign_exit",
		0.72,
		1.0
	)
	await get_tree().create_timer(0.24).timeout
	_capture("demon_election_faction_showcase")
	var election_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"global_upgrade", "왕가의 호령", "유세 지원대 전체 강화\n수치 변화 · 피해 ×1.00 → ×1.08", &"global"),
		UpgradeData.new().configure(&"core_level", "연설 지속력 Lv.2", "후보 방어력 강화\n수치 변화 · 체력 ×1.00 → ×1.20", &"emerald"),
		UpgradeData.new().configure(&"cursor_level", "심복 기동 Lv.2", "심복 이동속도 강화\n수치 변화 · 이동속도 ×1.00 → ×1.12", &"iron"),
	]
	election_game.level_up_panel.show_choices(election_choices, 4, 2, 3)
	await _settle()
	_capture("demon_election_level_up")
	election_game.level_up_panel.hide_panel()
	election_game.hud.show_result({
		"victory": true, "stage_name": "마계 선거 결전", "stage_duration_seconds": 600.0,
		"challenge_level": 4, "challenge_experience_multiplier": 1.08, "elapsed": 600.0,
		"level": 24, "kills": 612, "boss_kills": 4,
		"boss_kill_ids": election_game.boss_plan.slots.map(func(slot: Dictionary) -> String: return String(slot.boss_id)),
		"boss_plan": election_game.boss_plan.to_snapshot(),
		"candidate_id": "judaginda", "candidate_name": "주다긴다", "candidate_elected": true,
		"candidate_support_earned": 0, "candidate_support_total": 1000, "candidate_support_required": 1000,
		"candidate_newly_elected": false, "governance_approval_before": 76, "governance_approval_delta": 10, "governance_approval": 86,
		"funds_earned": 438, "defense_funds_total": 1660,
		"funds_breakdown": {"progress_funds": 180, "boss_funds": 125, "victory_funds": 75, "challenge_multiplier": 1.12, "first_clear_funds": 0},
		"experience": 3180.0, "core_health": 94.0, "core": "죽음교주 주다긴다", "cursor": "죽음교 돌격부대",
		"retainer_name": "돌격부대", "retainer_contribution": {"role": "부대·처형", "damage": 6840.0, "control_applications": 18, "collection_experience": 492.0, "executions": 7, "unique_uses": 4},
		"decree_name": "심판의 종", "top_tower": "죽음교 판결관", "unlocked": "없음", "build": election_game.loadout.get_build_summary(),
	})
	await get_tree().create_timer(1.35).timeout
	_capture("demon_election_governance_result")
	election_game.queue_free()
	await get_tree().process_frame
	GameSession.selected_core_id = &"jade"
	GameSession.selected_cursor_id = &"platinum"
	var combo_game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	combo_game.testing_mode = true
	await _add_running_block_game(combo_game)
	_capture("demon_election_irelai_jugdied_combat")
	var combo_start := combo_game.core.global_position
	var combo_end := combo_game.target_cursor.global_position
	for ratio in [0.36, 0.58, 0.78]:
		var combo_enemy := combo_game._spawn_enemy(DataRegistry.get_enemy(&"armored"), combo_start.lerp(combo_end, ratio), combo_game.target_cursor.current_sector, 8.0, 1.0)
		combo_enemy.set_process(false)
		combo_enemy.set_physics_process(false)
	combo_game._trigger_retainer_combo()
	combo_game.hud.warning_label.visible = false
	await get_tree().create_timer(0.18).timeout
	_capture("demon_election_combo_reconstruction")
	combo_game.queue_free()
	await get_tree().process_frame
	GameSession.selected_core_id = &"obsidian"
	GameSession.selected_cursor_id = &"vanguard"
	ConceptService.load_profile(default_concept_path)
	SaveManager.cleared_stage_ids.assign(cleared_stage_backup)
	SaveManager.highest_challenge_by_stage = highest_challenge_backup
	SaveManager.selected_challenge_by_stage = selected_challenge_backup
	SaveManager._apply_save_data(meta_state_backup)
	await get_tree().process_frame
	var block_game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	block_game.testing_mode = true
	add_child(block_game)
	await _settle()
	_capture("formation_guard_preparation")
	block_game.preparation_panel._confirm()
	await _settle()
	_capture("formation_guard_deployed")
	var content_lock_bypass_backup := MetaProgressionService.testing_content_lock_bypass
	MetaProgressionService.set_testing_content_lock_bypass(true)
	RunRng.seed_run(13049)
	var formation_shape_choices := block_game.loadout.get_formation_candidates(3, 3)
	MetaProgressionService.set_testing_content_lock_bypass(content_lock_bypass_backup)
	block_game.level_up_panel.show_subchoices(formation_shape_choices, "블록 편대 형태", 2, false)
	await _settle()
	_capture("formation_shape_choices")
	if not formation_shape_choices.is_empty():
		block_game.level_up_panel._show_formation_details(0)
		await _settle()
		_capture("formation_shape_details")
	block_game.level_up_panel.hide_panel()
	var shape_formations := _representative_shape_formations(block_game.loadout)
	var primary_shape_choices: Array[UpgradeData] = []
	for shape: StringName in [TowerFormationData.SHAPE_LONG, TowerFormationData.SHAPE_BEND, TowerFormationData.SHAPE_COMPACT]:
		if shape_formations.has(shape):
			primary_shape_choices.append(_shape_audit_choice(block_game.loadout, shape_formations[shape] as TowerFormationData))
	block_game.level_up_panel.show_subchoices(primary_shape_choices, "4칸 형태 비교 · 직선/ㄴ자/압축", 8, false)
	await _settle()
	_capture("formation_shape_catalog_primary")
	var secondary_shape_choices: Array[UpgradeData] = []
	for shape: StringName in [TowerFormationData.SHAPE_STEP, TowerFormationData.SHAPE_BEND, TowerFormationData.SHAPE_COMPACT]:
		if shape_formations.has(shape):
			secondary_shape_choices.append(_shape_audit_choice(block_game.loadout, shape_formations[shape] as TowerFormationData))
	block_game.level_up_panel.show_subchoices(secondary_shape_choices, "4칸 형태 비교 · 계단형", 16, false)
	await _settle()
	_capture("formation_shape_catalog_step")
	if not secondary_shape_choices.is_empty():
		block_game.level_up_panel._show_formation_details(0)
		await _settle()
		_capture("formation_shape_step_details")
	block_game.level_up_panel.hide_panel()
	var captured_block_placement := false
	for shape: StringName in [TowerFormationData.SHAPE_LONG, TowerFormationData.SHAPE_BEND, TowerFormationData.SHAPE_COMPACT, TowerFormationData.SHAPE_STEP]:
		if not shape_formations.has(shape):
			continue
		block_game.preparation_panel.show_formation(shape_formations[shape] as TowerFormationData)
		await _settle()
		if not captured_block_placement:
			_capture("formation_block_placement")
			captured_block_placement = true
		_capture("formation_placement_%s" % String(shape).to_lower())
	block_game.queue_free()
	await get_tree().process_frame

	var game := (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as GameController
	game.testing_mode = true
	await _add_running_block_game(game)
	_install_formation(game, &"balanced")
	_install_formation(game, &"guidance")
	_install_formation(game, &"precision")
	_install_formation(game, &"barrage")
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"global_upgrade", "전역 전투 시너지", "모든 타워 피해와 공격속도 증가", &"global"))
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"global_upgrade", "전역 전투 시너지", "모든 타워 피해와 공격속도 증가", &"global"))
	game.hud.warning_label.visible = false
	for lane in game.battlefield.lane_count:
		var spawn_position := game.battlefield.get_spawn_position(lane) - Vector2(170.0 + lane * 85.0, 0.0)
		var enemy := game._spawn_enemy(DataRegistry.enemies[lane % 3], spawn_position, lane, 1.3, 1.0)
		enemy.set_process(false)
		enemy.set_physics_process(false)
	game.target_cursor.set_destination(game.battlefield.get_battle_rect().get_center() + Vector2(150.0, 0.0))
	game.hud.set_bottom_info_visible(true)
	await _settle()
	_capture("gameplay_hud")
	for artifact_id in [&"war_banner", &"green_gear", &"blue_lens", &"crown_shard", &"silver_spur", &"toxin_ampoule"]:
		game.loadout.artifact_inventory.equip(artifact_id)
	game.hud.update_artifacts(game.loadout.get_artifact_presentations())
	await _settle()
	_capture("artifact_hud")
	game.hud._toggle_artifact_details()
	await _settle()
	_capture("artifact_hud_details")
	game.hud._toggle_artifact_details()
	game.hud.set_bottom_info_visible(false)
	await _settle()
	_capture("gameplay_hud_compact")
	game.hud.set_bottom_info_visible(true)
	await _settle()
	game.core.set_process(false)
	game.core.set_physics_process(false)
	for core_data in DataRegistry.cores:
		game.core.configure(core_data)
		var skill_candidate := ConceptService.get_election_campaign().candidate_for_core(core_data.id)
		if skill_candidate != null:
			var skill_retainer := ConceptService.get_election_campaign().retainer(skill_candidate.default_retainer_id)
			game.hud.set_run_identity(skill_candidate.full_name, skill_retainer.full_name if skill_retainer != null else "", 0, "")
		game.core.skill_cast_total = core_data.skill_cast_seconds
		game.core.skill_cast_remaining = core_data.skill_cast_seconds * 0.58
		game.hud.update_skill_cast(game.core.skill_cast_remaining, game.core.skill_cast_total)
		game._on_core_skill_cast_started(core_data, core_data.skill_cast_seconds)
		await get_tree().process_frame
		_capture("candidate_skill_cast_%s" % String(skill_candidate.id if skill_candidate != null else core_data.id))
		for effect in game.effect_container.get_children():
			effect.queue_free()
		game.screen_effects.reset_effects()
		await get_tree().process_frame
	game.core.configure(DataRegistry.get_core(GameSession.selected_core_id))
	game.hud.skill_casting = false
	game.hud.update_skill_charge(0.0, game.core.data.skill_charge_seconds)
	game.core.set_process(true)
	game.core.set_physics_process(true)
	await get_tree().process_frame
	game.hud.set_bottom_info_visible(false)
	game._set_range_overlay(true)
	game.range_overlay.inspect_at(game.core.global_position, true)
	await _settle()
	_capture("unit_info_core")
	var range_probe := _find_first_normal_tower_cell(game.loadout)
	if not range_probe.is_empty():
		var range_column := range_probe.column as TowerColumn
		game.range_overlay.inspect_at(range_column.get_attack_origin(int(range_probe.row)), true)
	game.hud.warning_label.visible = false
	await _settle()
	_capture("unit_info_tower")
	_capture("attack_ranges")
	game._set_range_overlay(false)
	game.pause_menu.show_menu()
	await _settle()
	_capture("pause_menu")
	(game.pause_menu.get_node("%OptionsButton") as Button).pressed.emit()
	await _settle()
	_capture("pause_options")
	game.pause_menu.hide_menu()
	var effect_center := game.battlefield.get_battle_rect().get_center()
	game._show_burst_effect(effect_center, Color("65e0c0"), 145.0, 0.9)
	game._show_impact_effect(effect_center + Vector2(260.0, -110.0), Color("ff9f66"), 88.0, 0.65)
	game._show_effect(effect_center - Vector2(310.0, 120.0), effect_center + Vector2(120.0, 120.0), Color("83a4ff"), 0.0, 0.7)
	game.screen_effects.shake(0.72, 0.35)
	game.screen_effects.flash(Color("65e0c0"), 0.1, 0.25)
	await get_tree().process_frame
	_capture("effects_showcase")
	game.screen_effects.reset_effects()
	for effect in game.effect_container.get_children():
		effect.queue_free()
	await get_tree().process_frame
	var pattern_rect := game.battlefield.get_battle_rect()
	game._show_pattern_effect(pattern_rect.position + pattern_rect.size * Vector2(0.28, 0.28), Color("ff9f66"), 78.0, &"zone", 0.8, 1.2)
	game._show_pattern_effect(pattern_rect.position + pattern_rect.size * Vector2(0.52, 0.28), Color("ff657d"), 50.0, &"slash", 0.9, 1.0)
	game._show_pattern_effect(pattern_rect.position + pattern_rect.size * Vector2(0.73, 0.28), Color("d781ff"), 40.0, &"sigil", 0.8, 1.2)
	game._show_pattern_effect(pattern_rect.position + pattern_rect.size * Vector2(0.3, 0.72), Color("f4d56b"), 72.0, &"orbit", 0.9, 1.0)
	game._show_chain_effect([
		pattern_rect.position + pattern_rect.size * Vector2(0.5, 0.72),
		pattern_rect.position + pattern_rect.size * Vector2(0.61, 0.64),
		pattern_rect.position + pattern_rect.size * Vector2(0.72, 0.76),
		pattern_rect.position + pattern_rect.size * Vector2(0.84, 0.66),
	], Color("fff079"), 0.85)
	await get_tree().process_frame
	await get_tree().process_frame
	_capture("tower_attack_patterns")
	for effect in game.effect_container.get_children():
		effect.queue_free()
	await get_tree().process_frame
	_show_election_projectile_showcase(game, pattern_rect)
	await _settle()
	_capture("election_projectile_showcase")
	for projectile in get_tree().get_nodes_in_group(&"projectiles"):
		projectile.queue_free()
	await get_tree().process_frame
	for column in game.loadout.columns:
		column.set_process(false)
		column.set_physics_process(false)
		for row_index in game.battlefield.lane_count:
			if column.get_tower_data(row_index) != null:
				column.confirm_attack(row_index)
	await get_tree().process_frame
	_capture("tower_motion_showcase")
	var abyss_column := TowerColumn.new()
	game.add_child(abyss_column)
	abyss_column.set_process(false)
	abyss_column.set_physics_process(false)
	var abyss_showcase_center := game.battlefield.get_battle_rect().get_center()
	abyss_column.setup(2, abyss_showcase_center.x - 70.0, game.battlefield)
	abyss_column.set_shared_progress({&"slow": 7}, {&"slow": &"slow_power"})
	abyss_column.equip_formation_cells(DataRegistry.get_formation(&"cryo_net"), [{"cell": Vector2i(2, 0), "tower_id": &"slow"}], &"abyss_showcase")
	var abyss_showcase_origin := abyss_column.get_attack_origin(0)
	var abyss_showcase_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), abyss_showcase_origin + Vector2(96.0, 0.0), 0, 20.0, 1.0)
	abyss_showcase_target.set_process(false)
	abyss_showcase_target.set_physics_process(false)
	for sacrifice_index in 4:
		game._register_abyss_sacrifice_for_column(abyss_column, 0, abyss_showcase_origin)
	var abyss_showcase_summon := game.summon_container.get_child(game.summon_container.get_child_count() - 1) as AbyssSummon
	abyss_showcase_summon.set_process(false)
	abyss_showcase_summon.set_physics_process(false)
	abyss_showcase_summon._physics_process(0.24)
	await get_tree().process_frame
	_capture("abyss_summon_active")
	abyss_showcase_summon.force_expire()
	abyss_showcase_target.active = false
	abyss_showcase_target.queue_free()
	abyss_column.queue_free()
	await get_tree().process_frame

	var choices := game.loadout.generate_upgrade_choices()
	game.level_up_panel.show_choices(choices, 2, 3, 3)
	await _settle()
	_capture("level_up_choices")
	var movement_upgrade_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"cursor_level", "심복 Lv.5", game.loadout._growth_track_level_description(game.loadout.cursor_state, true, 5), game.loadout.cursor_state.id),
		UpgradeData.new().configure(&"global_upgrade", "전역 전투 시너지", "전체 타워 피해 ×1.14 → ×1.21\n전체 타워 공격속도 ×1.10 → ×1.15", &"global"),
		UpgradeData.new().configure(&"tower_type_level", "속사 타워 전체 Lv.3", game.loadout._tower_level_description(&"rapid", 3), &"rapid"),
	]
	game.level_up_panel.show_choices(movement_upgrade_choices, 5)
	await _settle()
	_capture("cursor_movement_upgrade")
	var status_milestone_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"status_upgrade", "독 Lv.4 특화", game.loadout._status_upgrade_description(&"poison", 4), &"poison"),
		UpgradeData.new().configure(&"status_upgrade", "출혈 Lv.7 완성", game.loadout._status_upgrade_description(&"bleed", 7), &"bleed"),
		UpgradeData.new().configure(&"status_upgrade", "감전 Lv.4 특화", game.loadout._status_upgrade_description(&"shock", 4), &"shock"),
	]
	game.level_up_panel.show_choices(status_milestone_choices, 12)
	await _settle()
	_capture("status_milestone_choices")
	var overgrowth_card := UpgradeData.new().configure(&"candidate_overgrowth", "후보 초과성장 · 고유 기술", "완성된 후보의 고유 기술 피해를 소폭 반복 강화합니다.\n반복 2회 → 3회 · 5.0% → 7.5%", &"candidate_skill")
	overgrowth_card.offer_metadata = {"family": "overgrowth", "target_group": "candidate", "stat_key": "skill", "stack": 3}
	var overgrowth_choices: Array[UpgradeData] = [
		overgrowth_card,
		UpgradeData.new().configure(&"status_upgrade", "감전 Lv.5", game.loadout._status_upgrade_description(&"shock", 5), &"shock"),
		UpgradeData.new().configure(&"tower_type_level", "고블린 창병 전체 Lv.5", game.loadout._tower_level_description(&"rapid", 5), &"rapid"),
	]
	game.level_up_panel.show_choices(overgrowth_choices, 15)
	await _settle()
	_capture("overgrowth_choices")
	var artifact_card := ArtifactOfferService.build_choice(game.loadout.artifact_catalog.find_artifact(&"blood_prism"))
	var artifact_choices: Array[UpgradeData] = [
		artifact_card,
		UpgradeData.new().configure(&"status_upgrade", "화상 Lv.3", game.loadout._status_upgrade_description(&"burn", 3), &"burn"),
		UpgradeData.new().configure(&"tower_type_level", "오크 궁병 전체 Lv.3", game.loadout._tower_level_description(&"pierce", 3), &"pierce"),
	]
	game.level_up_panel.show_choices(artifact_choices, 16, 2, 3)
	await _settle()
	_capture("artifact_choices")
	for artifact_id in [&"war_banner", &"green_gear", &"blue_lens", &"crown_shard", &"silver_spur", &"toxin_ampoule"]:
		game.loadout.artifact_inventory.equip(artifact_id)
	game.level_up_panel.hide_panel()
	game.artifact_resolution_panel.show_resolution(game.loadout.artifact_catalog.find_artifact(&"blood_prism"), game.loadout.get_equipped_artifacts())
	await _settle()
	_capture("artifact_replacement")
	game.artifact_resolution_panel.hide_panel()
	var final_trait_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"candidate_branch", "죽음친화의식", "후보와 친위대의 처형 기준을 대상 등급별로 강화", &"judaginda_death_affinity"),
		UpgradeData.new().configure(&"cursor_level", "심복 Lv.7", "심복 최종 특성 완성\n정예 검술 훈련 · 충돌 취약 부여", &"iron"),
		UpgradeData.new().configure(&"tower_type_level", "고블린 창병 전체 Lv.7", "선택한 분기의 최종 관통·도탄 효과 자동 완성", &"rapid"),
	]
	game.level_up_panel.show_choices(final_trait_choices, 7)
	await _settle()
	_capture("final_trait_choices")
	var rapid_tower := DataRegistry.get_tower(&"rapid")
	var specialization_parent: Array[UpgradeData] = [
		UpgradeData.new().configure(&"tower_specialization_entry", "%s Lv.4 특화" % rapid_tower.display_name, "세 가지 전용 특화 중 하나를 선택합니다", &"rapid"),
		UpgradeData.new().configure(&"global_upgrade", "전역 전투 시너지", "모든 타워 피해와 공격속도 증가", &"global"),
		UpgradeData.new().configure(&"status_upgrade", "화상 Lv.1", "전체 타워 공격에 화상을 부여", &"burn"),
	]
	game.loadout.tower_type_levels[&"rapid"] = 3
	var specialization_choices := game.loadout.get_specialization_subchoices(specialization_parent[0])
	game.level_up_panel.show_choices(specialization_parent, 4)
	game.level_up_panel.show_subchoices(specialization_choices, "%s Lv.4 특화" % rapid_tower.display_name, 4)
	await _settle()
	_capture("specialization_choices")
	for specialization_tower_id: StringName in [&"pierce", &"execute", &"slow", &"mark", &"area", &"knockback", &"chain"]:
		var specialization_tower := DataRegistry.get_tower(specialization_tower_id)
		var specialization_entry := UpgradeData.new().configure(
			&"tower_specialization_entry",
			"%s Lv.4 특화" % specialization_tower.display_name,
			"세 가지 전용 특화 중 하나를 선택합니다",
			specialization_tower_id
		)
		game.loadout.tower_type_levels[specialization_tower_id] = 3
		game.level_up_panel.show_subchoices(
			game.loadout.get_specialization_subchoices(specialization_entry),
			specialization_entry.display_name,
			4
		)
		await _settle()
		_capture("%s_specialization_choices" % String(specialization_tower_id))

	game.level_up_panel.hide_panel()
	var result_board_snapshot := [
		{"placement_id": "guard_emerald", "formation_id": "emerald_guard", "anchor_x": 0, "anchor_y": 0, "vertical_flipped": false, "is_guard": true, "cells": [
			{"x": 0, "y": 0, "tower_id": "emerald_guardian"}, {"x": 0, "y": 1, "tower_id": "rapid"}, {"x": 1, "y": 1, "tower_id": "rapid"},
		]},
		{"placement_id": "formation_1", "formation_id": "mixed", "anchor_x": 2, "anchor_y": 1, "vertical_flipped": true, "is_guard": false, "cells": [
			{"x": 2, "y": 3, "tower_id": "area"}, {"x": 2, "y": 2, "tower_id": "rapid"}, {"x": 2, "y": 1, "tower_id": "knockback"},
		]},
		{"placement_id": "formation_2", "formation_id": "cryo_net", "anchor_x": 4, "anchor_y": 0, "vertical_flipped": false, "is_guard": false, "cells": [
			{"x": 4, "y": 0, "tower_id": "slow"}, {"x": 4, "y": 1, "tower_id": "rubber_golem"},
		]},
	]
	var result_campaign := ConceptService.get_election_campaign()
	var result_plan := CampaignStageResolver.resolve(game.stage_data, DataRegistry.bosses, result_campaign, &"emerald", &"iron", 1847)
	var result_service := RunResultService.new()
	game.hud.show_result({
		"victory": true,
		"stage_name": "10분 공식 유세장",
		"stage_duration_seconds": 600.0,
		"challenge_level": 3,
		"challenge_experience_multiplier": 1.06,
		"elapsed": 600.0,
		"level": 18,
		"kills": 428,
		"boss_kills": 4,
		"boss_kill_ids": ["boss_5", "boss_10", "boss_15", "final_boss"],
		"boss_timeline": result_service._build_boss_timeline(result_plan, ["boss_5", "boss_10", "boss_15", "final_boss", "judgment_bell"]),
		"candidate_id": "partason",
		"candidate_name": "파르태손 8세",
		"candidate_support_earned": 103,
		"candidate_support_total": 1000,
		"candidate_support_required": 1000,
		"candidate_newly_elected": true,
		"funds_earned": 414,
		"defense_funds_total": 1240,
		"funds_breakdown": {
			"progress_funds": 180,
			"boss_funds": 125,
			"victory_funds": 75,
			"challenge_multiplier": 1.09,
			"first_clear_funds": 0,
		},
		"experience": 2450.0,
		"core_health": 126.0,
		"core": "파르태손 VIII 마아앙",
		"cursor": "마장군 칸다 도르기어크",
		"retainer_name": "칸다",
		"retainer_contribution": {"role": "근접·상태", "damage": 5210.0, "control_applications": 14, "collection_experience": 386.0, "executions": 0, "unique_uses": 11},
		"outcome_summary": {
			"growth": {"candidate_slots": 3, "guard_stage": 3, "retainer_level": 7, "artifact_count": 4},
			"formation": {"regular_formations": 2, "regular_units": 5, "guard_formations": 1, "guard_units": 3, "guard_damage": 7165.0, "guard_kills": 96, "guard_control_applications": 0},
			"status": {"active_status_count": 3, "total_applications": 184, "total_damage": 4380.0, "top_status_id": "shock", "top_applications": 96, "top_damage": 2860.0},
			"artifacts": {"offers": 5, "acquisitions": 4, "discards": 1, "replacements": 0, "final_inventory": {"count": 4, "artifact_ids": ["war_banner", "green_gear", "blue_lens", "crown_shard"]}, "effect_contribution": {"estimated_output_delta": 1840.0}},
			"spawn": {"base_count": 287, "bonus_count": 27, "bonus_experience_ratio": 0.0713, "packets": [{"packet_id": "breakthrough", "display_name": "돌파대", "count": 105}, {"packet_id": "escort", "display_name": "호위대", "count": 43}, {"packet_id": "siege", "display_name": "공성대", "count": 24}]},
		},
		"top_tower": "고블린 창병",
		"unlocked": "주그디에드",
		"build": game.loadout.get_build_summary(),
		"formation_board": result_board_snapshot,
		"formation_board_width": 6,
		"formation_board_height": 4,
	})
	await get_tree().create_timer(1.35).timeout
	_capture("result_screen")
	game.hud.result_overlay.modal_shell.get_body_scroll().scroll_vertical = int(game.hud.result_overlay.modal_shell.get_body_scroll().get_v_scroll_bar().max_value)
	await _settle()
	_capture("result_screen_details")
	game.hud.show_result({
		"victory": false,
		"stage_name": "10분 공식 유세장",
		"stage_duration_seconds": 600.0,
		"challenge_level": 2,
		"challenge_experience_multiplier": 1.04,
		"elapsed": 372.0,
		"level": 12,
		"kills": 231,
		"boss_kills": 1,
		"boss_kill_ids": ["boss_5"],
		"boss_timeline": result_service._build_boss_timeline(result_plan, ["boss_5"]),
		"candidate_id": "partason",
		"candidate_name": "파르태손 8세",
		"candidate_support_earned": 43,
		"candidate_support_total": 622,
		"candidate_support_required": 1000,
		"candidate_newly_elected": false,
		"funds_earned": 113,
		"defense_funds_total": 964,
		"funds_breakdown": {
			"progress_funds": 92,
			"boss_funds": 15,
			"victory_funds": 0,
			"challenge_multiplier": 1.06,
			"first_clear_funds": 0,
		},
		"experience": 1380.0,
		"core_health": 0.0,
		"core": "파르태손 VIII 마아앙",
		"cursor": "마장군 칸다 도르기어크",
		"retainer_name": "칸다",
		"retainer_contribution": {"role": "근접·상태", "damage": 2380.0, "control_applications": 7, "collection_experience": 204.0, "executions": 0, "unique_uses": 5},
		"outcome_summary": {
			"growth": {"candidate_slots": 2, "guard_stage": 1, "retainer_level": 5, "artifact_count": 2},
			"formation": {"regular_formations": 2, "regular_units": 5, "guard_formations": 1, "guard_units": 3, "guard_damage": 2980.0, "guard_kills": 34, "guard_control_applications": 0},
			"status": {"active_status_count": 2, "total_applications": 71, "total_damage": 1640.0, "top_status_id": "poison", "top_applications": 42, "top_damage": 1210.0},
			"artifacts": {"offers": 4, "acquisitions": 3, "discards": 1, "replacements": 1, "final_inventory": {"count": 2, "artifact_ids": ["war_banner", "blood_prism"]}, "effect_contribution": {"estimated_output_delta": 720.0}},
			"spawn": {"base_count": 204, "bonus_count": 18, "bonus_experience_ratio": 0.083, "packets": [{"packet_id": "breakthrough", "display_name": "돌파대", "count": 82}, {"packet_id": "escort", "display_name": "호위대", "count": 19}]},
		},
		"top_tower": "고블린 창병",
		"unlocked": "없음",
		"build": game.loadout.get_build_summary(),
		"formation_board": result_board_snapshot,
		"formation_board_width": 6,
		"formation_board_height": 4,
	})
	await get_tree().create_timer(1.35).timeout
	_capture("result_screen_defeat")
	game.hud.result_panel.visible = false
	game.hud.result_backdrop.visible = false
	game.enemy_spawner.stop()
	game.core.stop()
	game.target_cursor.stop()
	game.target_cursor.visible = false
	game.column_container.visible = false
	for column in game.loadout.columns:
		column.set_process(false)
		column.set_physics_process(false)
	for effect in game.effect_container.get_children():
		effect.queue_free()
	game.screen_effects.reset_effects()
	for node in get_tree().get_nodes_in_group(&"enemies"):
		(node as Enemy).active = false
		node.queue_free()
	await get_tree().process_frame
	var battle_rect := game.battlefield.get_battle_rect()
	for enemy_index in DataRegistry.enemies.size():
		var lane := enemy_index % 4
		var column := enemy_index / 4
		var roster_position := Vector2(
			battle_rect.position.x + battle_rect.size.x * (0.34 + column * 0.16),
			game.battlefield.get_lane_y(lane)
		)
		var roster_enemy := game._spawn_enemy(DataRegistry.enemies[enemy_index], roster_position, lane, 1.0, 1.0)
		roster_enemy.set_process(false)
		roster_enemy.set_physics_process(false)
	await _settle()
	_capture("enemy_roster")
	for node in get_tree().get_nodes_in_group(&"enemies"):
		(node as Enemy).active = false
		node.queue_free()
	await get_tree().process_frame
	for boss_index in DataRegistry.bosses.size():
		var boss_lane := boss_index
		var boss_position := Vector2(
			battle_rect.position.x + battle_rect.size.x * (0.42 + boss_index * 0.12),
			game.battlefield.get_lane_y(boss_lane)
		)
		var roster_boss := game._spawn_enemy(DataRegistry.bosses[boss_index], boss_position, boss_lane, 1.0, 1.0)
		roster_boss.set_process(false)
		roster_boss.set_physics_process(false)
	game.hud.warning_label.visible = false
	game.hud.hide_boss()
	for effect in game.effect_container.get_children():
		effect.queue_free()
	game.screen_effects.reset_effects()
	await _settle()
	_capture("boss_roster")
	for node in get_tree().get_nodes_in_group(&"enemies"):
		(node as Enemy).active = false
		node.queue_free()
	await get_tree().process_frame
	game.column_container.visible = true
	await _show_tower_roster(game)
	await _settle()
	_capture("tower_roster")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)

func _add_running_block_game(game: GameController) -> void:
	add_child(game)
	await _settle()
	if game.game_phase == GameTypes.GamePhase.PREPARATION and game.preparation_panel.visible:
		game.preparation_panel._confirm()
		await _settle()
	if not game.block_board_active or game.game_phase != GameTypes.GamePhase.RUNNING:
		push_error("UI snapshot block-board setup failed")

func _install_formation(game: GameController, formation_id: StringName) -> void:
	var formation := DataRegistry.get_formation(formation_id)
	var placements := game.loadout.get_valid_board_placements(formation)
	if placements.is_empty():
		push_error("UI snapshot formation has no valid placement: %s" % String(formation_id))
		return
	var placement := placements[0]
	var owner_id := game.loadout.place_formation_block(
		formation,
		placement.anchor as Vector2i,
		bool(placement.vertical_flipped)
	)
	if owner_id == &"":
		push_error("UI snapshot formation placement failed: %s" % String(formation_id))

func _find_first_tower_cell(loadout: LoadoutManager) -> Dictionary:
	for column in loadout.columns:
		for row_index in column.row_towers.size():
			if column.get_tower_data(row_index) != null:
				return {"column": column, "row": row_index}
	return {}

func _find_first_normal_tower_cell(loadout: LoadoutManager) -> Dictionary:
	for column in loadout.columns:
		if column.is_guard_formation:
			continue
		for row_index in column.row_towers.size():
			var tower := column.get_tower_data(row_index)
			if tower != null and tower.id in DataRegistry.NORMAL_DEFENDER_IDS:
				return {"column": column, "row": row_index}
	return _find_first_tower_cell(loadout)

func _show_election_projectile_showcase(game: GameController, battle_rect: Rect2) -> void:
	var tower_ids: Array[StringName] = [&"rapid", &"area", &"emerald_guardian", &"obsidian_inquisitor"]
	for index in tower_ids.size():
		var tower := DataRegistry.get_tower(tower_ids[index])
		var profile := game._tower_projectile_profile(tower, 0)
		var position := battle_rect.position + battle_rect.size * Vector2(0.34 + index * 0.15, 0.56)
		var projectile := game._create_tower_projectile_node()
		projectile.setup(
			position,
			position + Vector2(180.0, 0.0),
			profile.texture as Texture2D,
			float(profile.speed),
			tower.color,
			float(profile.length) * 1.5,
			{"behavior": tower.behavior, "volley_index": 1}
		)
		projectile.set_process(false)
		projectile.set_physics_process(false)

func _show_tower_roster(game: GameController) -> void:
	var placement_ids: Array[StringName] = []
	for placement in game.loadout.get_board_snapshot():
		placement_ids.append(StringName(placement.get("placement_id", "")))
	for placement_id in placement_ids:
		game.loadout.remove_formation_block(placement_id)
	await get_tree().process_frame
	for column_index in 4:
		var tower_column := TowerColumn.new()
		game.column_container.add_child(tower_column)
		tower_column.setup(column_index + 1, game.battlefield.get_column_x(column_index + 1), game.battlefield)
		tower_column.set_shared_progress(game.loadout.tower_type_levels, game.loadout.tower_branch_ids)
		var entries: Array[Dictionary] = []
		for row_index in game.battlefield.lane_count:
			var tower_index := column_index * game.battlefield.lane_count + row_index
			if tower_index < DataRegistry.towers.size():
				entries.append({
					"cell": Vector2i(column_index + 1, row_index),
					"tower_id": DataRegistry.towers[tower_index].id,
				})
		if not tower_column.equip_formation_cells(DataRegistry.formations[0], entries, StringName("tower_roster_%d" % column_index)):
			push_error("UI snapshot tower roster slice setup failed: %d" % column_index)
		tower_column.clear_disable()
		tower_column.set_process(false)
		tower_column.set_physics_process(false)
		game.loadout.columns.append(tower_column)

func _settle() -> void:
	for node in get_tree().get_nodes_in_group(&"level_up_panels"):
		var level_up_panel := node as LevelUpPanel
		if level_up_panel != null and level_up_panel.visible:
			level_up_panel.complete_card_reveal()
	for _frame in 8:
		await get_tree().process_frame

func _representative_shape_formations(loadout: LoadoutManager) -> Dictionary:
	var result := {}
	for formation in DataRegistry.formations:
		if formation == null or formation.is_unique() or formation.cells.size() != 4:
			continue
		if formation.shape_class in result or loadout.get_valid_board_placements(formation).is_empty():
			continue
		result[formation.shape_class] = formation
	return result

func _shape_audit_choice(loadout: LoadoutManager, formation: TowerFormationData) -> UpgradeData:
	var valid_positions := loadout.get_valid_board_placements(formation).size()
	var choice := UpgradeData.new().configure(
		&"new_formation",
		formation.display_name,
		"형태 검증 · %d칸 · %s / %d병종\n배치 %s · 현재 %d곳 · 편성점수 %d\n%s · %s" % [
			formation.cells.size(),
			formation.get_shape_display_name(),
			formation.get_distinct_tower_count(),
			formation.get_placement_difficulty_display_name(),
			valid_positions,
			formation.formation_score,
			", ".join(formation.role_tags),
			formation.description,
		],
		formation.id
	)
	choice.offer_metadata = {
		"shape_class": formation.shape_class,
		"distinct_tower_count": formation.get_distinct_tower_count(),
		"valid_position_count": valid_positions,
	}
	return choice

func _capture(file_name: String) -> void:
	for node in get_tree().get_nodes_in_group(&"level_up_panels"):
		var level_up_panel := node as LevelUpPanel
		if level_up_panel != null and level_up_panel.visible:
			level_up_panel.complete_card_reveal()
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [OUTPUT_DIR, file_name])
