extends Node

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _create_test_column(game: GameController, formation_id: StringName, row_recipe: Array, column_index: int = 0) -> TowerColumn:
	var column := TowerColumn.new()
	game.loadout.add_child(column)
	column.set_process(false)
	column.set_physics_process(false)
	column.setup(column_index, 0.0, game.battlefield)
	column.set_shared_progress({}, {})
	var entries: Array[Dictionary] = []
	for row_index in row_recipe.size():
		var tower_id := StringName(row_recipe[row_index])
		if tower_id != &"":
			entries.append({"cell": Vector2i(column_index, row_index), "tower_id": tower_id})
	column.equip_formation_cells(DataRegistry.get_formation(formation_id), entries, StringName("contract_%s_%d" % [formation_id, column_index]))
	return column

func _run() -> void:
	await get_tree().process_frame
	AudioManager.muted = true
	for contract_failure in AssetCoverageContractTest.run():
		failures.append(contract_failure)
	for contract_failure in AudioPresentationContractTest.run():
		failures.append(contract_failure)
	for contract_failure in CombatMotionProfileContractTest.run():
		failures.append(contract_failure)
	for contract_failure in RetainerMotionProfileContractTest.run():
		failures.append(contract_failure)
	for contract_failure in CombatCharacterArtContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019CharacterStyleRefreshContractTest.run():
		failures.append(contract_failure)
	for contract_failure in ElectionCampaignContractTest.run():
		failures.append(contract_failure)
	for contract_failure in StageRuntimeBossPlanContractTest.run():
		failures.append(contract_failure)
	for contract_failure in ElectionCombatMechanicsContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in NecromancyReactivationContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in ComboVanguardContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in CandidateProgressionContractTest.run():
		failures.append(contract_failure)
	for contract_failure in CombatModifierResolverContractTest.run():
		failures.append(contract_failure)
	for contract_failure in SummonServiceContractTest.run():
		failures.append(contract_failure)
	for contract_failure in PerformanceBudgetContractTest.run():
		failures.append(contract_failure)
	for contract_failure in FormationBoardContractTest.run():
		failures.append(contract_failure)
	for contract_failure in FormationBoardContractTest.run_runtime(self):
		failures.append(contract_failure)
	for contract_failure in BossControlResistanceContractTest.run():
		failures.append(contract_failure)
	for contract_failure in ModularizationContractTest.run():
		failures.append(contract_failure)
	for contract_failure in FormationOfferBuilderContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V013MigrationContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V014FormationCatalogContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V015EnemySpawnFoundationContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V015FactionEnemyContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in V015FactionPreludeCompositionContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V016EnemyObservabilityContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V016BalanceAuditPolicyContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V016BalanceConvergenceMetricsContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M0BaselineContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M1MetaUnlockContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M2TutorialContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M3HubCodexContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M4DefenseStatContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in V019M5OvergrowthContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M6ArtifactFoundationContractTest.run():
		failures.append(contract_failure)
	for contract_failure in V019M7ArtifactOfferUiContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in V019M8ArtifactMetricsAuditContractTest.run():
		failures.append(contract_failure)
	for contract_failure in UiUxFoundationContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in UiUxM2ChoiceCardContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in UiUxM3CombatHudContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in UiUxM4UnitInfoContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in UiUxM5MetaPagesContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in UiUxM6ModalFlowsContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in UiUxM7ResponsiveAccessibilityContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in AudiencePresentationContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in RetainerProgressionContractTest.run():
		failures.append(contract_failure)
	for contract_failure in CommonStatusV013ContractTest.run():
		failures.append(contract_failure)
	for contract_failure in EnemyStatusVisualContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in EnemyRuntimeStateContractTest.run(self):
		failures.append(contract_failure)
	for contract_failure in SpawnDirectorContractTest.run():
		failures.append(contract_failure)
	for contract_failure in SpawnCompositionContractTest.run():
		failures.append(contract_failure)
	for contract_failure in RunOutcomeSummaryContractTest.run():
		failures.append(contract_failure)
	for contract_failure in FirstFiveRunEconomyContractTest.run():
		failures.append(contract_failure)
	for contract_failure in BalanceAuditSummaryContractTest.run():
		failures.append(contract_failure)
	for contract_failure in ImplementationFreezeContractTest.run():
		failures.append(contract_failure)
	MetaProgressionService.set_testing_content_lock_bypass(true)
	for contract_failure in CatalogGrowthRuntimeContractTest.run(self):
		failures.append(contract_failure)
	var menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var title_page := menu.get_node("%TitlePage") as Control
	var game_setup_page := menu.get_node("%GameSetupPage") as Control
	var shop_page := menu.get_node("%ShopPage") as Control
	var achievements_page := menu.get_node("%AchievementsPage") as Control
	var codex_page := menu.get_node("%CodexPage") as Control
	_check(title_page.visible and not game_setup_page.visible and not shop_page.visible and not achievements_page.visible and not codex_page.visible, "the application must open on the title hub")
	(menu.get_node("%GameMenuButton") as Button).pressed.emit()
	await get_tree().process_frame
	_check(game_setup_page.visible and not title_page.visible, "the title hub must open the game setup page")
	_check((menu.get_node("%CoreOption") as OptionButton).item_count == DataRegistry.cores.size(), "the game setup page must retain the core selector")
	_check((menu.get_node("%CursorOption") as OptionButton).item_count == DataRegistry.cursors.size(), "the game setup page must retain the target cursor selector")
	var cursor_option := menu.get_node("%CursorOption") as OptionButton
	_check(cursor_option.size.x < 700.0 and cursor_option.size.y < 100.0, "high-resolution cursor art must not expand the setup selector over the screen")
	(menu.get_node("%GameBackButton") as Button).pressed.emit()
	(menu.get_node("%ShopMenuButton") as Button).pressed.emit()
	await get_tree().process_frame
	_check(shop_page.visible and (menu.get_node("%ShopProductList") as VBoxContainer).get_child_count() == 5, "the title hub shop must list the five active tower products with their current state")
	(menu.get_node("%ShopBackButton") as Button).pressed.emit()
	(menu.get_node("%AchievementMenuButton") as Button).pressed.emit()
	await get_tree().process_frame
	_check(achievements_page.visible and not title_page.visible and menu.achievement_browser.get_visible_entry_count() == MetaProgressionService.get_achievements().size(), "the title hub must open every data-backed achievement with progress and rewards")
	menu.achievement_browser._set_filter(&"status")
	_check(menu.achievement_browser.get_visible_entry_count() == 4, "achievement category filters must expose the four status-growth achievements")
	menu.achievement_browser._set_filter(&"all")
	(menu.get_node("%AchievementBackButton") as Button).pressed.emit()
	(menu.get_node("%CodexMenuButton") as Button).pressed.emit()
	await get_tree().process_frame
	menu.codex_browser.show_category(&"tower")
	_check(codex_page.visible and not title_page.visible and menu.codex_browser.get_entry_count() == 15 and not menu.codex_browser.get_selected_entry().is_empty(), "the title hub codex must browse nine regular and six candidate-exclusive guard unit types and select a detailed entry")
	menu.codex_browser.show_category(&"formation")
	_check(menu.codex_browser.get_entry_count() == 54, "the codex must include 49 regular and five core-exclusive formation recipes")
	menu.codex_browser.show_category(&"enemy")
	_check(menu.codex_browser.get_entry_count() == 17, "the codex must include seven common enemies, five faction representatives, and five candidate bosses")
	(menu.get_node("%CodexBackButton") as Button).pressed.emit()
	await get_tree().process_frame
	_check(title_page.visible, "every secondary title page must provide a return path")
	menu.queue_free()
	await get_tree().process_frame

	var packed := load("res://scenes/game/game.tscn") as PackedScene

	var game := packed.instantiate() as GameController
	game.testing_mode = true
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	if game.game_phase == GameTypes.GamePhase.PREPARATION and game.preparation_panel.visible:
		game.preparation_panel._confirm()
		await get_tree().process_frame
	_check(game.experience_rewards != null and game.experience_rewards.is_configured(), "the experience reward module must be configured with its runtime dependencies")
	_check(game.block_board_active and game.game_phase == GameTypes.GamePhase.RUNNING, "the main gameplay smoke scenario must use the current block board and enter combat after guard preparation")
	_check(game.loadout.get_board_snapshot().size() == 1 and bool(game.loadout.get_board_snapshot()[0].is_guard), "the main gameplay smoke scenario must begin with exactly one mandatory guard placement")
	_check(game.core.data.id == GameSession.selected_core_id, "selected core must be applied")
	_check(game.target_cursor.data.id == GameSession.selected_cursor_id, "selected cursor must be applied")
	_check(game.target_cursor.data.texture != null, "the active target cursor must expose its configured image")
	var unique_cursor_movement_speeds: Dictionary = {}
	for movement_cursor in DataRegistry.cursors:
		unique_cursor_movement_speeds[movement_cursor.movement_speed] = true
	_check(unique_cursor_movement_speeds.size() == 5, "all five target cursors must expose distinct movement speeds")
	_check(DataRegistry.get_cursor(&"silver").movement_speed > DataRegistry.get_cursor(&"iron").movement_speed and DataRegistry.get_cursor(&"iron").movement_speed > DataRegistry.get_cursor(&"gold").movement_speed and DataRegistry.get_cursor(&"gold").movement_speed > DataRegistry.get_cursor(&"platinum").movement_speed, "target cursor mobility must follow the fast silver, balanced iron, deliberate gold, and heavy platinum identities")
	var expected_cursor_effects := {
		&"iron": &"cursor_iron",
		&"silver": &"cursor_silver",
		&"gold": &"cursor_gold",
		&"platinum": &"cursor_platinum",
		&"vanguard": &"cursor_vanguard",
	}
	for cursor_data in DataRegistry.cursors:
		game._show_cursor_attack_effect(game.target_cursor.global_position, cursor_data, cursor_data.attack_radius, null)
		_check(get_tree().get_nodes_in_group(&"combat_effects").any(func(effect: CombatEffect) -> bool: return effect.effect_style == expected_cursor_effects[cursor_data.id]), "each target cursor must route to its own attack presentation: %s" % cursor_data.id)
	for effect in get_tree().get_nodes_in_group(&"combat_effects"):
		effect.queue_free()
	await get_tree().process_frame
	GameSession.selected_challenge_level = 10
	var challenge_enemy_position := game.battlefield.get_free_spawn_position(0.82)
	var challenge_enemy := game._spawn_enemy(DataRegistry.enemies[0], challenge_enemy_position, game.battlefield.world_to_lane(challenge_enemy_position), 1.0, 1.0)
	challenge_enemy.set_process(false)
	challenge_enemy.set_physics_process(false)
	_check(is_equal_approx(challenge_enemy.current_health, challenge_enemy.data.max_health * 2.2) and is_equal_approx(challenge_enemy.speed_multiplier, 1.15), "challenge health and movement multipliers must apply to every enemy created by the controller")
	_check(is_equal_approx(challenge_enemy.challenge_experience_multiplier, 1.2) and is_equal_approx(challenge_enemy.runtime_status_resistance, minf(challenge_enemy.data.status_resistance + 0.15, 0.95)), "challenge experience and status-resistance modifiers must be attached to spawned enemies")
	challenge_enemy.active = false
	challenge_enemy.queue_free()
	GameSession.selected_challenge_level = 0
	var breach_boss_position := game.battlefield.get_free_spawn_position(0.18)
	var breach_boss := game._spawn_enemy(DataRegistry.bosses[0], breach_boss_position, game.battlefield.world_to_lane(breach_boss_position), 1.0, 1.0)
	breach_boss.set_process(false)
	breach_boss.set_physics_process(false)
	breach_boss.position = breach_boss.target_position + Vector2(10.0, 140.0)
	var breach_start_distance := breach_boss.position.distance_to(breach_boss.target_position)
	var breach_health_before := game.core.current_health
	breach_boss._physics_process(0.016)
	_check(breach_boss.active and breach_boss in game.active_bosses and breach_boss.position.distance_to(breach_boss.target_position) > breach_start_distance, "a boss reaching the core from any angle must remain alive and be forced radially back into the battlefield")
	_check(breach_health_before - game.core.current_health >= game.core.max_health * 0.14, "a tier-one boss breach must deal its 15% maximum-health-scaled low-floor penalty")
	game.core.heal(game.core.max_health)
	game._unregister_boss(breach_boss)
	breach_boss.active = false
	breach_boss.queue_free()
	await get_tree().process_frame
	game.screen_effects.reset_effects()
	game.screen_effects.shake_request_count = 0
	game.screen_effects.flash_request_count = 0
	var core_health_before_feedback := game.core.current_health
	game.core.take_damage(1.0)
	_check(game.core.damage_flash > 0.9 and game.core.action_pulse > 0.0, "core damage must trigger local flash and pulse feedback")
	_check(game.hud.health_label.scale.x > 1.0, "core damage must punch the HUD health readout")
	game.core.heal(core_health_before_feedback - game.core.current_health)
	_check(not game.pause_menu.visible and not game.pause_menu_open, "the pause menu must start hidden")
	var pause_button := game.hud.pause_button
	_check(pause_button.custom_minimum_size.x >= 48.0 and not pause_button.disabled, "the mobile HUD must expose a touch-sized pause button")
	pause_button.pressed.emit()
	_check(get_tree().paused and game.pause_menu.visible and game.game_phase == GameTypes.GamePhase.PAUSED, "the HUD pause button must pause combat without requiring a keyboard")
	(game.pause_menu.get_node("%ContinueButton") as Button).pressed.emit()
	_check(not get_tree().paused and game.game_phase == GameTypes.GamePhase.RUNNING, "the touch pause flow must resume the previous combat phase")
	game.hud.set_touch_control_hint(true)
	_check(game.hud.instruction_label.text.contains("상단 버튼") and game.hud.instruction_label.text.contains("일시정지"), "touch input hints must describe the on-screen combat controls")
	game.hud.set_touch_control_hint(false)
	_check(game.hud.instruction_label.text.contains("ESC") and game.hud.instruction_label.text.contains("자동"), "desktop input hints must describe shortcuts and automatic target behavior in the active concept terminology")
	var bottom_info := game.hud.bottom_info
	var bottom_info_toggle := game.hud.bottom_info_toggle
	_check(not bottom_info.visible and bottom_info_toggle.is_visible_in_tree() and bottom_info_toggle.custom_minimum_size.x >= 48.0 and bottom_info_toggle.custom_minimum_size.y >= 48.0 and bottom_info_toggle.text.contains("보기"), "the stage HUD must keep its long build drawer folded behind a visible touch-sized control by default")
	bottom_info_toggle.pressed.emit()
	_check(bottom_info.visible and bottom_info_toggle.text.contains("숨기기"), "the bottom description control must restore the build and input explanation on demand")
	bottom_info_toggle.pressed.emit()
	_check(not bottom_info.visible and bottom_info_toggle.text.contains("보기"), "the bottom description control must fold the build and input explanation while remaining available")
	var speed_button := game.hud.speed_button
	_check(is_equal_approx(Engine.time_scale, 1.0) and Engine.physics_ticks_per_second == GameController.BASE_PHYSICS_TICKS_PER_SECOND and speed_button.text.contains("1×"), "each run must start at normal game speed and base physics cadence")
	_check(not game.range_overlay.is_overlay_enabled() and not game.hud.range_button.button_pressed, "attack range overlay must start disabled")
	var range_event := InputEventAction.new()
	range_event.action = &"toggle_attack_ranges"
	range_event.pressed = true
	game._unhandled_input(range_event)
	_check(game.range_overlay.is_overlay_enabled() and game.hud.range_button.button_pressed and game.hud.range_button.text.contains("종료") and not game.target_cursor.movement_input_enabled, "G shortcut must enter contextual range inspection mode and pause target movement input")
	game._unhandled_input(range_event)
	_check(not game.range_overlay.is_overlay_enabled() and not game.hud.range_button.button_pressed and game.target_cursor.movement_input_enabled, "G shortcut must exit range inspection mode and restore target movement")
	speed_button.pressed.emit()
	_check(is_equal_approx(Engine.time_scale, 2.0) and Engine.physics_ticks_per_second == GameController.BASE_PHYSICS_TICKS_PER_SECOND * 2 and speed_button.text.contains("2×"), "the HUD speed button must advance to double speed without enlarging game-time physics steps")
	var speed_event := InputEventAction.new()
	speed_event.action = &"cycle_game_speed"
	speed_event.pressed = true
	game._unhandled_input(speed_event)
	_check(is_equal_approx(Engine.time_scale, 3.0) and Engine.physics_ticks_per_second == GameController.BASE_PHYSICS_TICKS_PER_SECOND * 3 and speed_button.text.contains("3×"), "the speed shortcut must advance to triple speed without enlarging game-time physics steps")
	var pause_event := InputEventAction.new()
	pause_event.action = &"ui_cancel"
	pause_event.pressed = true
	game._unhandled_input(pause_event)
	_check(get_tree().paused and game.pause_menu.visible and game.pause_menu_open, "ESC must pause combat and open the pause menu")
	_check(game.game_phase == GameTypes.GamePhase.PAUSED, "opening the pause menu must expose the PAUSED game phase")
	(game.pause_menu.get_node("%OptionsButton") as Button).pressed.emit()
	_check(game.pause_menu.options_page.visible and get_tree().paused, "the options submenu must remain available while combat is paused")
	var shake_toggle := game.pause_menu.get_node("%ShakeToggle") as CheckButton
	shake_toggle.button_pressed = false
	_check(not GameSession.screen_shake_enabled and not game.screen_effects.shake_enabled, "the pause options must disable screen shake immediately")
	shake_toggle.button_pressed = true
	_check(GameSession.screen_shake_enabled and game.screen_effects.shake_enabled, "the pause options must restore screen shake immediately")
	game.pause_menu._unhandled_input(pause_event)
	_check(game.pause_menu.main_page.visible and get_tree().paused, "ESC in options must return to the main pause page without resuming")
	game.pause_menu._unhandled_input(pause_event)
	_check(not get_tree().paused and not game.pause_menu.visible and not game.pause_menu_open, "continue or ESC must resume combat and remove the pause menu")
	_check(game.game_phase == GameTypes.GamePhase.RUNNING, "resuming from the opening pause must restore the prior game phase")
	_check(is_equal_approx(Engine.time_scale, 3.0), "resuming from pause must preserve the selected combat speed")
	game._unhandled_input(speed_event)
	_check(is_equal_approx(Engine.time_scale, 1.0) and Engine.physics_ticks_per_second == GameController.BASE_PHYSICS_TICKS_PER_SECOND, "cycling beyond triple speed must restore normal time and physics cadence")
	_check(game.screen_effects.camera.enabled, "shared screen effects must own an enabled world camera")
	game.screen_effects.camera.offset = Vector2(11.0, -7.0)
	game.screen_effects.camera.rotation = 0.01
	game.screen_effects.camera.force_update_scroll()
	var input_world_position := game.battlefield.get_battle_rect().get_center() + Vector2(95.0, 0.0)
	var transformed_screen_position := get_viewport().get_canvas_transform() * input_world_position
	_check(game.target_cursor._screen_to_world(transformed_screen_position).distance_to(input_world_position) < 0.01, "target input must invert the active camera transform during screen shake")
	var touch_move_event := InputEventScreenTouch.new()
	touch_move_event.position = transformed_screen_position
	touch_move_event.pressed = true
	var touch_movement_start := game.target_cursor.global_position
	game.target_cursor._unhandled_input(touch_move_event)
	_check(game.target_cursor.destination_position.distance_to(input_world_position) < 0.01 and game.target_cursor.global_position.is_equal_approx(touch_movement_start), "touch input must set a transformed world destination without teleporting the target cursor")
	var touch_distance_before := game.target_cursor.global_position.distance_to(input_world_position)
	game.target_cursor._physics_process(0.1)
	_check(game.target_cursor.global_position.distance_to(input_world_position) < touch_distance_before and game.target_cursor.global_position.distance_to(input_world_position) > 1.0, "the target cursor must advance toward a touch destination at its configured movement speed")
	touch_move_event.pressed = false
	game.target_cursor._unhandled_input(touch_move_event)
	game.target_cursor.warp_to(input_world_position)
	game.screen_effects.reset_effects()
	game.screen_effects.camera.force_update_scroll()
	game.screen_effects.shake(0.55, 0.2)
	game.screen_effects._process(0.016)
	_check(game.screen_effects.shake_request_count == 1 and game.screen_effects.shake_remaining > 0.0, "screen shake requests must start a bounded decay window")
	game.screen_effects.flash(Color("ff6577"), 0.16, 0.2)
	game.screen_effects._process(0.016)
	_check(game.screen_effects.flash_request_count == 1 and game.screen_effects.flash_rect.color.a > 0.0, "shared screen flash must render below the HUD")
	game.screen_effects.flash(Color("ffcf58"), 0.12, 0.04)
	game.screen_effects._process(0.0)
	_check(game.screen_effects.flash_remaining <= game.screen_effects.flash_duration and game.screen_effects.flash_rect.color.a <= game.screen_effects.flash_peak_alpha, "overlapping flashes must keep a normalized duration and bounded alpha")
	game.screen_effects.reset_effects()
	game._show_burst_effect(game.battlefield.get_battle_rect().get_center(), Color("65e0c0"), 100.0, 0.8)
	_check(not get_tree().get_nodes_in_group(&"combat_effects").is_empty(), "shared burst effects must register for lifecycle tracking")
	for effect_node in get_tree().get_nodes_in_group(&"combat_effects"):
		effect_node.queue_free()
	_check(is_equal_approx(game.stage_data.duration_seconds, 600.0), "standard stage must use the 10-minute MVP duration")
	_check(is_equal_approx(game.stage_data.initial_health_multiplier, 1.3), "opening enemy health multiplier must be increased")
	_check(is_equal_approx(game.stage_data.health_multiplier_at(0.0), 1.3), "opening health scaling must start above baseline")
	_check(game.stage_data.spawn_phases[0].base_budget_rate >= 5.0, "opening spawn phase must retain readable but continuous base pressure")
	_check(game.stage_data.spawn_phases.back().base_budget_rate >= game.stage_data.spawn_phases[0].base_budget_rate * 8.0, "late spawn budget must scale far above the opening phase")
	var balance_column := TowerColumn.new()
	add_child(balance_column)
	balance_column.set_process(false)
	balance_column.set_physics_process(false)
	balance_column.setup(0, 0.0, game.battlefield)
	var balance_levels := {&"rapid": 1, &"area": 1}
	var balance_branches := {}
	balance_column.set_shared_progress(balance_levels, balance_branches)
	balance_column.equip_formation_cells(DataRegistry.get_formation(&"balanced"), [{"cell": Vector2i(0, 0), "tower_id": &"rapid"}], &"balance_contract")
	balance_column.attack_accumulators[0] = balance_column.get_attack_interval(0)
	balance_column._physics_process(0.0)
	_check(is_zero_approx(balance_column.attack_flashes[0]), "tower cooldowns without a target must not show a false muzzle flash")
	_check(balance_column.get_tower_art_texture(0) == DataRegistry.get_tower(&"rapid").texture, "idle towers must use their neutral character pose")
	balance_column.confirm_attack(0)
	_check(balance_column.attack_flashes[0] > 0.9, "confirmed tower attacks must trigger a visible recoil and muzzle feedback window")
	_check(balance_column.attack_pose_remaining[0] > 0.0 and balance_column.get_tower_art_texture(0) == DataRegistry.get_tower(&"rapid").attack_texture, "confirmed tower attacks must switch to the dedicated attack pose")
	balance_column._physics_process(0.2)
	_check(is_zero_approx(balance_column.attack_pose_remaining[0]) and balance_column.get_tower_art_texture(0) == DataRegistry.get_tower(&"rapid").texture, "tower attack poses must return to the neutral sprite after the feedback window")
	var level_dps: Array[float] = [balance_column.get_damage_per_second(0)]
	_check(is_equal_approx(balance_column.get_attack_range(0), game.battlefield.get_column_spacing()), "level 1 rapid range must equal one formation cell")
	_check(is_equal_approx(balance_column.get_attack_interval(0), DataRegistry.get_tower(&"rapid").attack_interval), "level 1 tower attack interval must match the design reference base value")
	for next_level in range(2, 8):
		balance_levels[&"rapid"] = next_level
		if next_level == 4:
			balance_branches[&"rapid"] = &"rapid_burn"
		balance_column.set_shared_progress(balance_levels, balance_branches)
		level_dps.append(balance_column.get_damage_per_second(0))
	_check(is_equal_approx(TowerColumn.DAMAGE_LEVEL_CURVE[1], 1.0) and is_equal_approx(TowerColumn.SPEED_LEVEL_CURVE[1], 1.0), "level 1 tower damage and speed must use the documented base stats without hidden reductions")
	_check(is_equal_approx(TowerColumn.DAMAGE_LEVEL_CURVE[3], TowerColumn.DAMAGE_LEVEL_CURVE[4]) and is_equal_approx(TowerColumn.SPEED_LEVEL_CURVE[3], TowerColumn.SPEED_LEVEL_CURVE[4]), "level 4 base stats must stay flat so its specialization supplies the milestone power step")
	_check(level_dps[3] > level_dps[2] * 1.15, "level 4 branch milestone must create a visible power step")
	_check(level_dps[6] > level_dps[0] * 7.5, "level 7 tower must be dramatically stronger than level 1 through stepped stats and branch completion")
	_check(balance_column.is_tower_final(&"rapid"), "level 7 must complete the selected tower branch")
	var rapid_upgrade_text := game.loadout._tower_level_description(&"rapid", 2)
	_check(rapid_upgrade_text.contains("피해") and rapid_upgrade_text.contains("×1.00 → ×1.45"), "tower upgrade cards must show the exact current and next stat multiplier")
	var core_upgrade_text := game.loadout._growth_track_level_description(game.loadout.core_state, false, 2)
	_check(core_upgrade_text.contains("공격 피해") and not core_upgrade_text.contains("최대 체력") and core_upgrade_text.contains("→"), "each core upgrade card must emphasize one large stat increase instead of bundling every base stat")
	var cursor_upgrade_text := game.loadout._growth_track_level_description(game.loadout.cursor_state, true, 2)
	_check(cursor_upgrade_text.contains("공격 피해") and not cursor_upgrade_text.contains("넉백"), "each target-cursor upgrade card must emphasize one focused stat increase")
	var cursor_movement_upgrade_text := game.loadout._growth_track_level_description(game.loadout.cursor_state, true, 5)
	_check(cursor_movement_upgrade_text.contains("이동속도") and not cursor_movement_upgrade_text.contains("공격속도"), "target cursor level 5 must clearly offer movement speed as its focused stat increase")
	_check(LoadoutManager.CORE_DAMAGE_LEVEL_CURVE[2] >= 1.45 and is_equal_approx(LoadoutManager.CORE_HEALTH_LEVEL_CURVE[2], 1.0) and LoadoutManager.CORE_HEALTH_LEVEL_CURVE[3] >= 1.4, "core levels 2 and 3 must create separate damage and durability power spikes")
	_check(LoadoutManager.CURSOR_DAMAGE_LEVEL_CURVE[2] >= 1.5 and is_equal_approx(LoadoutManager.CURSOR_CONTROL_LEVEL_CURVE[2], 1.0) and LoadoutManager.CURSOR_CONTROL_LEVEL_CURVE[3] >= 1.5, "target levels 2 and 3 must create separate damage and knockback power spikes")
	_check(game.loadout._status_upgrade_description(&"bleed", 2).contains("0.35% / 소스별 2중첩") and game.loadout._status_upgrade_description(&"bleed", 2).contains("0.40% / 소스별 2중첩"), "status upgrade cards must show damage-rate and source-specific stack-limit transitions")
	var retired_global_choice := UpgradeData.new().configure(&"global_upgrade", "폐기된 공통 성장", "legacy", &"global")
	_check(not game.loadout.apply_upgrade(retired_global_choice) and game.loadout.global_upgrade_level == 0, "retired global upgrade cards must be rejected by the runtime application boundary")
	balance_column.queue_free()
	var spawn_sampler := EnemySpawner.new()
	add_child(spawn_sampler)
	spawn_sampler.stage_data = game.stage_data
	_check(game.stage_data.spawn_table.size() == 6, "the ten-minute stage must use six explicit weighted spawn phases")
	spawn_sampler.enemy_pool = DataRegistry.enemies
	var early_spawn_ids := spawn_sampler.get_regular_spawn_candidates(45.0).map(func(entry: Dictionary) -> StringName: return (entry.enemy as EnemyData).id)
	var locked_spawn_ids := spawn_sampler.get_regular_spawn_candidates(120.0).map(func(entry: Dictionary) -> StringName: return (entry.enemy as EnemyData).id)
	var mid_spawn_ids := spawn_sampler.get_regular_spawn_candidates(240.0).map(func(entry: Dictionary) -> StringName: return (entry.enemy as EnemyData).id)
	var pressure_spawn_ids := spawn_sampler.get_regular_spawn_candidates(320.0).map(func(entry: Dictionary) -> StringName: return (entry.enemy as EnemyData).id)
	var final_spawn_ids := spawn_sampler.get_regular_spawn_candidates(570.0).map(func(entry: Dictionary) -> StringName: return (entry.enemy as EnemyData).id)
	_check(early_spawn_ids.has(&"civilian_slime") and early_spawn_ids.has(&"goblin_raider") and early_spawn_ids.size() == 2, "opening spawn phase must contain only slime and goblin threats")
	_check(locked_spawn_ids.size() == 2 and not locked_spawn_ids.has(&"skeleton_raider"), "skeleton and orc profiles must remain locked before 150 seconds")
	_check(mid_spawn_ids.has(&"skeleton_raider") and mid_spawn_ids.has(&"orc_shield"), "skeleton and orc threats must enter after 150 seconds")
	_check(pressure_spawn_ids.has(&"hound_light_infantry") and pressure_spawn_ids.has(&"wraith_raider") and final_spawn_ids.has(&"steel_golem"), "hound and wraith must unlock at 300 seconds and steel golem at 450 seconds")
	spawn_sampler.enemy_pool = [DataRegistry.enemies[0]]
	var sampled_spawn_ratios: Array[float] = []
	spawn_sampler.spawn_requested.connect(func(spawn_y_ratio: float, _enemy_data: EnemyData, _health: float, _speed: float, _context: EnemySpawnContext) -> void: sampled_spawn_ratios.append(spawn_y_ratio))
	for sample_index in 12:
		spawn_sampler._spawn_regular(0.0)
	_check(sampled_spawn_ratios.all(func(ratio: float) -> bool: return ratio >= 0.04 and ratio <= 0.96), "free enemy spawns must remain inside the safe vertical battlefield span")
	var unique_spawn_coordinates: Dictionary = {}
	for ratio in sampled_spawn_ratios:
		unique_spawn_coordinates[roundi(ratio * 1000.0)] = true
	_check(unique_spawn_coordinates.size() > 4, "regular enemies must use continuous free Y coordinates instead of four fixed rows")
	spawn_sampler.queue_free()
	var diagonal_spawn := game.battlefield.get_free_spawn_position(0.22)
	var diagonal_context := EnemySpawnContext.new()
	diagonal_context.enemy_id = &"skeleton_raider"
	diagonal_context.spawn_y_ratio = 0.22
	diagonal_context.destination_y_ratio = 0.70
	var diagonal_enemy := game._spawn_enemy(DataRegistry.get_enemy(&"skeleton_raider"), diagonal_spawn, game.battlefield.world_to_lane(diagonal_spawn), 1.0, 1.0, diagonal_context)
	var fixed_direction := diagonal_enemy.fixed_movement_direction
	diagonal_enemy._physics_process(0.2)
	_check(not fixed_direction.is_zero_approx() and fixed_direction.is_equal_approx(diagonal_enemy.fixed_movement_direction) and not is_equal_approx(diagonal_enemy.position.y, diagonal_spawn.y), "skeleton raiders must preserve one fixed diagonal vector from SpawnContext")
	diagonal_enemy.active = false
	diagonal_enemy.queue_free()
	var free_spawn := game.battlefield.get_free_spawn_position(0.16, 54.0)
	var free_enemy := game._spawn_enemy(DataRegistry.get_enemy(&"civilian_slime"), free_spawn, game.battlefield.world_to_lane(free_spawn), 1.0, 1.0)
	free_enemy.set_process(false)
	free_enemy.set_physics_process(false)
	var free_start := free_enemy.position
	var free_distance_before := free_enemy.position.distance_to(free_enemy.target_position)
	free_enemy._physics_process(0.2)
	_check(is_equal_approx(free_enemy.target_position.x, game.battlefield.get_battle_rect().position.x) and is_equal_approx(free_enemy.target_position.y, free_start.y), "ordinary enemies must target the full left core face at their own spawn height")
	_check(free_enemy.position.distance_to(free_enemy.target_position) < free_distance_before and is_equal_approx(free_enemy.position.y, free_start.y), "ordinary enemies must advance horizontally instead of converging diagonally on the core center")
	var shifted_y := free_enemy.position.y + 48.0
	free_enemy.change_vertical_position(shifted_y, game.battlefield.world_to_lane(Vector2(free_enemy.position.x, shifted_y)))
	_check(is_equal_approx(free_enemy.target_position.y, shifted_y), "position-shifting enemies must continue horizontally from their newly selected height")
	free_enemy.active = false
	free_enemy.queue_free()
	game.battlefield.set_spawn_warning(0.37)
	_check(is_equal_approx(game.battlefield.warning_spawn_ratio, 0.37), "boss warnings must retain an exact free spawn coordinate instead of snapping to a row")
	game.battlefield.set_spawn_warning(-1.0)
	var hound_enemy := game._spawn_enemy(DataRegistry.get_enemy(&"hound_light_infantry"), game.battlefield.get_spawn_position(1), 1, 10.0, 1.0)
	hound_enemy.set_process(false)
	hound_enemy.set_physics_process(false)
	for hit_index in 5:
		hound_enemy.take_damage(2.0, &"test")
		hound_enemy._physics_process(0.21)
	_check(hound_enemy.get_acceleration_stack_count() == 5 and is_equal_approx(hound_enemy.get_acceleration_speed_bonus(), 0.30), "hound infantry must mature at five +6% hit-speed stacks with an internal cooldown")
	hound_enemy._physics_process(2.6)
	_check(hound_enemy.get_acceleration_stack_count() == 0, "hound acceleration stacks must expire after their refresh window")
	hound_enemy.active = false
	hound_enemy.queue_free()
	var golem_data := DataRegistry.get_enemy(&"steel_golem")
	_check(golem_data.knockback_resistance > 0.0 and golem_data.knockback_resistance < 1.0 and golem_data.status_resistance > 0.0 and golem_data.status_resistance < 1.0, "steel golem must partially resist knockback and status instead of being immune")
	var wraith_near_column := TowerColumn.new()
	game.add_child(wraith_near_column)
	wraith_near_column.setup(0, game.battlefield.get_column_x(2), game.battlefield)
	wraith_near_column.row_towers.resize(Battlefield.LANE_COUNT)
	wraith_near_column.row_towers.fill(null)
	wraith_near_column.row_towers[0] = DataRegistry.get_tower(&"rapid")
	wraith_near_column.row_towers[1] = DataRegistry.get_tower(&"emerald_guardian")
	var wraith_far_column := TowerColumn.new()
	game.add_child(wraith_far_column)
	wraith_far_column.setup(5, game.battlefield.get_column_x(5), game.battlefield)
	wraith_far_column.row_towers.resize(Battlefield.LANE_COUNT)
	wraith_far_column.row_towers.fill(null)
	wraith_far_column.row_towers[0] = DataRegistry.get_tower(&"rapid")
	game.loadout.columns.append(wraith_near_column)
	game.loadout.columns.append(wraith_far_column)
	var wraith_disable_metric_before := float(game.metrics.mechanic_totals.get("wraith_death_disable", 0.0))
	var wraith_disable_events_before := game.metrics.defender_disable_events.size()
	game._resolve_enemy_death_effect(DataRegistry.get_enemy(&"wraith_raider"), wraith_near_column.get_attack_origin(0))
	var wraith_disable_event: Dictionary = game.metrics.defender_disable_events.back() if not game.metrics.defender_disable_events.is_empty() else {}
	_check(wraith_near_column.is_row_disabled(0) and not wraith_near_column.is_row_disabled(1) and not wraith_far_column.is_row_disabled(0), "wraith death must disable only nearby normal defenders by world distance")
	_check(is_equal_approx(float(game.metrics.mechanic_totals.get("wraith_death_disable", 0.0)), wraith_disable_metric_before + 1.0) and game.metrics.defender_disable_events.size() == wraith_disable_events_before + 1 and wraith_disable_event.get("targets", []) == ["0:0:rapid"], "wraith death resolution must report the unified mechanic count and stable defender target id")
	game.loadout.columns.erase(wraith_near_column)
	game.loadout.columns.erase(wraith_far_column)
	wraith_near_column.queue_free()
	wraith_far_column.queue_free()
	await get_tree().process_frame

	var core_test_y := game.target_cursor.global_position.y
	var core_test_a := game.enemy_container.to_local(game.core.global_position + Vector2(100.0, core_test_y - game.core.global_position.y))
	var core_test_b := game.enemy_container.to_local(game.core.global_position + Vector2(140.0, core_test_y - game.core.global_position.y + 28.0))
	var core_test_c := game.enemy_container.to_local(game.core.global_position + Vector2(100.0, core_test_y - game.core.global_position.y + 100.0))
	var core_test_enemies: Array[Enemy] = [
		game._spawn_enemy(DataRegistry.enemies[3], core_test_a, game.target_cursor.current_sector, 1000.0, 1.0),
		game._spawn_enemy(DataRegistry.enemies[3], core_test_b, game.target_cursor.current_sector, 1000.0, 1.0),
		game._spawn_enemy(DataRegistry.enemies[3], core_test_c, (game.target_cursor.current_sector + 1) % 4, 1000.0, 1.0),
	]
	for enemy in core_test_enemies:
		enemy.set_process(false)
		enemy.set_physics_process(false)
	for core_data in DataRegistry.cores:
		match core_data.attack_type:
			&"pierce":
				core_test_enemies[0].global_position = Vector2(game.core.global_position.x + 100.0, core_test_y)
				core_test_enemies[1].global_position = Vector2(game.core.global_position.x + 140.0, core_test_y + 28.0)
				core_test_enemies[2].global_position = Vector2(game.core.global_position.x + 100.0, core_test_y + 100.0)
			&"radial":
				core_test_enemies[0].global_position = game.core.global_position + Vector2(100.0, -30.0)
				core_test_enemies[1].global_position = game.core.global_position + Vector2(150.0, -120.0)
				core_test_enemies[2].global_position = game.core.global_position + Vector2(200.0, -200.0)
			_:
				core_test_enemies[0].global_position = game.core.global_position + Vector2(100.0, -20.0)
				core_test_enemies[1].global_position = game.core.global_position + Vector2(140.0, -80.0)
				core_test_enemies[2].global_position = game.core.global_position + Vector2(180.0, -140.0)
		for enemy in core_test_enemies:
			enemy.current_health = enemy.get_max_health()
		var health_before: Array[float] = []
		for enemy in core_test_enemies:
			health_before.append(enemy.current_health)
		game._on_core_attack_requested(core_data)
		var damaged_count := 0
		for enemy_index in core_test_enemies.size():
			if core_test_enemies[enemy_index].current_health < health_before[enemy_index]:
				damaged_count += 1
		match core_data.attack_type:
			&"single": _check(damaged_count == 1, "single core attack must damage exactly one nearest target")
			&"pierce": _check(damaged_count == 2, "pierce core attack must damage every target in the cursor band")
			&"radial": _check(damaged_count == 3, "radial core attack must damage nearby targets across rows")
			&"random": _check(damaged_count == 1, "random core attack must damage exactly the target represented by its effect")
	for core_data in DataRegistry.cores:
		_check(core_data.skill_cast_seconds >= 0.8 and core_data.skill_damage >= 150.0, "every core active must have an explicit readable cast time and upgraded base damage")
		match core_data.skill_type:
			&"beam", &"wall":
				core_test_enemies[0].global_position = Vector2(game.core.global_position.x + 100.0, core_test_y)
				core_test_enemies[1].global_position = Vector2(game.core.global_position.x + 140.0, core_test_y + 28.0)
				core_test_enemies[2].global_position = Vector2(game.core.global_position.x + 180.0, core_test_y + 200.0)
			_:
				core_test_enemies[0].global_position = Vector2(game.core.global_position.x + 100.0, core_test_y)
				core_test_enemies[1].global_position = Vector2(game.core.global_position.x + 140.0, core_test_y + 80.0)
				core_test_enemies[2].global_position = Vector2(game.core.global_position.x + 180.0, core_test_y + 160.0)
		var skill_health_before: Array[float] = []
		var skill_position_before := core_test_enemies[0].global_position
		for enemy in core_test_enemies:
			enemy.current_health = enemy.get_max_health()
			enemy.clear_statuses()
			enemy.control_recovery_remaining.clear()
			skill_health_before.append(enemy.current_health)
		game._on_core_skill_requested(core_data)
		var skill_damaged_count := 0
		for enemy_index in core_test_enemies.size():
			if core_test_enemies[enemy_index].current_health < skill_health_before[enemy_index]:
				skill_damaged_count += 1
		match core_data.skill_type:
			&"beam": _check(skill_damaged_count == 2 and core_test_enemies[0].global_position.x > skill_position_before.x and core_test_enemies[0].statuses.has(&"stun"), "beam core skill must hit its widened band with heavy knockback and a cast-impact stun")
			&"radial":
				_check(skill_damaged_count == 3 and core_test_enemies.all(func(enemy: Enemy) -> bool: return enemy.statuses.has(&"pierce_mark")), "radial core skill must damage, displace, and expose every active enemy")
				_check(game.candidate_charm_stage_remaining >= core_data.charm_profile.active_zone_duration and not game.candidate_charm_stage_grants_buff, "Jiane's base active must leave a persistent charm zone without granting the branch-only army buff")
				game.candidate_charm_stage_remaining = 0.0
				game.candidate_charm_zone_profile = null
			&"wall": _check(skill_damaged_count == 2 and core_test_enemies[0].statuses.has(&"slow") and core_test_enemies[0].statuses.has(&"stun"), "wall core skill must damage, slow, stun, and push enemies in its widened band")
			&"barrage": _check(skill_damaged_count == 3, "barrage core skill must cover every available target before repeating impacts")
	var cast_probe := DefenseCore.new()
	add_child(cast_probe)
	cast_probe.set_process(false)
	cast_probe.set_physics_process(false)
	var cast_probe_data := DataRegistry.get_core(&"emerald")
	var cast_resolved := {"value": false}
	cast_probe.skill_requested.connect(func(_data: CoreData) -> void: cast_resolved.value = true)
	cast_probe.configure(cast_probe_data)
	cast_probe.skill_charge = cast_probe_data.skill_charge_seconds
	_check(cast_probe.activate_skill() and cast_probe.is_skill_casting() and not cast_resolved.value, "activating a charged core skill must enter a real cast state without resolving immediately")
	cast_probe.add_skill_charge(5.0)
	_check(is_zero_approx(cast_probe.skill_charge), "skill charge gains must pause during the cast")
	cast_probe._physics_process(cast_probe_data.skill_cast_seconds * 0.5)
	_check(cast_probe.is_skill_casting() and not cast_resolved.value, "core skill damage must remain pending during the telegraph window")
	cast_probe._physics_process(cast_probe_data.skill_cast_seconds * 0.51)
	_check(not cast_probe.is_skill_casting() and cast_resolved.value, "core skill must resolve once when its cast time completes")
	cast_probe.queue_free()
	var reaper_core_probe := DefenseCore.new()
	add_child(reaper_core_probe)
	reaper_core_probe.set_process(false)
	reaper_core_probe.set_physics_process(false)
	var reaper_attack_count := {"value": 0}
	reaper_core_probe.attack_requested.connect(func(_data: CoreData) -> void: reaper_attack_count.value += 1)
	var reaper_core_data := DataRegistry.get_core(&"obsidian")
	reaper_core_probe.configure(reaper_core_data)
	reaper_core_probe.skill_charge = reaper_core_data.skill_charge_seconds
	_check(reaper_core_probe.activate_skill(), "Judaginda's charged Reaper active must enter its cast state")
	reaper_core_probe._physics_process(reaper_core_data.skill_cast_seconds * 1.01)
	_check(int(reaper_attack_count.value) == 0 and not reaper_core_probe.is_skill_casting(), "Judaginda must remain unable to perform basic attacks for the entire Reaper summon cast")
	reaper_core_probe._physics_process(0.01)
	_check(int(reaper_attack_count.value) == 1, "Judaginda must resume basic attacks after the Reaper strike resolves")
	reaper_core_probe.queue_free()
	for enemy in core_test_enemies:
		enemy.active = false
		enemy.queue_free()
	await get_tree().process_frame

	var battle_rect := game.battlefield.get_battle_rect()
	var requested_target_position := battle_rect.position + battle_rect.size * Vector2(0.63, 0.29)
	game.target_cursor.attack_accumulator = 0.12
	var movement_start := game.target_cursor.position
	game.target_cursor.set_destination(requested_target_position)
	_check(game.target_cursor.position.is_equal_approx(movement_start) and game.target_cursor.destination_position.is_equal_approx(requested_target_position), "target cursor commands must preserve free X/Y coordinates as a destination without teleporting")
	var movement_distance_before := game.target_cursor.get_remaining_movement_distance()
	game.target_cursor._physics_process(0.1)
	_check(game.target_cursor.get_remaining_movement_distance() < movement_distance_before and is_equal_approx(movement_start.distance_to(game.target_cursor.position), game.target_cursor.get_effective_movement_speed() * 0.1), "target cursor travel distance must be limited by movement speed and frame time")
	game.target_cursor.warp_to(requested_target_position)
	_check(game.target_cursor.position.is_equal_approx(requested_target_position), "target cursor movement must preserve both free X and Y coordinates inside the battlefield")
	_check(game.target_cursor.current_sector == game.battlefield.world_to_lane(requested_target_position), "free target movement must retain the nearest installation row as compatibility metadata")
	_check(game.hud.lane_label.text.contains("X62") and game.hud.lane_label.text.contains("Y29") and not game.hud.lane_label.text.contains("행"), "target HUD must report free normalized X/Y coordinates instead of a snapped row")
	game.target_cursor.attack_accumulator = 0.12
	game.target_cursor.set_destination(battle_rect.position - Vector2(80.0, 60.0))
	_check(is_equal_approx(game.target_cursor.attack_accumulator, 0.12), "issuing a target movement command must not recharge its attack cooldown")
	_check(game.target_cursor.destination_position.is_equal_approx(battle_rect.position), "target cursor must clamp free movement destinations to both battlefield edges")
	game.target_cursor.warp_to(requested_target_position)
	game.target_cursor.refresh_layout()
	_check(game.target_cursor.position.is_equal_approx(requested_target_position), "layout refresh must not snap a free target position back to a row center")
	game.target_cursor.apply_upgrade(1.4, 1.0, 1.3, 1.0, 1.25)
	_check(is_equal_approx(game.target_cursor.get_effective_attack_radius(), game.target_cursor.data.attack_radius * 1.3), "cursor damage growth must not leak into attack and collection radius")
	_check(is_equal_approx(game.target_cursor.stat_multiplier, 1.4), "cursor damage must retain its independent upgrade channel")
	_check(is_equal_approx(game.target_cursor.get_effective_movement_speed(), game.target_cursor.data.movement_speed * 1.25), "target cursor movement speed must retain an independent upgrade channel")
	game.target_cursor.apply_upgrade(1.0, 1.0, 1.0, 1.0, 1.0)
	game.target_cursor.attack_accumulator = game.target_cursor.data.attack_interval
	game.target_cursor._physics_process(0.01)
	_check(game.target_cursor.attack_flash > 0.9, "target cursor attack must trigger a strong visual pulse")
	_check(game.target_cursor.attack_accumulator < 0.02, "target cursor circular cooldown must reset after an attack")
	_check(game._uses_projectile(&"rapid"), "rapid tower must use a projectile")
	_check(game._uses_projectile(&"area"), "area tower must use a projectile")
	_check(not game._uses_projectile(&"slow"), "slow tower must apply a full-range aura without a projectile")
	_check(not game._uses_projectile(&"knockback"), "knockback tower must use a persistent orbit attack instead of another ordinary projectile")
	_check(not game._uses_projectile(&"pierce"), "pierce tower must remain hitscan")
	_check(not game._uses_projectile(&"execute"), "execute tower must remain hitscan")
	_check(not game._uses_projectile(&"mark"), "mark tower must remain hitscan")
	_check(not game._uses_projectile(&"chain"), "chain tower must remain hitscan")
	var attraction_orb := ExperienceOrb.new()
	add_child(attraction_orb)
	attraction_orb.setup(requested_target_position + Vector2(80.0, 0.0), 2.0)
	var attraction_distance_before := attraction_orb.global_position.distance_to(requested_target_position)
	_check(not attraction_orb.attract_and_collect(requested_target_position, 100.0, 0.1), "an experience orb entering collection range must start attraction before it is collected")
	attraction_orb._physics_process(0.08)
	_check(attraction_orb.attracting and attraction_orb.global_position.distance_to(requested_target_position) < attraction_distance_before and attraction_orb.trail_points.size() >= 1, "an attracted experience orb must smoothly accelerate toward the target center and retain a suction trail")
	attraction_orb.queue_free()
	var launched_orb := ExperienceOrb.new()
	add_child(launched_orb)
	var launched_start := requested_target_position
	launched_orb.setup(launched_start, 12.0, Vector2(180.0, -40.0), 0.6, game.battlefield.get_battle_rect())
	_check(not launched_orb.attract_and_collect(requested_target_position, 200.0, 0.1), "a boss reward orb must remain collection-locked during its launch spectacle")
	launched_orb._physics_process(0.1)
	_check(launched_orb.global_position.distance_to(launched_start) > 10.0 and launched_orb.trail_points.size() >= 1, "a boss reward orb must visibly eject with launch velocity and a trail")
	launched_orb.queue_free()
	await get_tree().process_frame

	var core_position := game.core.global_position
	var advanced_outer := game._spawn_enemy(DataRegistry.enemies[3], core_position + Vector2(210.0, -46.0), 0, 10.0, 1.0)
	var trailing_center := game._spawn_enemy(DataRegistry.enemies[3], core_position + Vector2(280.0, 30.0), 1, 10.0, 1.0)
	advanced_outer.set_process(false)
	advanced_outer.set_physics_process(false)
	trailing_center.set_process(false)
	trailing_center.set_physics_process(false)
	_check(game.targeting_service.frontmost_to_core([trailing_center, advanced_outer], core_position) == advanced_outer, "closest-core targeting must use horizontal progress toward the full left core face")
	_check(game.targeting_service.highest_current_health([trailing_center, advanced_outer], core_position) == advanced_outer, "equal-health targeting must break ties in favor of the more advanced enemy")
	_check(game.targeting_service.density_queries.select_densest([trailing_center, advanced_outer], 40.0, core_position) == advanced_outer, "equal-density targeting must break ties by breach progress")
	var cursor_position_before_targeting_test := game.target_cursor.global_position
	game.target_cursor.warp_to(advanced_outer.global_position)
	var synchronized_targets := game._cursor_priority_targets([trailing_center, advanced_outer])
	_check(synchronized_targets.size() == 1 and synchronized_targets[0] == advanced_outer, "target synchronization must use a free circular region around the cursor")
	game.target_cursor.warp_to(cursor_position_before_targeting_test)
	var ratio_low_tank := game._spawn_enemy(DataRegistry.enemies[3], Vector2(core_position.x + 230.0, game.battlefield.get_lane_y(2)), 2, 10.0, 1.0)
	var killable_mob := game._spawn_enemy(DataRegistry.enemies[3], Vector2(core_position.x + 250.0, game.battlefield.get_lane_y(2)), 2, 1.0, 1.0)
	ratio_low_tank.set_process(false)
	ratio_low_tank.set_physics_process(false)
	killable_mob.set_process(false)
	killable_mob.set_physics_process(false)
	ratio_low_tank.current_health = 80.0
	killable_mob.current_health = 50.0
	_check(game.targeting_service.select_by_rule([ratio_low_tank, killable_mob], &"lowest_health", core_position, Vector2.ZERO, 0.0) == killable_mob, "execute targeting must choose the lowest remaining health rather than the lowest health ratio")
	var fast_threat := game._spawn_enemy(DataRegistry.get_enemy(&"fast"), Vector2(core_position.x + 420.0, game.battlefield.get_lane_y(3)), 3, 1.0, 1.0)
	var slow_threat := game._spawn_enemy(DataRegistry.get_enemy(&"guardian"), Vector2(core_position.x + 250.0, game.battlefield.get_lane_y(3)), 3, 1.0, 1.0)
	fast_threat.set_process(false)
	fast_threat.set_physics_process(false)
	slow_threat.set_process(false)
	slow_threat.set_physics_process(false)
	_check(game.targeting_service.select_by_rule([slow_threat, fast_threat], &"breach_pressure", core_position, Vector2.ZERO, 0.0) == fast_threat, "slow tower targeting must combine movement speed with remaining breach distance")
	for targeting_enemy in [advanced_outer, trailing_center, ratio_low_tank, killable_mob, fast_threat, slow_threat]:
		targeting_enemy.active = false
		targeting_enemy.queue_free()
	await get_tree().process_frame

	var balanced_formation := DataRegistry.get_formation(&"balanced")
	var balanced_placement := game.loadout.get_valid_board_placements(balanced_formation)[0] as Dictionary
	var balanced_choice := UpgradeData.new().configure(&"new_formation", "균형 편대", "test", &"balanced")
	balanced_choice.board_anchor = balanced_placement.anchor as Vector2i
	balanced_choice.vertical_flip = bool(balanced_placement.vertical_flipped)
	balanced_choice.placement_confirmed = true
	_check(game.loadout.apply_upgrade(balanced_choice), "a valid formation placement must report a successful upgrade application")
	RunRng.seed_run(7299)
	var early_expansion_choices := game.loadout.generate_upgrade_choices()
	_check(early_expansion_choices.size() == 3 and early_expansion_choices.filter(func(choice: UpgradeData) -> bool: return choice.category == &"formation_set").size() <= 1 and early_expansion_choices.all(func(choice: UpgradeData) -> bool: return choice.category != &"new_formation"), "block-board level-up offers must remain three cards and expose recipes only through at most one formation-set entry")
	_check(not UpgradeOfferService.has_duplicate_choices(early_expansion_choices), "an early level-up screen must not display the same category and stable reward ID more than once")
	var duplicate_placement := UpgradeData.new().configure(&"new_formation", "중복 편대", "test", &"balanced")
	duplicate_placement.board_anchor = balanced_choice.board_anchor
	duplicate_placement.placement_confirmed = true
	_check(not game.loadout.apply_upgrade(duplicate_placement), "an occupied formation placement must report failure instead of consuming an upgrade")
	var offer_state_before_retry := game.loadout.get_offer_state_snapshot()
	RunRng.seed_run(7301)
	var repeated_offer := game.loadout.generate_upgrade_choices()
	RunRng.seed_run(7301)
	var expected_visible_offer: Array[UpgradeData] = []
	for _attempt in 4:
		game.loadout.restore_offer_state(offer_state_before_retry)
		expected_visible_offer = game.loadout.generate_upgrade_choices()
		if game.loadout._upgrade_choice_signature(expected_visible_offer) != game.loadout._upgrade_choice_signature(repeated_offer):
			break
	var expected_offer_state := game.loadout.get_offer_state_snapshot()
	game.loadout.restore_offer_state(offer_state_before_retry)
	RunRng.seed_run(7301)
	var rerolled_offer := game.loadout.generate_rerolled_upgrade_choices(repeated_offer)
	_check(game.loadout._upgrade_choice_signature(rerolled_offer) != game.loadout._upgrade_choice_signature(repeated_offer), "a reroll must retry a repeated visible offer when another draw is available")
	_check(game.loadout.get_offer_state_snapshot() == expected_offer_state, "discarded reroll attempts must not advance specialization or guard-growth pity state more than the final visible offer")
	var balanced_slices := game.loadout.placed_formation_slices[balanced_choice.placement_id] as Array
	var projectile_column := balanced_slices[0] as TowerColumn
	var projectile_row := projectile_column.row_towers.find(DataRegistry.get_tower(&"rapid"))
	projectile_column.set_process(false)
	projectile_column.set_physics_process(false)
	projectile_column.attack_accumulators[projectile_row] = 0.0
	var tower_catch_up_attacks := {"count": 0}
	projectile_column.attack_requested.connect(func(_column: TowerColumn, row_index: int) -> void:
		if row_index == projectile_row:
			tower_catch_up_attacks.count += 1
	)
	var tower_catch_up_interval := projectile_column.get_attack_interval(projectile_row)
	projectile_column._physics_process(tower_catch_up_interval * 2.5)
	_check(tower_catch_up_attacks.count == 2 and is_equal_approx(projectile_column.attack_accumulators[projectile_row], tower_catch_up_interval * 0.5), "tower attack timers must preserve remainder and catch up independently of frame length")
	projectile_column.attack_accumulators[projectile_row] = 0.0
	var balanced_tower_ids: Array[StringName] = []
	for balanced_slice in balanced_slices:
		for balanced_tower in (balanced_slice as TowerColumn).row_towers:
			if balanced_tower != null:
				balanced_tower_ids.append(balanced_tower.id)
	_check(balanced_tower_ids == [&"rapid", &"rapid", &"rapid", &"rapid"], "the four-cell balanced block must contain four ordinary rapid towers across its combat slices")
	_check(not game.loadout.has_common_status_application_source(&"poison") and not game.loadout.has_common_status_application_source(&"burn") and not game.loadout.has_common_status_application_source(&"bleed") and not game.loadout.has_common_status_application_source(&"shock") and game.loadout._random_status_upgrade_choice() == null, "common status cards must stay out of the pool when the build has no way to apply them")
	_check(game.loadout._tower_supports_common_status(DataRegistry.get_tower(&"knockback"), &"bleed") and game.loadout._tower_supports_common_status(DataRegistry.get_tower(&"chain"), &"shock"), "innate bleed and shock tower roles must be recognized as matching status-card prerequisites")
	var repeatable_pool := game.loadout.get_formation_choice_pool()
	_check(repeatable_pool.size() == 49 and repeatable_pool.any(func(formation: TowerFormationData) -> bool: return formation.id == &"balanced") and repeatable_pool.all(func(formation: TowerFormationData) -> bool: return not formation.is_unique()), "an acquired regular formation must remain repeatable while unique formations stay in their separate run-limited pool")
	var detail_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"new_formation", "표준 사격진", "test", &"balanced"),
		UpgradeData.new().configure(&"new_formation", "중앙 유도형", "test", &"guidance"),
		UpgradeData.new().configure(&"new_formation", "집중 포격형", "test", &"barrage"),
	]
	var panel_reroll_requests := {"count": 0}
	game.level_up_panel.reroll_requested.connect(func() -> void: panel_reroll_requests.count += 1)
	game.level_up_panel.show_choices(detail_choices, 2, 2, 3)
	_check(game.level_up_panel.reroll_button.visible and game.level_up_panel.reroll_button.text.contains("2 / 3"), "normal level-up cards must expose the remaining per-run reroll count")
	game.level_up_panel.reroll_button.pressed.emit()
	_check(panel_reroll_requests.count == 1, "an available reroll button must request a fresh trait draw")
	game.level_up_panel.set_reroll_state(0, 3)
	game.level_up_panel.reroll_button.pressed.emit()
	_check(panel_reroll_requests.count == 1 and game.level_up_panel.reroll_button.disabled, "a depleted reroll button must be disabled and emit no request")
	_check(game.level_up_panel.detail_buttons.all(func(button: Button) -> bool: return button.visible), "formation level-up cards must expose a separate details button")
	game.level_up_panel._show_formation_details(0)
	var detail_formation := DataRegistry.get_formation(detail_choices[0].data_id)
	_check(game.level_up_panel.details_open and game.level_up_panel.details_tower_list.get_child_count() == 1 and game.level_up_panel.details_shape_preview.get_child_count() == 1 and game.level_up_panel.details_summary.text.contains("기초 편성점수") and game.level_up_panel.details_summary.text.contains(detail_formation.get_shape_display_name()) and game.level_up_panel.details_summary.text.contains("%d병종" % detail_formation.get_distinct_tower_count()) and game.level_up_panel.details_summary.text.contains("배치 %s" % detail_formation.get_placement_difficulty_display_name()), "formation details must show a mini-board plus the set intent, shape, species, difficulty, score, and each unique tower")
	game.level_up_panel.hide_panel()
	game._set_range_overlay(true)
	var inspected_origin := projectile_column.get_attack_origin(projectile_row)
	_check(game.range_overlay.inspect_at(inspected_origin), "range inspection must select an installed tower at its battlefield position")
	_check(game.range_overlay.is_overlay_enabled() and game.range_overlay.get_visible_tower_count() == game.loadout.board_state.get_occupied_count() and is_equal_approx(game.range_overlay.get_inspected_range(), projectile_column.get_attack_range(projectile_row)), "contextual overlay must cover every occupied block cell while inspecting the selected tower's effective runtime range")
	_check(game.unit_info_popover.visible and game.unit_info_popover.get_snapshot().get("stable_id", &"") == projectile_column.get_tower_data(projectile_row).id and String(game.unit_info_popover.status_label.text).contains("상태"), "range inspection must present a matching read-only defender popover with explicit status text")
	game._set_range_overlay(false)
	_check(not game.unit_info_popover.visible, "closing range inspection must also dismiss its unit information popover")
	var repeated_placements := game.loadout.get_valid_board_placements(balanced_formation).filter(func(placement: Dictionary) -> bool: return (placement.anchor as Vector2i).y >= 2)
	var repeated_choice := UpgradeData.new().configure(&"new_formation", "표준 사격진 반복", "test", &"balanced")
	repeated_choice.board_anchor = (repeated_placements[0] as Dictionary).anchor as Vector2i
	repeated_choice.vertical_flip = bool((repeated_placements[0] as Dictionary).vertical_flipped)
	repeated_choice.placement_confirmed = true
	_check(game.loadout.apply_upgrade(repeated_choice), "the same formation recipe must be installable in another valid board region")
	_check(game.loadout.get_board_snapshot().filter(func(placement: Dictionary) -> bool: return placement.formation_id == &"balanced").size() == 2, "repeated block recipes must retain two independent placement owners")
	var active_core_data := DataRegistry.get_core(GameSession.selected_core_id)
	var guard_snapshot := game.loadout.get_board_snapshot().filter(func(placement: Dictionary) -> bool: return bool(placement.is_guard))
	var unique_columns := game.loadout.columns.filter(func(column: TowerColumn) -> bool: return column.contains_tower_type(active_core_data.unique_tower_id))
	_check(guard_snapshot.size() == 1 and (guard_snapshot[0] as Dictionary).formation_id == active_core_data.unique_formation_id and game.loadout.get_build_summary().contains("★"), "mandatory preparation must install and mark exactly the selected core's guard formation")
	_check(game.loadout.generate_upgrade_choices().all(func(choice: UpgradeData) -> bool: return choice.category != &"unique_formation") and game.loadout.get_formation_choice_pool().all(func(formation: TowerFormationData) -> bool: return not formation.is_unique()), "mandatory guards must stay out of ordinary block level-up offers and the repeatable formation pool")
	var unique_column := unique_columns[0] as TowerColumn
	var unique_row := unique_column.row_towers.find(DataRegistry.get_tower(active_core_data.unique_tower_id))
	var unique_origin := unique_column.get_attack_origin(unique_row)
	var unique_target := game._spawn_enemy(DataRegistry.enemies[3], unique_origin + Vector2(110.0, 0.0), unique_row, 10.0, 1.0)
	unique_target.set_process(false)
	unique_target.set_physics_process(false)
	var unique_health_before := unique_target.current_health
	game._on_tower_attack_requested(unique_column, unique_row)
	var unique_projectiles := get_tree().get_nodes_in_group(&"projectiles").filter(func(projectile: Projectile) -> bool: return projectile.payload.get("behavior") == &"unique_single")
	_check(unique_projectiles.size() == 1, "the emerald unique tower must fire its own core-analog resonant projectile")
	if not unique_projectiles.is_empty():
		(unique_projectiles[0] as Projectile)._physics_process(0.5)
	_check(unique_target.current_health < unique_health_before and unique_target.last_knockback_displacement > 0.0, "the emerald resonant projectile must deal damage and reproduce the core's control identity through knockback")
	unique_target.active = false
	unique_target.queue_free()
	await get_tree().process_frame
	var original_unique_tower := unique_column.row_towers[unique_row]
	unique_column.row_towers[unique_row] = DataRegistry.get_tower(&"sapphire_lance")
	var lance_targets: Array[Enemy] = [
		game._spawn_enemy(DataRegistry.enemies[3], unique_origin + Vector2(100.0, 0.0), unique_row, 10.0, 1.0),
		game._spawn_enemy(DataRegistry.enemies[3], unique_origin + Vector2(190.0, 0.0), unique_row, 10.0, 1.0),
	]
	for enemy in lance_targets:
		enemy.set_process(false)
		enemy.set_physics_process(false)
	var lance_health := lance_targets.map(func(enemy: Enemy) -> float: return enemy.current_health)
	game._on_tower_attack_requested(unique_column, unique_row)
	_check(lance_targets[0].current_health < lance_health[0] and lance_targets[1].current_health < lance_health[1], "the sapphire unique tower must reproduce its core's straight-line piercing identity")
	for enemy in lance_targets:
		enemy.active = false
		enemy.queue_free()
	await get_tree().process_frame
	unique_column.row_towers[unique_row] = DataRegistry.get_tower(&"amethyst_nova")
	var nova_targets: Array[Enemy] = [
		game._spawn_enemy(DataRegistry.enemies[3], unique_origin + Vector2(80.0, -20.0), unique_row, 10.0, 1.0),
		game._spawn_enemy(DataRegistry.enemies[3], unique_origin + Vector2(105.0, 24.0), unique_row, 10.0, 1.0),
	]
	for enemy in nova_targets:
		enemy.set_process(false)
		enemy.set_physics_process(false)
	var nova_health := nova_targets.map(func(enemy: Enemy) -> float: return enemy.current_health)
	game._on_tower_attack_requested(unique_column, unique_row)
	_check(nova_targets[0].current_health < nova_health[0] and nova_targets[1].current_health < nova_health[1] and nova_targets.all(func(enemy: Enemy) -> bool: return enemy.statuses.has(&"slow")), "the amethyst unique tower must damage and slow every nearby target with a radial core-like pulse")
	for enemy in nova_targets:
		enemy.active = false
		enemy.queue_free()
	await get_tree().process_frame
	unique_column.row_towers[unique_row] = DataRegistry.get_tower(&"jade_roulette")
	var undead_lifecycle := game._get_retainer_reactivation_component(unique_column, unique_row, unique_column.row_towers[unique_row])
	var undead_health_before := undead_lifecycle.current_health
	var roulette_targets: Array[Enemy] = []
	for target_index in 4:
		var roulette_target := game._spawn_enemy(DataRegistry.enemies[3], unique_origin + Vector2(90.0 + target_index * 28.0, (target_index - 2) * 15.0), unique_row, 10.0, 1.0)
		roulette_target.set_process(false)
		roulette_target.set_physics_process(false)
		roulette_targets.append(roulette_target)
	var roulette_health := roulette_targets.map(func(enemy: Enemy) -> float: return enemy.current_health)
	game._on_tower_attack_requested(unique_column, unique_row)
	_check(roulette_targets.all(func(enemy: Enemy) -> bool: return enemy.current_health < roulette_health[roulette_targets.find(enemy)]), "the undead guard must distribute one summoned barrage across four distinct targets")
	_check(undead_lifecycle.current_health < undead_health_before, "the undead guard must spend isolated activity health only when an attack is confirmed")
	for enemy in roulette_targets:
		enemy.active = false
		enemy.queue_free()
	unique_column.row_towers[unique_row] = original_unique_tower
	unique_column.queue_redraw()
	await get_tree().process_frame
	var projectile_origin := projectile_column.get_attack_origin(projectile_row)
	var blocking_enemy := game._spawn_enemy(
		DataRegistry.enemies[3],
		projectile_origin + Vector2(120.0, 0.0),
		projectile_row,
		10.0,
		1.0
	)
	var aimed_enemy := game._spawn_enemy(DataRegistry.enemies[3], projectile_origin + Vector2(300.0, 0.0), projectile_row, 10.0, 1.0)
	blocking_enemy.set_process(false)
	blocking_enemy.set_physics_process(false)
	aimed_enemy.set_process(false)
	aimed_enemy.set_physics_process(false)
	_check(blocking_enemy in game.spatial_index.get_active_enemies() and aimed_enemy in game.spatial_index.get_active_enemies(), "spawned enemies must register with the reusable spatial index")
	_check(blocking_enemy in game.spatial_index.query_radius(blocking_enemy.global_position, 24.0) and aimed_enemy not in game.spatial_index.query_radius(blocking_enemy.global_position, 24.0), "spatial index radius queries must return only nearby active enemies")
	var aimed_original_position := aimed_enemy.global_position
	aimed_enemy.global_position += Vector2(0.0, 220.0)
	_check(aimed_enemy not in game.spatial_index.query_radius(aimed_original_position, 24.0) and aimed_enemy in game.spatial_index.query_radius(aimed_enemy.global_position, 24.0), "spatial index cells must update incrementally when an enemy transform changes")
	aimed_enemy.global_position = aimed_original_position
	var ordered_pierce_targets: Array[Enemy] = [aimed_enemy, blocking_enemy]
	game._sort_targets_along_segment(ordered_pierce_targets, projectile_origin, projectile_origin + Vector2.RIGHT * 600.0)
	_check(ordered_pierce_targets == [blocking_enemy, aimed_enemy], "piercing targets must be ordered by beam progress rather than spawn order")
	var blocker_health_before := blocking_enemy.current_health
	var aimed_health_before := aimed_enemy.current_health
	var rapid_targets := game._enemies_in_tower_range([blocking_enemy, aimed_enemy], projectile_column, projectile_row, projectile_column.get_tower_data(projectile_row))
	_check(blocking_enemy in rapid_targets and aimed_enemy not in rapid_targets, "rapid tower must acquire nearby enemies but reject enemies beyond 1 cell")
	var rapid_origin := projectile_column.get_attack_origin(projectile_row)
	var free_target_position := rapid_origin + Vector2(40.0, projectile_column.get_attack_range(projectile_row) * 0.45)
	var free_target := game._spawn_enemy(DataRegistry.enemies[3], free_target_position, game.battlefield.world_to_lane(free_target_position), 100.0, 1.0)
	free_target.set_process(false)
	free_target.set_physics_process(false)
	var free_range_targets := game._enemies_in_tower_range([free_target], projectile_column, projectile_row, projectile_column.get_tower_data(projectile_row))
	_check(free_target in free_range_targets and not is_equal_approx(free_target.global_position.y, rapid_origin.y), "a fixed tower must acquire enemies by circular distance even when they are between tower rows")
	free_target.active = false
	free_target.queue_free()
	var rapid_lane_height := game.battlefield.get_battle_rect().size.y / float(game.battlefield.lane_count) * 0.48
	var direct_rapid_targets := game.targeting_service.filter_tower_range(
		[blocking_enemy, aimed_enemy],
		rapid_origin,
		projectile_column.get_attack_range(projectile_row),
		rapid_origin.y,
		rapid_lane_height,
		false
	)
	_check(direct_rapid_targets == rapid_targets, "game controller tower range queries must delegate to the targeting service without changing results")
	game._on_tower_attack_requested(projectile_column, projectile_row)
	var rapid_volley := get_tree().get_nodes_in_group(&"projectiles")
	_check(rapid_volley.size() == 1 and rapid_volley.all(func(projectile: Projectile) -> bool: return projectile.payload.get("behavior") == &"rapid"), "rapid tower must fire one readable single-target projectile")
	for projectile in rapid_volley:
		projectile.queue_free()
	await get_tree().process_frame
	game._spawn_tower_projectile(projectile_column, projectile_row, projectile_column.get_tower_data(projectile_row), aimed_enemy.global_position, projectile_column.get_damage(projectile_row))
	_check(is_equal_approx(blocking_enemy.current_health, blocker_health_before), "projectile damage must not apply on fire")
	var active_projectiles := get_tree().get_nodes_in_group(&"projectiles")
	_check(active_projectiles.size() == 1, "projectile tower must create one flying projectile")
	if not active_projectiles.is_empty():
		var projectile := active_projectiles[0] as Projectile
		projectile.speed = 10000.0
		projectile._physics_process(1.0)
		_check(is_instance_valid(projectile) and projectile.remaining_hits == 0, "rapid projectile must stop after its first single-target collision")
	await get_tree().process_frame
	_check(blocking_enemy.current_health < blocker_health_before, "projectile must damage the first enemy intersecting its path")
	_check(is_equal_approx(aimed_enemy.current_health, aimed_health_before), "projectile must disappear before reaching the aimed enemy after an earlier collision")
	_check(get_tree().get_nodes_in_group(&"projectiles").is_empty(), "projectile must be removed after impact")
	var pass_through_projectile := Projectile.new()
	add_child(pass_through_projectile)
	pass_through_projectile.setup(Vector2(0.0, -500.0), Vector2(20.0, -500.0), null, 100.0, Color.WHITE, 20.0, {})
	pass_through_projectile._physics_process(0.3)
	_check(is_instance_valid(pass_through_projectile) and pass_through_projectile.position.x > 20.0, "projectile must continue beyond its aim point when nothing is hit")
	_check(pass_through_projectile.trail_points.size() >= 2, "all flying projectiles must retain a short reusable motion trail")
	pass_through_projectile.queue_free()
	var endpoint_projectile := Projectile.new()
	add_child(endpoint_projectile)
	var endpoint_impact := {"count": 0, "target": null}
	endpoint_projectile.impacted.connect(func(target: Enemy, _position: Vector2, _payload: Dictionary) -> void:
		endpoint_impact.count += 1
		endpoint_impact.target = target
	)
	endpoint_projectile.setup(Vector2(0.0, -550.0), Vector2(100.0, -550.0), null, 100.0, Color.WHITE, 20.0, {}, 25.0)
	endpoint_projectile._physics_process(0.5)
	_check(endpoint_impact.count == 1 and endpoint_impact.target == null, "a projectile reaching maximum range must emit one terminal impact instead of vanishing")
	await get_tree().process_frame
	projectile_column.set_shared_progress({&"rapid": 7}, {&"rapid": &"rapid_burn"})
	game._on_tower_attack_requested(projectile_column, projectile_row)
	var goblin_number_volley := get_tree().get_nodes_in_group(&"projectiles")
	_check(goblin_number_volley.size() == 3, "goblin numbers specialization must emit three bounded shots from one tower controller at level seven")
	for projectile in goblin_number_volley:
		projectile.queue_free()
	await get_tree().process_frame
	projectile_column.set_shared_progress({&"rapid": 7}, {&"rapid": &"rapid_ricochet"})
	projectile_column.attack_counts[projectile_row] = 5
	game._on_tower_attack_requested(projectile_column, projectile_row)
	var elite_goblin_projectiles := get_tree().get_nodes_in_group(&"projectiles")
	var elite_goblin_damage := projectile_column.get_damage(projectile_row)
	_check(elite_goblin_projectiles.size() == 1 and float((elite_goblin_projectiles[0] as Projectile).payload.damage) >= elite_goblin_damage * 1.59 and float(game.metrics.mechanic_totals.get("goblin_warcry", 0.0)) > 0.0, "elite goblins must trigger their stronger periodic warcry shot")
	for projectile in elite_goblin_projectiles:
		projectile.queue_free()
	await get_tree().process_frame
	projectile_column.set_shared_progress({&"rapid": 7}, {&"rapid": &"rapid_mark"})
	projectile_column.attack_counts[projectile_row] = 1
	game._on_tower_attack_requested(projectile_column, projectile_row)
	var tactics_projectiles := get_tree().get_nodes_in_group(&"projectiles")
	if not tactics_projectiles.is_empty():
		var tactics_projectile := tactics_projectiles[0] as Projectile
		game._on_projectile_impacted(blocking_enemy, blocking_enemy.global_position, tactics_projectile.payload)
	_check((blocking_enemy.has_common_ailment(&"poison") or blocking_enemy.has_common_ailment(&"bleed")) and blocking_enemy.statuses.has(&"mark") and float(game.metrics.mechanic_totals.get("goblin_tactics", 0.0)) > 0.0, "goblin tactics must periodically combine poison or bleed with vulnerability")
	for projectile in tactics_projectiles:
		projectile.queue_free()
	projectile_column.set_shared_progress({&"rapid": 1}, {})
	await get_tree().process_frame

	var precision_formation := DataRegistry.get_formation(&"precision")
	var precision_placements := game.loadout.get_valid_board_placements(precision_formation).filter(func(placement: Dictionary) -> bool: return (placement.anchor as Vector2i).y == 0)
	var precision_choice := UpgradeData.new().configure(&"new_formation", "정밀 편대", "test", &"precision")
	precision_choice.board_anchor = (precision_placements[0] as Dictionary).anchor as Vector2i
	precision_choice.vertical_flip = bool((precision_placements[0] as Dictionary).vertical_flipped)
	precision_choice.placement_confirmed = true
	_check(game.loadout.apply_upgrade(precision_choice), "a precision block must install in a valid current-board region")
	var precision_slices := game.loadout.placed_formation_slices[precision_choice.placement_id] as Array
	var hitscan_column := precision_slices.filter(func(column: TowerColumn) -> bool: return column.contains_tower_type(&"pierce"))[0] as TowerColumn
	var hitscan_row := hitscan_column.row_towers.find(DataRegistry.get_tower(&"pierce"))
	hitscan_column.set_process(false)
	hitscan_column.set_physics_process(false)
	var shared_dps_before := projectile_column.get_damage_per_second(projectile_row)
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"tower_type_level", "속사 전체 Lv.2", "test", &"rapid"))
	_check(projectile_column.get_tower_level(&"rapid") == 2 and (balanced_slices[1] as TowerColumn).get_tower_level(&"rapid") == 2, "tower type upgrades must apply to every matching block slice")
	_check(projectile_column.get_damage_per_second(projectile_row) > shared_dps_before, "shared tower type upgrade must increase matching formation DPS")
	var build_summary := game.loadout.get_build_summary()
	_check(build_summary.contains("편대") and build_summary.contains("종류 강화") and build_summary.contains("\n"), "run HUD summary must expose formations and shared upgrade states at a glance")
	_check(game.hud.build_label.text == build_summary, "HUD must refresh immediately after formation and type upgrades")
	var effect_refreshes := {"count": 0}
	game.loadout.effects_changed.connect(func(_global: Array) -> void: effect_refreshes.count += 1)
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"status_upgrade", "독 강화", "독 자체 피해 강화", &"poison"))
	_check(effect_refreshes.count == 1, "each status upgrade must rebuild the effect HUD exactly once")
	_check(game.loadout.get_selected_global_effects().size() == 1 and game.hud.global_count.text == "1", "selected status upgrades must refresh their separate effect panel immediately")
	_check(game.hud.global_list.get_child_count() == 1 and game.hud.get_node_or_null("EffectPanels/DevicePanel") == null, "the effect HUD must render active status effects without the retired module panel")
	_check(game.hud.global_list.find_children("*", "Label", true, false).is_empty(), "status effects must remain clean icon-only chips")
	game.target_cursor.warp_to(Vector2(game.target_cursor.global_position.x, game.battlefield.get_lane_y(hitscan_row)))
	var blocking_health_before_hitscan := blocking_enemy.current_health
	var aimed_health_before_hitscan := aimed_enemy.current_health
	game._on_tower_attack_requested(hitscan_column, hitscan_row)
	_check(blocking_enemy.current_health < blocking_health_before_hitscan or aimed_enemy.current_health < aimed_health_before_hitscan, "target-directed pierce hitscan damage must apply immediately")
	_check(get_tree().get_nodes_in_group(&"projectiles").is_empty(), "hitscan tower must not create a projectile")
	blocking_enemy.active = false
	aimed_enemy.active = false
	hitscan_column.set_shared_progress({&"pierce": 7}, {})
	var base_orc_range := hitscan_column.get_attack_range(hitscan_row)
	var base_orc_interval := hitscan_column.get_attack_interval(hitscan_row)
	hitscan_column.set_shared_progress({&"pierce": 7}, {&"pierce": &"pierce_power"})
	_check(hitscan_column.get_attack_range(hitscan_row) >= base_orc_range * 1.89 and hitscan_column.get_attack_interval(hitscan_row) > base_orc_interval, "longbow orcs must gain major range while accepting a slower firing cycle")
	hitscan_column.set_shared_progress({&"pierce": 7}, {&"pierce": &"pierce_execute"})
	hitscan_column.attack_counts[hitscan_row] = 4
	var power_shot_target := game._spawn_enemy(DataRegistry.enemies[3], hitscan_column.get_attack_origin(hitscan_row) + Vector2(180.0, 0.0), hitscan_row, 100.0, 2.0)
	var power_shot_wide_target := game._spawn_enemy(DataRegistry.enemies[3], hitscan_column.get_attack_origin(hitscan_row) + Vector2(190.0, 45.0), hitscan_row, 100.0, 1.0)
	power_shot_target.set_process(false)
	power_shot_target.set_physics_process(false)
	power_shot_wide_target.set_process(false)
	power_shot_wide_target.set_physics_process(false)
	var power_shot_wide_health := power_shot_wide_target.current_health
	game._on_tower_attack_requested(hitscan_column, hitscan_row)
	_check(power_shot_wide_target.current_health < power_shot_wide_health and float(game.metrics.mechanic_totals.get("orc_power_shot", 0.0)) > 0.0, "every fifth high-orc attack must widen into a power shot that catches off-axis enemies (health %.1f -> %.1f, events %.1f)" % [power_shot_wide_health, power_shot_wide_target.current_health, float(game.metrics.mechanic_totals.get("orc_power_shot", 0.0))])
	for enemy in [power_shot_target, power_shot_wide_target]:
		enemy.active = false
		enemy.queue_free()
	hitscan_column.set_shared_progress({&"pierce": 7}, {&"pierce": &"pierce_rail"})
	var explosive_target := game._spawn_enemy(DataRegistry.enemies[3], hitscan_column.get_attack_origin(hitscan_row) + Vector2(170.0, 0.0), hitscan_row, 100.0, 2.0)
	explosive_target.set_process(false)
	explosive_target.set_physics_process(false)
	var explosive_health := explosive_target.current_health
	game._on_tower_attack_requested(hitscan_column, hitscan_row)
	_check(is_equal_approx(explosive_target.current_health, explosive_health), "explosive-rune arrows must attach without immediate piercing damage")
	get_tree().paused = true
	await get_tree().create_timer(0.35, true, false, true).timeout
	_check(is_equal_approx(explosive_target.current_health, explosive_health), "delayed explosive arrows must not resolve while combat is paused")
	get_tree().paused = false
	await get_tree().create_timer(0.35, true, false, true).timeout
	_check(explosive_target.current_health < explosive_health and float(game.metrics.mechanic_totals.get("orc_explosive_arrow", 0.0)) > 0.0, "explosive-rune arrows must detonate after their configured delay and deal area damage (health %.1f -> %.1f, events %.1f)" % [explosive_health, explosive_target.current_health, float(game.metrics.mechanic_totals.get("orc_explosive_arrow", 0.0))])
	explosive_target.active = false
	explosive_target.queue_free()
	hitscan_column.set_shared_progress({&"pierce": 1}, {})
	blocking_enemy.active = false
	aimed_enemy.active = false
	_check(blocking_enemy not in game.spatial_index.get_active_enemies() and aimed_enemy not in game.spatial_index.get_active_enemies(), "inactive enemies must leave spatial index query results without a scene-tree scan")
	blocking_enemy.queue_free()
	aimed_enemy.queue_free()
	await get_tree().process_frame

	var area_column := _create_test_column(game, &"mixed", [&"area"])
	var area_tower := area_column.get_tower_data(0)
	var area_origin := area_column.get_attack_origin(0)
	var density_solitary := game._spawn_enemy(DataRegistry.enemies[3], area_origin + Vector2(55.0, 0.0), 0, 100.0, 1.0)
	var density_cluster_a := game._spawn_enemy(DataRegistry.enemies[3], area_origin + Vector2(230.0, 0.0), 0, 100.0, 1.0)
	var density_cluster_b := game._spawn_enemy(DataRegistry.enemies[3], area_origin + Vector2(270.0, 18.0), 0, 100.0, 1.0)
	for enemy in [density_solitary, density_cluster_a, density_cluster_b]:
		enemy.set_process(false)
		enemy.set_physics_process(false)
	var density_target := game._select_projectile_target([density_solitary, density_cluster_a, density_cluster_b], area_column, area_tower)
	_check(density_target in [density_cluster_a, density_cluster_b], "area tower must target the densest enemy cluster instead of always choosing the closest enemy")
	var direct_density_target := game.targeting_service.density_queries.select_densest(
		[density_solitary, density_cluster_a, density_cluster_b],
		area_tower.area_radius,
		game.core.global_position
	)
	_check(direct_density_target == density_target, "density target selection must be owned by the reusable density query service")
	_check(game.targeting_service.density_queries.count_neighbors(density_cluster_a, [density_solitary, density_cluster_a, density_cluster_b], area_tower.area_radius) == 2, "density service must count only enemies inside the requested radius")
	var area_a_health := density_cluster_a.current_health
	var area_b_health := density_cluster_b.current_health
	var solitary_health := density_solitary.current_health
	game._spawn_tower_projectile(area_column, 0, area_tower, density_target.global_position, area_column.get_damage(0))
	var area_projectiles := get_tree().get_nodes_in_group(&"projectiles")
	_check(area_projectiles.size() == 1, "area tower must launch one visible artillery shell")
	if not area_projectiles.is_empty():
		var area_projectile := area_projectiles[0] as Projectile
		area_projectile.speed = 10000.0
		area_projectile._physics_process(1.0)
	_check(density_cluster_a.current_health < area_a_health and density_cluster_b.current_health < area_b_health and is_equal_approx(density_solitary.current_health, solitary_health), "area shell must land on its dense target cluster without being blocked by a nearer enemy")
	_check(get_tree().get_nodes_in_group(&"combat_effects").any(func(effect: CombatEffect) -> bool: return effect.effect_style == &"zone"), "area impact must leave a persistent concentric zone effect")
	for enemy in [density_solitary, density_cluster_a, density_cluster_b]:
		enemy.active = false
		enemy.queue_free()
	area_column.queue_free()
	var row_area_column := _create_test_column(game, &"barrage", [&"", &"area"])
	var skeleton_branch_rng_state := RunRng.rng.state
	row_area_column.set_shared_progress({&"area": 7}, {&"area": &"area_power"})
	var row_area_tower := row_area_column.get_tower_data(1)
	var row_area_origin := row_area_column.get_attack_origin(1)
	var row_area_primary := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), row_area_origin + Vector2(160.0, 0.0), 1, 100.0, 5.0)
	row_area_primary.set_process(false)
	row_area_primary.set_physics_process(false)
	var area_payload := {"column": row_area_column, "tower": row_area_tower, "row_index": 1, "behavior": &"area", "damage": row_area_column.get_damage(1), "area_radius": row_area_tower.area_radius * row_area_column.get_range_multiplier(1), "origin": row_area_origin}
	game._on_projectile_impacted(null, row_area_primary.global_position, area_payload)
	_check(row_area_primary.has_common_ailment(&"burn") and row_area_primary.get_common_ailment_stacks(&"burn") == 1 and float(game.metrics.mechanic_totals.get("skeleton_fire_zone_burn", 0.0)) > 0.0, "one firebomb zone must apply burn to each enemy exactly once")
	var paused_zone_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), row_area_primary.global_position + Vector2(8.0, 0.0), 1, 100.0, 5.0)
	paused_zone_target.set_process(false)
	paused_zone_target.set_physics_process(false)
	get_tree().paused = true
	await get_tree().create_timer(0.3, true, false, true).timeout
	_check(not paused_zone_target.has_common_ailment(&"burn"), "persistent firebomb zones must not apply new burns while combat is paused")
	get_tree().paused = false
	await get_tree().create_timer(0.3, true, false, true).timeout
	_check(paused_zone_target.has_common_ailment(&"burn"), "persistent firebomb zones must resume after combat is unpaused")
	_check(row_area_primary.get_common_ailment_stacks(&"burn") == 1, "a persistent firebomb zone must not reapply burn indefinitely to the same enemy")
	paused_zone_target.active = false
	paused_zone_target.queue_free()
	row_area_primary.active = false
	row_area_primary.queue_free()
	row_area_column.set_shared_progress({&"area": 7}, {&"area": &"area_shrapnel"})
	var bone_shard_rng_state := RunRng.rng.state
	game._on_projectile_impacted(null, row_area_origin + Vector2(160.0, 0.0), area_payload)
	var bone_shards := get_tree().get_nodes_in_group(&"projectiles").filter(func(projectile: Projectile) -> bool: return projectile.payload.get("behavior") == &"area_shard")
	_check(bone_shards.size() == 8 and bone_shards.all(func(projectile: Projectile) -> bool: return projectile.remaining_hits == 1), "bone-bomb development must emit exactly eight random single-hit projectiles at level seven")
	for shard in bone_shards:
		shard.queue_free()
	RunRng.rng.state = bone_shard_rng_state
	await get_tree().process_frame
	row_area_column.set_shared_progress({&"area": 7}, {&"area": &"area_stun"})
	var lightning_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), row_area_origin + Vector2(160.0, 0.0), 1, 100.0, 5.0)
	lightning_target.set_process(false)
	lightning_target.set_physics_process(false)
	var lightning_health := lightning_target.current_health
	game._on_projectile_impacted(null, lightning_target.global_position, area_payload)
	_check(lightning_target.current_health < lightning_health and lightning_target.has_common_ailment(&"shock") and float(game.metrics.mechanic_totals.get("skeleton_lightning_strike", 0.0)) > 0.0, "lightning collaboration must add impact damage and common shock stacks")
	lightning_target.active = false
	lightning_target.queue_free()
	row_area_column.queue_free()
	RunRng.rng.state = skeleton_branch_rng_state

	var slow_column := _create_test_column(game, &"cryo_net", [&"slow"])
	var slow_blocker := game._spawn_enemy(DataRegistry.enemies[3], slow_column.get_attack_origin(0) + Vector2(55.0, 0.0), 0, 100.0, 1.0)
	var slow_enemy := game._spawn_enemy(DataRegistry.enemies[3], slow_column.get_attack_origin(0) + Vector2(110.0, 0.0), 0, 100.0, 1.0)
	var slow_splash_enemy := game._spawn_enemy(DataRegistry.enemies[3], slow_column.get_attack_origin(0) + Vector2(20.0, 180.0), 1, 100.0, 1.0)
	slow_blocker.set_process(false)
	slow_blocker.set_physics_process(false)
	slow_enemy.set_process(false)
	slow_enemy.set_physics_process(false)
	slow_splash_enemy.set_process(false)
	slow_splash_enemy.set_physics_process(false)
	var slow_blocker_health := slow_blocker.current_health
	game._on_tower_attack_requested(slow_column, 0)
	_check(is_equal_approx(slow_blocker.current_health, slow_blocker_health) and slow_blocker.statuses.has(&"slow"), "slow aura must apply control without direct damage")
	_check(slow_enemy.statuses.has(&"slow"), "slow aura must affect every same-row enemy in range")
	_check(slow_splash_enemy.statuses.has(&"slow"), "slow aura must affect adjacent-row enemies inside its circular range (distance %.1f / range %.1f)" % [slow_splash_enemy.global_position.distance_to(slow_column.get_attack_origin(0)), slow_column.get_attack_range(0)])
	_check(not get_tree().get_nodes_in_group(&"projectiles").any(func(projectile: Projectile) -> bool: return projectile.payload.get("behavior") == &"slow"), "slow aura must not create a locked projectile")
	for enemy in [slow_blocker, slow_enemy, slow_splash_enemy]:
		enemy.active = false
		enemy.queue_free()
	slow_column.set_shared_progress({&"slow": 7}, {&"slow": &"slow_lock"})
	slow_column.attack_counts[0] = 3
	var erosion_enemy := game._spawn_enemy(DataRegistry.enemies[0], slow_column.get_attack_origin(0) + Vector2(90.0, 0.0), 0, 100.0, 1.0)
	erosion_enemy.set_process(false)
	erosion_enemy.set_physics_process(false)
	game._on_tower_attack_requested(slow_column, 0)
	_check(erosion_enemy.statuses.has(&"stun") and float(game.metrics.mechanic_totals.get("abyss_erosion_pulse", 0.0)) > 0.0, "every fourth erosion pulse must stun through the shared control-resistance path")
	erosion_enemy.active = false
	erosion_enemy.queue_free()
	slow_column.set_shared_progress({&"slow": 7}, {})
	var base_abyss_range := slow_column.get_attack_range(0)
	slow_column.set_shared_progress({&"slow": 7}, {&"slow": &"slow_range"})
	var giant_enemy := game._spawn_enemy(DataRegistry.enemies[0], slow_column.get_attack_origin(0) + Vector2(base_abyss_range * 1.35, 0.0), 0, 100.0, 1.0)
	giant_enemy.set_process(false)
	giant_enemy.set_physics_process(false)
	game._on_tower_attack_requested(slow_column, 0)
	_check(slow_column.get_attack_range(0) >= base_abyss_range * 1.59 and giant_enemy.statuses.has(&"slow") and float(giant_enemy.statuses[&"slow"].power) > slow_column.get_tower_data(0).status_power, "giant pillar must expand the aura and intensify its slow")
	giant_enemy.active = false
	giant_enemy.queue_free()
	slow_column.set_shared_progress({&"slow": 7}, {&"slow": &"slow_power"})
	var sacrifice_origin := slow_column.get_attack_origin(0)
	var summon_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), sacrifice_origin + Vector2(80.0, 0.0), 0, 100.0, 12.0)
	summon_target.set_process(false)
	summon_target.set_physics_process(false)
	var summon_target_health := summon_target.current_health
	var abyss_key := game._abyss_sacrifice_key(slow_column, 0)
	var outside_sacrifice := game._register_abyss_sacrifice_for_column(slow_column, 0, sacrifice_origin + Vector2(slow_column.get_attack_range(0) + 1.0, 0.0))
	_check(not outside_sacrifice and not game.abyss_sacrifice_stacks.has(abyss_key), "defeats outside the abyss aura must not add sacrifice stacks")
	for sacrifice_index in 4:
		game._register_abyss_sacrifice_for_column(slow_column, 0, sacrifice_origin)
	var first_abyss_summon := game.summon_container.get_child(game.summon_container.get_child_count() - 1) as AbyssSummon
	first_abyss_summon.set_process(false)
	first_abyss_summon.set_physics_process(false)
	_check(first_abyss_summon != null and is_equal_approx(first_abyss_summon.maximum_health, 7.0) and is_equal_approx(first_abyss_summon.attack_damage, 84.0) and is_equal_approx(first_abyss_summon.attack_interval, 1.10) and int(game.active_abyss_summons.get(abyss_key, 0)) == 1 and float(game.metrics.mechanic_totals.get("abyss_summon_created", 0.0)) > 0.0, "four nearby sacrifices must create one pace-adjusted, health-limited abyss summon")
	first_abyss_summon._physics_process(0.2)
	_check(is_equal_approx(summon_target.current_health, summon_target_health) and first_abyss_summon.current_health < first_abyss_summon.maximum_health, "abyss summons must lose health over time and move before attacking outside contact range")
	summon_target.current_health = 1.0
	first_abyss_summon._physics_process(0.2)
	_check(not summon_target.active and float(game.metrics.tower_damage.get("slow", 0.0)) > 0.0 and int(game.metrics.tower_kills.get("slow", 0)) == 1, "abyss summon contact damage and kills must belong to the source slow tower")
	for sacrifice_index in 8:
		game._register_abyss_sacrifice_for_column(slow_column, 0, sacrifice_origin)
	var second_abyss_summon := game.summon_container.get_child(game.summon_container.get_child_count() - 1) as AbyssSummon
	second_abyss_summon.set_process(false)
	second_abyss_summon.set_physics_process(false)
	var full_pool_stacks := int(game.abyss_sacrifice_stacks.get(abyss_key, 0))
	var full_pool_rejection_metric := float(game.metrics.mechanic_events.get("abyss_sacrifice_rejected_full", 0.0))
	var rejected_at_cap := true
	for sacrifice_index in 8:
		rejected_at_cap = not game._register_abyss_sacrifice_for_column(slow_column, 0, sacrifice_origin) and rejected_at_cap
	_check(int(game.active_abyss_summons.get(abyss_key, 0)) == 2 and rejected_at_cap and int(game.abyss_sacrifice_stacks.get(abyss_key, 0)) == full_pool_stacks and is_equal_approx(float(game.metrics.mechanic_events.get("abyss_sacrifice_rejected_full", 0.0)) - full_pool_rejection_metric, 8.0), "a full level-7 summon pool must reject and report extra sacrifices without building a hidden backlog")
	first_abyss_summon.force_expire()
	_check(int(game.active_abyss_summons.get(abyss_key, 0)) == 1, "an expired abyss summon must immediately return its active pool slot")
	second_abyss_summon._physics_process(second_abyss_summon.maximum_health + 0.01)
	_check(int(game.active_abyss_summons.get(abyss_key, 0)) == 0 and float(game.metrics.mechanic_events.get("abyss_summon_expired", 0.0)) >= 2.0, "depleted summon health must expire the creature, return its pool slot, and report the lifecycle")
	var candidate_abyss_summon := AbyssSummon.new()
	game.summon_container.add_child(candidate_abyss_summon)
	candidate_abyss_summon.position = sacrifice_origin
	var candidate_abyss_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), sacrifice_origin + Vector2(24.0, 0.0), 0, 100.0, 2.0)
	candidate_abyss_target.set_process(false)
	candidate_abyss_target.set_physics_process(false)
	var candidate_abyss_health := candidate_abyss_target.current_health
	var candidate_abyss_damage_metric := float(game.metrics.mechanic_totals.get("kasuha_summon_damage", 0.0))
	game._on_candidate_abyss_summon_attack(candidate_abyss_summon, candidate_abyss_target, 36.0)
	_check(candidate_abyss_target.current_health < candidate_abyss_health and float(game.metrics.mechanic_totals.get("kasuha_summon_damage", 0.0)) > candidate_abyss_damage_metric, "candidate abyss summons must apply core-area damage and record their actual dealt damage")
	candidate_abyss_target.active = false
	candidate_abyss_target.queue_free()
	candidate_abyss_summon.queue_free()
	slow_column.queue_free()

	var golem_rng_state := RunRng.rng.state
	var golem_column := _create_test_column(game, &"cryo_net", [&"", &"", &"", &"rubber_golem"])
	var golem_row := 3
	var golem_base_origin := golem_column.get_base_attack_origin(golem_row)
	var golem_enemy := game._spawn_enemy(DataRegistry.enemies[0], golem_base_origin + Vector2(60.0, 0.0), golem_row, 100.0, 1.0)
	golem_enemy.set_process(false)
	golem_enemy.set_physics_process(false)
	var golem_enemy_distance := golem_enemy.position.distance_to(golem_enemy.target_position)
	game._on_tower_attack_requested(golem_column, golem_row)
	var advanced_golem_origin := golem_column.get_attack_origin(golem_row)
	_check(advanced_golem_origin.distance_to(golem_base_origin) > 0.0 and advanced_golem_origin.distance_to(golem_base_origin) <= golem_column.get_golem_activity_radius(golem_row), "rubber golem must advance toward danger while remaining inside its activity radius")
	_check(golem_enemy.position.distance_to(golem_enemy.target_position) > golem_enemy_distance and float(game.metrics.mechanic_totals.get("rubber_golem_control_success", 0.0)) > 0.0, "rubber golem contact must apply control and record its successful displacement")
	var distance_before_return := golem_column.get_attack_origin(golem_row).distance_to(golem_base_origin)
	golem_column._physics_process(0.5)
	_check(golem_column.get_attack_origin(golem_row).distance_to(golem_base_origin) < distance_before_return, "an idle rubber golem must start returning to its installation cell")
	var base_activity_radius := golem_column.get_golem_activity_radius(golem_row)
	var base_control_radius := golem_column.get_golem_control_radius(golem_row)
	golem_column.set_shared_progress({&"rubber_golem": 7}, {&"rubber_golem": &"golem_elastic"})
	_check(golem_column.apply_golem_recoil(golem_row, golem_base_origin + Vector2(100.0, 0.0), 48.0) > 0.0, "high-elasticity specialization must recoil the golem inside its activity boundary")
	golem_column.set_shared_progress({&"rubber_golem": 7}, {&"rubber_golem": &"golem_heavy"})
	_check(golem_column.get_golem_activity_radius(golem_row) < base_activity_radius and golem_column.get_golem_control_radius(golem_row) > base_control_radius, "heavy specialization must trade movement territory for a wider control impact")
	golem_enemy.active = false
	golem_enemy.queue_free()
	golem_column.queue_free()
	RunRng.rng.state = golem_rng_state

	var knockback_column := _create_test_column(game, &"mixed", [&"", &"", &"", &"knockback"])
	var knockback_tower := knockback_column.get_tower_data(3)
	var knockback_origin := knockback_column.get_attack_origin(3)
	var knockback_enemy := game._spawn_enemy(DataRegistry.enemies[0], knockback_origin + Vector2(240.0, 0.0), 3, 100.0, 1.0)
	var knockback_wave_enemy := game._spawn_enemy(DataRegistry.enemies[0], knockback_origin + Vector2(250.0, 25.0), 3, 100.0, 1.0)
	knockback_enemy.set_process(false)
	knockback_enemy.set_physics_process(false)
	knockback_wave_enemy.set_process(false)
	knockback_wave_enemy.set_physics_process(false)
	knockback_enemy.position.x = knockback_origin.x + 120.0
	knockback_wave_enemy.position = knockback_origin + Vector2(100.0, 25.0)
	var knockback_distance := knockback_enemy.position.distance_to(knockback_enemy.target_position)
	var knockback_wave_distance := knockback_wave_enemy.position.distance_to(knockback_wave_enemy.target_position)
	game._on_tower_attack_requested(knockback_column, 3)
	_check(knockback_enemy.position.distance_to(knockback_enemy.target_position) > knockback_distance and knockback_wave_enemy.position.distance_to(knockback_wave_enemy.target_position) > knockback_wave_distance, "knockback tower orbiting saws must push every target radially away from the core")
	_check(knockback_enemy.last_knockback_displacement >= knockback_tower.status_power * 0.95, "a normal enemy hit by a saw must receive the full documented knockback distance")
	_check(knockback_enemy.knockback_flash > 0.9 and knockback_enemy.hit_feedback_profile == &"knockback", "knockback must leave a directional ghost and kinetic recoil profile on the enemy")
	_check(get_tree().get_nodes_in_group(&"combat_effects").any(func(effect: CombatEffect) -> bool: return effect.effect_style == &"hit_knockback"), "knockback damage must spawn its dedicated directional impact effect")
	var level_one_saw_speed := knockback_column.get_saw_rotation_speed(3)
	_check(knockback_column.get_saw_blade_count(3) == 2 and level_one_saw_speed > 0.0 and is_equal_approx(knockback_column.get_saw_orbit_radius(3) + 17.0, knockback_column.get_attack_range(3)), "saw tower must expose a persistent blade count, rotation speed, and orbit radius")
	knockback_column.set_shared_progress({&"knockback": 7}, {})
	_check(knockback_column.get_saw_blade_count(3) == 4 and knockback_column.get_saw_rotation_speed(3) > level_one_saw_speed and knockback_column.get_saw_contact_damage(3) > 0.0, "saw tower upgrades must add blades at levels 3 and 6 while increasing rotation and contact damage")
	_check(knockback_enemy.has_common_ailment(&"bleed"), "saw contact must apply its innate bleed ailment")
	for enemy in [knockback_enemy, knockback_wave_enemy]:
		enemy.active = false
		enemy.queue_free()
	var standard_saw_radius := knockback_column.get_saw_blade_radius(3)
	var standard_saw_speed := knockback_column.get_saw_rotation_speed(3)
	knockback_column.set_shared_progress({&"knockback": 7}, {&"knockback": &"push_mark"})
	_check(knockback_column.get_saw_blade_count(3) == 1 and knockback_column.get_saw_blade_radius(3) >= standard_saw_radius * 2.0 and knockback_column.get_saw_rotation_speed(3) > standard_saw_speed, "large evangelism chassis must render one substantially larger, faster saw")
	knockback_column.set_shared_progress({&"knockback": 7}, {&"knockback": &"push_wave"})
	_check(knockback_column.get_saw_blade_count(3) == 8 and float(knockback_column.get_branch_modifiers(&"knockback").push) < 1.0, "blood chassis must cover eight angles while reducing per-contact knockback")
	knockback_column.set_shared_progress({&"knockback": 7}, {&"knockback": &"push_force"})
	knockback_column.attack_counts[3] = 5
	var ki2_branch_rng_state := RunRng.rng.state
	var turbo_target := game._spawn_enemy(DataRegistry.enemies[0], knockback_origin + Vector2(100.0, 0.0), 3, 100.0, 3.0)
	turbo_target.set_process(false)
	turbo_target.set_physics_process(false)
	game._on_tower_attack_requested(knockback_column, 3)
	_check(knockback_column.is_row_disabled(3) and not knockback_column.is_row_disabled(0) and float(game.metrics.mechanic_totals.get("ki2_turbo_overheat", 0.0)) > 0.0, "turbo KI-II must overheat only its own row after the configured attack cycle")
	turbo_target.active = false
	turbo_target.queue_free()
	RunRng.rng.state = ki2_branch_rng_state
	knockback_column.queue_free()

	var execution_column := _create_test_column(game, &"execution", [&"execute", &"mark"])
	var execution_origin := execution_column.get_attack_origin(0)
	var execute_high := game._spawn_enemy(DataRegistry.enemies[3], execution_origin + Vector2(120.0, 0.0), 0, 100.0, 1.0)
	var execute_low := game._spawn_enemy(DataRegistry.enemies[3], execution_origin + Vector2(150.0, 0.0), 0, 100.0, 1.0)
	execute_high.set_process(false)
	execute_high.set_physics_process(false)
	execute_low.set_process(false)
	execute_low.set_physics_process(false)
	execute_high.set_execute_threshold(0.10)
	execute_low.set_execute_threshold(0.10)
	_check(is_equal_approx(execute_high.execute_threshold_ratio, 0.10), "an installed execute tower must expose its 10% execution threshold on enemy health bars")
	execute_low.current_health = execute_low.get_max_health() * 0.05
	_check(not execute_high.needs_continuous_redraw() and execute_low.needs_continuous_redraw(), "execute indicators must animate only after health enters the visible execution threshold")
	var execute_high_health := execute_high.current_health
	var execute_low_health := execute_low.current_health
	game._on_tower_attack_requested(execution_column, 0)
	_check(execute_high.current_health < execute_high_health and execute_low.active and is_equal_approx(execute_low.current_health, execute_low_health), "troll sniper must honor its highest-health targeting rule instead of diverting to a low-health execution target")
	_check(get_tree().get_nodes_in_group(&"combat_effects").any(func(effect: CombatEffect) -> bool: return effect.effect_style == &"hit_execute"), "execute tower must create its dedicated crossed-cut hit silhouette")
	for enemy in [execute_high, execute_low]:
		enemy.active = false
		enemy.queue_free()
	execution_column.set_shared_progress({&"execute": 7}, {})
	var base_troll_interval := execution_column.get_attack_interval(0)
	execution_column.set_shared_progress({&"execute": 7}, {&"execute": &"execute_power"})
	_check(execution_column.get_attack_interval(0) < base_troll_interval * 0.88, "loader specialization must shorten troll sniper reload while retaining only soft-capped overflow speed")
	execution_column.set_shared_progress({&"execute": 7}, {&"execute": &"execute_threshold"})
	var armor_primary := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), execution_origin + Vector2(190.0, 0.0), 0, 100.0, 3.0)
	var armor_collateral := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), execution_origin + Vector2(95.0, 16.0), 0, 100.0, 1.0)
	armor_primary.set_process(false)
	armor_primary.set_physics_process(false)
	armor_collateral.set_process(false)
	armor_collateral.set_physics_process(false)
	var armor_collateral_health := armor_collateral.current_health
	game._on_tower_attack_requested(execution_column, 0)
	_check(armor_collateral.current_health < armor_collateral_health, "armor-piercing troll rounds must retain a main target while damaging enemies along the firing path")
	for enemy in [armor_primary, armor_collateral]:
		enemy.active = false
		enemy.queue_free()
	execution_column.set_shared_progress({&"execute": 7}, {&"execute": &"execute_cycle"})
	var ricochet_primary := game._spawn_enemy(DataRegistry.enemies[3], execution_origin + Vector2(150.0, 0.0), 0, 100.0, 4.0)
	var ricochet_targets: Array[Enemy] = []
	for offset in [Vector2(185.0, 24.0), Vector2(220.0, -18.0), Vector2(255.0, 20.0)]:
		var ricochet_target := game._spawn_enemy(DataRegistry.enemies[3], execution_origin + offset, 0, 100.0, 1.0)
		ricochet_target.set_process(false)
		ricochet_target.set_physics_process(false)
		ricochet_targets.append(ricochet_target)
	ricochet_primary.set_process(false)
	ricochet_primary.set_physics_process(false)
	var ricochet_healths := ricochet_targets.map(func(enemy: Enemy) -> float: return enemy.current_health)
	game._on_tower_attack_requested(execution_column, 0)
	_check(ricochet_targets.all(func(enemy: Enemy) -> bool: return enemy.current_health < float(ricochet_healths[ricochet_targets.find(enemy)])), "ricochet expert must hit up to three distinct nearby enemies with diminishing damage")
	ricochet_primary.active = false
	ricochet_primary.queue_free()
	for enemy in ricochet_targets:
		enemy.active = false
		enemy.queue_free()
	execution_column.set_shared_progress({&"execute": 1}, {})

	var mark_origin := execution_column.get_attack_origin(1)
	var mark_high := game._spawn_enemy(DataRegistry.enemies[3], mark_origin + Vector2(120.0, 0.0), 1, 100.0, 1.0)
	var mark_low := game._spawn_enemy(DataRegistry.enemies[3], mark_origin + Vector2(150.0, 0.0), 1, 100.0, 1.0)
	mark_high.set_process(false)
	mark_high.set_physics_process(false)
	mark_low.set_process(false)
	mark_low.set_physics_process(false)
	mark_low.current_health *= 0.5
	game._on_tower_attack_requested(execution_column, 1)
	_check(mark_high.statuses.has(&"mark") and not mark_low.statuses.has(&"mark"), "mark tower must apply vulnerability to the highest-health target")
	_check(get_tree().get_nodes_in_group(&"combat_effects").any(func(effect: CombatEffect) -> bool: return effect.effect_style == &"sigil"), "mark tower must create a persistent rotating target sigil")
	for enemy in [mark_high, mark_low]:
		enemy.active = false
		enemy.queue_free()
	execution_column.set_shared_progress({&"mark": 7}, {&"mark": &"mark_amp"})
	var fear_target := game._spawn_enemy(DataRegistry.enemies[0], mark_origin + Vector2(120.0, 0.0), 1, 100.0, 4.0)
	fear_target.set_process(false)
	fear_target.set_physics_process(false)
	game._on_tower_attack_requested(execution_column, 1)
	_check(fear_target.statuses.has(&"mark") and fear_target.statuses.has(&"slow") and float(fear_target.statuses[&"mark"].remaining) >= 7.9, "shock-and-fear must apply a long vulnerability and a slowing hex to the same target")
	fear_target.active = false
	fear_target.queue_free()
	execution_column.set_shared_progress({&"mark": 7}, {&"mark": &"mark_power"})
	var weakness_target := game._spawn_enemy(DataRegistry.enemies[0], mark_origin + Vector2(120.0, 0.0), 1, 100.0, 4.0)
	weakness_target.set_process(false)
	weakness_target.set_physics_process(false)
	game._on_tower_attack_requested(execution_column, 1)
	_check(float(weakness_target.statuses.get(&"mark", {}).get("power", 0.0)) >= 0.61 and float(weakness_target.statuses.get(&"mark", {}).get("remaining", 99.0)) <= 2.21, "weakness exposure must apply its short high-amplification mark at runtime")
	weakness_target.active = false
	weakness_target.queue_free()
	execution_column.set_shared_progress({&"mark": 7}, {})
	var base_hex_interval := execution_column.get_attack_interval(1)
	execution_column.set_shared_progress({&"mark": 7}, {&"mark": &"mark_spread"})
	var shift_target := game._spawn_enemy(DataRegistry.enemies[0], mark_origin + Vector2(120.0, 0.0), 1, 100.0, 4.0)
	shift_target.set_process(false)
	shift_target.set_physics_process(false)
	game._on_tower_attack_requested(execution_column, 1)
	_check(execution_column.get_attack_interval(1) <= base_hex_interval * 0.88 and float(shift_target.statuses.get(&"mark", {}).get("remaining", 0.0)) >= 7.4, "shift work must rotate long marks at its soft-capped accelerated cadence")
	shift_target.active = false
	shift_target.queue_free()
	execution_column.queue_free()

	var chain_column := _create_test_column(game, &"cascade", [&"chain", &"chain", &"slow", &"chain"])
	var relay_test_path := game.chain_network_attack_execution_service.build_relay_path(chain_column, 0, game.loadout.columns)
	var slow_tower_origin := chain_column.get_attack_origin(2)
	var distant_chain_origin := chain_column.get_attack_origin(3)
	var chain_attack_range_before_bonus := chain_column.get_attack_range(0)
	_check(relay_test_path.size() == 2 and slow_tower_origin not in relay_test_path and distant_chain_origin not in relay_test_path, "chain relay paths must contain only distance-reachable chain towers and exclude unrelated or disconnected nodes")
	chain_column.set_defense_stat_context(DefenseStatResolver.new(), {&"power": 0.0, &"speed": 0.0, &"range": 160.0})
	var expanded_relay_path := game.chain_network_attack_execution_service.build_relay_path(chain_column, 0, game.loadout.columns)
	_check(expanded_relay_path.size() == 3 and distant_chain_origin in expanded_relay_path and is_equal_approx(chain_column.get_attack_range(0), chain_attack_range_before_bonus), "chain RANGE must expand link reach without changing its first-target acquisition range (base path %d, expanded %d, link %.1f, gap %.1f, attack %.1f→%.1f)" % [relay_test_path.size(), expanded_relay_path.size(), chain_column.get_chain_link_range(0), chain_column.get_attack_origin(1).distance_to(distant_chain_origin), chain_attack_range_before_bonus, chain_column.get_attack_range(0)])
	chain_column.set_defense_stat_context(DefenseStatResolver.new(), {&"power": 0.0, &"speed": 0.0, &"range": 0.0})
	var relay_midpoint := (chain_column.get_attack_origin(0) + chain_column.get_attack_origin(1)) * 0.5
	var chain_primary := game._spawn_enemy(DataRegistry.enemies[3], relay_midpoint + Vector2(8.0, 0.0), 0, 100.0, 1.0)
	chain_primary.set_process(false)
	chain_primary.set_physics_process(false)
	var chain_primary_health := chain_primary.current_health
	game._on_tower_attack_requested(chain_column, 0)
	_check(chain_primary.current_health < chain_primary_health, "chain tower must damage enemies touching the chain-tower-only relay path")
	_check(get_tree().get_nodes_in_group(&"combat_effects").any(func(effect: CombatEffect) -> bool: return effect.effect_style == &"chain" and effect.path_points.size() == 2), "chain tower must render the complete path between chain towers without unrelated relay nodes")
	chain_primary.active = false
	chain_primary.queue_free()
	var chain_branch_rng_state := RunRng.rng.state
	chain_column.set_shared_progress({&"chain": 7}, {})
	_check(is_zero_approx(chain_column.get_chain_network_damage_multiplier(0, 1)) and is_equal_approx(chain_column.get_chain_network_damage_multiplier(0, 2), 1.0) and is_equal_approx(chain_column.get_chain_network_damage_multiplier(0, 6), 1.32) and is_equal_approx(chain_column.get_chain_network_damage_multiplier(0, 12), 1.32), "chain network growth must require two relays and cap after four additional relay nodes")
	var base_chain_interval := chain_column.get_attack_interval(0)
	var base_chain_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), relay_midpoint + Vector2(8.0, 0.0), 0, 100.0, 10.0)
	base_chain_target.set_process(false)
	base_chain_target.set_physics_process(false)
	var base_chain_health := base_chain_target.current_health
	game._on_tower_attack_requested(chain_column, 0)
	var base_chain_loss := base_chain_health - base_chain_target.current_health
	base_chain_target.active = false
	base_chain_target.queue_free()
	chain_column.set_shared_progress({&"chain": 7}, {&"chain": &"chain_power"})
	_check(is_equal_approx(chain_column.get_chain_network_damage_multiplier(0, 6), 1.64), "high-voltage specialization must raise the capped six-node network multiplier to 1.64")
	var voltage_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), relay_midpoint + Vector2(8.0, 0.0), 0, 100.0, 10.0)
	voltage_target.set_process(false)
	voltage_target.set_physics_process(false)
	var voltage_health := voltage_target.current_health
	game._on_tower_attack_requested(chain_column, 0)
	var voltage_loss := voltage_health - voltage_target.current_health
	_check(voltage_loss > base_chain_loss * 1.5, "high-voltage discharge must materially exceed the two-node base network damage")
	voltage_target.active = false
	voltage_target.queue_free()
	chain_column.set_shared_progress({&"chain": 7}, {&"chain": &"chain_cycle"})
	var resonance_target := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), relay_midpoint + Vector2(8.0, 0.0), 0, 100.0, 10.0)
	resonance_target.set_process(false)
	resonance_target.set_physics_process(false)
	var resonance_health := resonance_target.current_health
	game._on_tower_attack_requested(chain_column, 0)
	var resonance_loss := resonance_health - resonance_target.current_health
	_check(resonance_loss > base_chain_loss * 1.4 and float(game.metrics.mechanic_totals.get("chain_resonance_return", 0.0)) > 0.0, "resonance circuit must add a measurable reverse beam without replacing the forward network")
	resonance_target.active = false
	resonance_target.queue_free()
	chain_column.set_shared_progress({&"chain": 7}, {&"chain": &"chain_mark"})
	_check(chain_column.get_attack_interval(0) <= base_chain_interval * 0.92, "superconducting core must accelerate beam cadence within the shared soft cap without changing network topology")
	RunRng.rng.state = chain_branch_rng_state
	chain_column.queue_free()
	await get_tree().process_frame

	game.loadout.apply_upgrade(UpgradeData.new().configure(&"tower_type_level", "속사 전체 Lv.3", "test", &"rapid"))
	var specialization_entries := game.loadout.get_specialization_entry_choices()
	var rapid_entries := specialization_entries.filter(func(choice: UpgradeData) -> bool: return choice.category == &"tower_specialization_entry" and choice.data_id == &"rapid")
	_check(rapid_entries.size() == 1, "a level 3 tower must create one optional specialization entry card")
	game.loadout.cursor_state.current_level = 3
	var rapid_entry_key := game.loadout.specialization_policy.entry_key(rapid_entries[0])
	var cursor_entry := game.loadout.get_specialization_entry_choices().filter(func(choice: UpgradeData) -> bool: return choice.category == &"cursor_specialization_entry")[0] as UpgradeData
	var cursor_entry_key := game.loadout.specialization_policy.entry_key(cursor_entry)
	game.loadout.specialization_entry_waits = {rapid_entry_key: 0, cursor_entry_key: 3}
	game.loadout.specialization_offer_misses = LoadoutManager.SPECIALIZATION_PITY_MISSES
	var prioritized_specialization_choices := game.loadout.generate_upgrade_choices()
	_check(prioritized_specialization_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"cursor_specialization_entry"), "specialization offers must prioritize the candidate that has waited the longest")
	_check(int(game.loadout.specialization_entry_waits.get(rapid_entry_key, 0)) > int(game.loadout.specialization_entry_waits.get(cursor_entry_key, 0)), "offering one specialization must rotate priority toward the remaining candidates")
	game.loadout.cursor_state.current_level = 1
	game.loadout.specialization_entry_waits.clear()
	game.loadout.specialization_offer_misses = LoadoutManager.SPECIALIZATION_PITY_MISSES
	var mixed_specialization_choices := game.loadout.generate_upgrade_choices()
	_check(mixed_specialization_choices.size() == 3 and mixed_specialization_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"tower_specialization_entry") and mixed_specialization_choices.any(func(choice: UpgradeData) -> bool: return not game.loadout.is_specialization_entry(choice)), "a specialization entry must appear alongside ordinary level-up choices instead of replacing all three cards")
	_check(mixed_specialization_choices.any(func(choice: UpgradeData) -> bool: return choice.category in [&"core_level", &"cursor_level"]), "status and specialization offers must preserve the dedicated core-or-cursor growth slot")
	var branch_choices := game.loadout.get_specialization_subchoices(rapid_entries[0])
	_check(branch_choices.size() == 3 and branch_choices.all(func(choice: UpgradeData) -> bool: return choice.category == &"tower_branch" and choice.description.contains("Lv.4 수치") and choice.description.contains("Lv.7 완성 수치")), "tower specialization cards must reveal three branches with quantified level-4 and level-7 effects")
	var choice_metric_probe := RunMetrics.new()
	choice_metric_probe.record_choices([rapid_entries[0]])
	choice_metric_probe.record_selection(rapid_entries[0])
	choice_metric_probe.record_choices(branch_choices)
	choice_metric_probe.record_selection(branch_choices[0])
	var choice_metric_snapshot := choice_metric_probe.upgrade_choice_metrics_snapshot()
	_check(is_equal_approx(float((choice_metric_snapshot.specialization_selection_rates as Dictionary).get("tower_specialization_entry:rapid", 0.0)), 1.0) and is_equal_approx(float((choice_metric_snapshot.specialization_selection_rates as Dictionary).get("tower_branch:%s" % branch_choices[0].data_id, 0.0)), 1.0), "specialization metrics must expose stable-ID entry and branch selection rates")
	choice_metric_probe.free()
	var rapid_level_before_submenu := game.loadout.get_tower_type_level(&"rapid")
	game.level_up_panel.show_choices(mixed_specialization_choices, game.experience.level)
	var rapid_entry_index := -1
	for index in mixed_specialization_choices.size():
		if mixed_specialization_choices[index].category == &"tower_specialization_entry" and mixed_specialization_choices[index].data_id == &"rapid":
			rapid_entry_index = index
			break
	_check(rapid_entry_index >= 0, "the mixed upgrade cards must retain the pending rapid specialization entry")
	game.level_up_panel._select(rapid_entry_index)
	var expected_subchoice_title := ConceptService.ui_text(&"level_up.subchoice_title", {&"parent": mixed_specialization_choices[rapid_entry_index].display_name, &"level": game.experience.level})
	_check(game.loadout.get_tower_type_level(&"rapid") == rapid_level_before_submenu and game.level_up_panel.choices.all(func(choice: UpgradeData) -> bool: return choice.category == &"tower_branch") and game.level_up_panel.get_node("%Title").text == expected_subchoice_title and not game.level_up_panel.reroll_button.visible, "opening the specialization submenu must not consume the upgrade or expose reroll before a branch is selected")
	game.level_up_panel.back_button.pressed.emit()
	_check(game.level_up_panel.get_node("Layout").visible and game.level_up_panel.choices == mixed_specialization_choices and not game.level_up_panel.back_button.visible and game.level_up_panel.reroll_button.visible, "specialization back navigation must restore the original three upgrade cards and their reroll control")
	game.level_up_panel._select(rapid_entry_index)
	game.loadout.apply_upgrade(branch_choices[0])
	game.level_up_panel.hide_panel()
	_check(game.loadout.get_tower_type_level(&"rapid") == 4 and game.loadout.get_tower_branch_id(&"rapid") != &"", "selecting a tower branch must activate it at level 4")
	var candidate_core_level_before := game.loadout.core_state.current_level
	_check(not game.loadout.apply_upgrade(UpgradeData.new().configure(&"core_level", "후보 Lv.2", "test", &"core")) and game.loadout.core_state.current_level == candidate_core_level_before, "a data-driven election candidate must reject the removed ordinary core-level path")
	var core_entries := game.loadout.get_specialization_entry_choices().filter(func(choice: UpgradeData) -> bool: return choice.category == &"core_specialization_entry")
	_check(core_entries.is_empty(), "a candidate growth profile must remove core specialization entries from the ordinary level-up pool")
	var core_damage_before_growth := game.loadout.get_core_damage_multiplier()
	var first_candidate_growth := game.loadout.claim_candidate_fixed_upgrade(0)
	var candidate_branch_choices := game.loadout.get_candidate_branch_choices()
	_check(first_candidate_growth != null and candidate_branch_choices.size() == 3 and game.loadout.get_core_damage_multiplier() > core_damage_before_growth, "the first boss slot must grant fixed candidate growth and expose exactly three branch cards for the second slot")
	_check(game.loadout.apply_candidate_branch(candidate_branch_choices[0]) and game.loadout.claim_candidate_fixed_upgrade(2) != null, "the second and third candidate milestones must apply one branch and the final fixed upgrade")
	var skill_probe := game._spawn_enemy(DataRegistry.get_enemy(&"armored"), Vector2(game.core.global_position.x + 120.0, game.target_cursor.global_position.y), game.target_cursor.current_sector, 1000.0, 1.0)
	skill_probe.set_process(false)
	skill_probe.set_physics_process(false)
	var skill_probe_health := skill_probe.current_health
	game._on_core_skill_requested(DataRegistry.get_core(game.loadout.core_state.id))
	var expected_skill_damage := DataRegistry.get_core(game.loadout.core_state.id).skill_damage * 1.15 * game.loadout.get_core_skill_damage_multiplier() - skill_probe.data.armor * 0.6
	_check(is_equal_approx(skill_probe_health - skill_probe.current_health, expected_skill_damage), "core active-skill damage must use the focused core-level skill multiplier in live combat")
	skill_probe.active = false
	skill_probe.queue_free()
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"cursor_level", "목표 Lv.2", "test", &"cursor"))
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"cursor_level", "목표 Lv.3", "test", &"cursor"))
	var cursor_entries := game.loadout.get_specialization_entry_choices().filter(func(choice: UpgradeData) -> bool: return choice.category == &"cursor_specialization_entry")
	_check(cursor_entries.size() == 1, "a level 3 target cursor must enter the ordinary pool through one specialization entry card")
	var cursor_branch_choices := game.loadout.get_specialization_subchoices(cursor_entries[0])
	_check(cursor_branch_choices.size() == 3 and cursor_branch_choices.all(func(choice: UpgradeData) -> bool: return choice.category == &"cursor_branch" and DataRegistry.get_specialization_branch(choice.data_id).owner_id == GameSession.selected_cursor_id), "the target specialization entry must reveal three owner-specific branches")
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"cursor_branch", "잘못된 목표 분기", "test", &"platinum_boss"))
	_check(game.loadout.cursor_state.current_level == 3 and game.loadout.cursor_state.selected_branch_id == &"", "a specialization owned by another cursor must be rejected")
	game.loadout.apply_upgrade(cursor_branch_choices[0])
	_check(game.loadout.cursor_state.current_level == 4 and game.loadout.cursor_state.selected_branch_id == &"iron_impact", "iron impact branch selection must enter level 4")
	_check(game.loadout.get_cursor_control_multiplier() > 1.6, "iron impact branch must strengthen its real knockback channel")
	var cursor_movement_before_level_5 := game.loadout.get_cursor_movement_speed_multiplier()
	game.loadout.apply_upgrade(UpgradeData.new().configure(&"cursor_level", "목표 Lv.5", "test", &"cursor"))
	_check(game.loadout.get_cursor_movement_speed_multiplier() >= cursor_movement_before_level_5 * 1.49, "target cursor level 5 must create a large movement-speed power step")
	for next_level in [6, 7]:
		game.loadout.apply_upgrade(UpgradeData.new().configure(&"cursor_level", "목표 Lv.%d" % next_level, "test", &"cursor"))
	_check(game.loadout.has_cursor_final_trait(&"iron_impact") and game.loadout.get_cursor_control_multiplier() >= 2.4, "iron level 7 must complete its own collision-control trait instead of only changing summary text")
	_check(game.loadout.get_build_summary().contains("후보 성장 3/3") and game.loadout.get_build_summary().contains("심복 L7") and game.loadout.get_build_summary().contains("완성"), "HUD build summary must identify completed candidate milestones and the retainer final trait")

	var choices := game.loadout.generate_upgrade_choices()
	_check(choices.size() == 3, "level-up generator must always return 3 choices")
	_check(not UpgradeOfferService.has_duplicate_choices(choices), "level-up generator must keep all three visible reward IDs distinct")
	var direct_generated_choices := choices.filter(func(choice: UpgradeData) -> bool: return not choice.requires_placement)
	if not direct_generated_choices.is_empty():
		game.loadout.apply_upgrade(direct_generated_choices[0])

	for enemy_index in DataRegistry.enemies.size():
		var enemy_data: EnemyData = DataRegistry.enemies[enemy_index]
		var spawn_position := game.battlefield.get_spawn_position(enemy_index % 4)
		var enemy := game._spawn_enemy(enemy_data, spawn_position, enemy_index % 4, 1.0, 1.0)
		_check(enemy != null, "enemy archetype failed to instantiate: %s" % enemy_data.id)
		if enemy != null:
			enemy.take_damage(1.0, &"test")
			_check(enemy.hit_flash > 0.9 and enemy.hit_pulse > 0.9, "enemy hits must trigger readable flash and scale feedback: %s" % enemy_data.id)
			enemy.register_hit_feedback(enemy.global_position - Vector2(20.0, 0.0), 0.6, &"rapid", Color("8fe8ff"))
			_check(enemy.hit_visual_velocity.x > 0.0 and enemy.hit_feedback_profile == &"rapid", "enemy hit feedback must recoil away from the attack source: %s" % enemy_data.id)
			enemy.take_damage(100000.0, &"test")
	await get_tree().process_frame

	game.experience.add_experience(game.experience.required_experience - game.experience.current_experience + 1.0)
	_check(game.level_up_panel.choices.size() == 3, "level-up panel did not receive choices")
	var pending_before_invalid_upgrade := game.pending_level_ups
	var invalid_runtime_choice := UpgradeData.new().configure(&"unknown_upgrade", "잘못된 강화", "test", &"missing")
	game._on_upgrade_selected(invalid_runtime_choice)
	_check(game.pending_level_ups == pending_before_invalid_upgrade and game.selecting_upgrade and get_tree().paused, "a failed runtime upgrade must keep the pending level-up and selection phase active")
	var choices_before_reroll := game._upgrade_choice_signature(game.level_up_panel.choices)
	game.level_up_panel.reroll_button.pressed.emit()
	_check(game.level_up_rerolls_remaining == GameController.LEVEL_UP_REROLL_LIMIT - 1 and game.level_up_panel.reroll_button.text.contains("2 / 3") and game._upgrade_choice_signature(game.level_up_panel.choices) != choices_before_reroll, "a level-up reroll must consume one run-limited charge and replace the current three choices")
	var blocked_speed := Engine.time_scale
	game._unhandled_input(speed_event)
	game._unhandled_input(range_event)
	game.core.skill_charge = game.core.data.skill_charge_seconds
	var blocked_skill_charge := game.core.skill_charge
	var skill_event := InputEventAction.new()
	skill_event.action = &"core_skill"
	skill_event.pressed = true
	game._unhandled_input(skill_event)
	_check(is_equal_approx(Engine.time_scale, blocked_speed) and not game.range_overlay.is_overlay_enabled() and is_equal_approx(game.core.skill_charge, blocked_skill_charge), "level-up phase must block speed, range, and core-skill input through the shared input policy")
	await get_tree().process_frame
	var preview_candidates := game.loadout.get_formation_candidates(2, 3)
	_check(not preview_candidates.is_empty(), "the current block board must expose at least one placeable two-cell formation preview fixture")
	var specialized_preview_found := false
	if not preview_candidates.is_empty():
		game.level_up_panel.show_subchoices(preview_candidates, "2칸 병력 세트", game.experience.level)
		await get_tree().process_frame
		for preview_index in game.level_up_panel.choices.size():
			if game.level_up_panel._is_formation_choice(game.level_up_panel.choices[preview_index]):
				var preview := game.level_up_panel.formation_previews[preview_index]
				specialized_preview_found = preview.visible and not preview.find_children("*", "GridContainer", true, false).is_empty() and not preview.find_children("*", "TextureRect", true, false).is_empty()
				break
		game.level_up_panel._return_to_previous_step()
	_check(specialized_preview_found, "formation cards must render their dedicated tower recipe preview")
	var visible_badges: Dictionary = {}
	for choice_index in game.level_up_panel.choices.size():
		var presentation: Dictionary = game.level_up_panel._category_presentation(game.level_up_panel.choices[choice_index].category)
		visible_badges[presentation.badge] = true
		var choice_card := game.level_up_panel.buttons[choice_index] as UiChoiceCard
		var badge_text := String(presentation.badge).trim_prefix("[").trim_suffix("]")
		_check(choice_card.eyebrow_label.text == badge_text and not choice_card.eyebrow_label.text.begins_with("%d" % (choice_index + 1)), "level-up card must display its category without a repeated top choice index")
		_check(choice_card.text.is_empty() and choice_card.title_label.text == game.level_up_panel.choices[choice_index].display_name and choice_card.title_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and choice_card.effect_label.text.begins_with("[center]"), "level-up card copy must use the centered shared ChoiceCard hierarchy")
		var detail_button := game.level_up_panel.detail_buttons[choice_index] as Button
		_check(choice_card.header_panel.custom_minimum_size.y == 132.0 and choice_card.icon_frame.custom_minimum_size == Vector2(52.0, 52.0) and choice_card.detail_rail.custom_minimum_size.y == 48.0 and choice_card.selection_panel.custom_minimum_size.y == 52.0 and detail_button.visible and detail_button.anchor_left == 0.5 and detail_button.offset_bottom == -68.0, "every level-up card must keep the same dark centered header, compact upper details action, and opposite full-width bottom selection affordance")
	_check(visible_badges.size() >= 2, "normal level-up choices must be visually separated into multiple upgrade categories")
	for preview_index in game.level_up_panel.choices.size():
		if not game.level_up_panel._is_formation_choice(game.level_up_panel.choices[preview_index]):
			var expected_body_impacts := game.level_up_panel._choice_body_impacts(game.level_up_panel.choices[preview_index])
			var preview_slots := game.level_up_panel.formation_previews[preview_index].get_children()
			_check(game.level_up_panel.formation_previews[preview_index].visible and preview_slots.size() == expected_body_impacts.size(), "every non-formation choice must render exactly its non-duplicated supplemental impact icons")
			var preview_icon_keys: Dictionary = {}
			for preview_slot_value in preview_slots:
				var preview_slot := preview_slot_value as Control
				var preview_icon_key := StringName(preview_slot.get_meta(&"impact_icon_key", &""))
				preview_icon_keys[preview_icon_key] = true
			_check(preview_icon_keys.size() == preview_slots.size(), "level-up card body impact icons must not repeat the header or one another")
	var viewport_center := game.get_viewport_rect().size * 0.5
	var panel_center := game.level_up_panel.global_position + game.level_up_panel.size * 0.5
	_check(panel_center.distance_to(viewport_center) < 2.0, "level-up overlay must fill and center on the viewport")
	_check(not game.level_up_panel.has_node("Placement"), "the retired six-column placement panel must not remain in the level-up scene")
	var first_direct_choice_index := -1
	for index in game.level_up_panel.choices.size():
		var offered_choice := game.level_up_panel.choices[index] as UpgradeData
		if not offered_choice.requires_placement and offered_choice.category != &"formation_set" and not game.loadout.is_specialization_entry(offered_choice):
			first_direct_choice_index = index
			break
	_check(first_direct_choice_index >= 0, "current block-board runs must retain a direct upgrade path alongside formation-set offers")
	if first_direct_choice_index >= 0:
		game.level_up_panel._select(first_direct_choice_index)
		await get_tree().process_frame
	_check(not get_tree().paused, "game must resume after choosing an upgrade")
	_check(game.game_phase == GameTypes.GamePhase.RUNNING, "game phase must return to RUNNING after placement")

	game.experience.add_experience(game.experience.required_experience - game.experience.current_experience + 1.0)
	await get_tree().process_frame
	var direct_choice_index := -1
	for index in game.level_up_panel.choices.size():
		var offered_choice := game.level_up_panel.choices[index] as UpgradeData
		if not offered_choice.requires_placement and offered_choice.category != &"formation_set" and not game.loadout.is_specialization_entry(offered_choice):
			direct_choice_index = index
			break
	_check(direct_choice_index >= 0, "level-up choices must include a direct non-placement upgrade")
	if direct_choice_index >= 0:
		game.level_up_panel._select(direct_choice_index)
		await get_tree().process_frame
	_check(not get_tree().paused, "game must resume after a direct upgrade choice")
	_check(game.game_phase == GameTypes.GamePhase.RUNNING, "direct upgrade must return the game to RUNNING")

	var timeline_completion_count := {"value": 0}
	game.game_speed_index = 2
	game._apply_game_speed()
	game.enemy_spawner.timeline_completed.connect(func() -> void: timeline_completion_count.value += 1)
	game.enemy_spawner.elapsed = 599.0
	game.enemy_spawner._physics_process(2.0)
	await get_tree().process_frame
	game.enemy_spawner._physics_process(1.0)
	_check(timeline_completion_count.value == 1, "the stage timeline must complete exactly once when its duration is reached")
	_check(get_tree().get_nodes_in_group(&"bosses").size() == 4, "all four boss milestones must be spawnable")
	var final_boss: Enemy
	var earlier_boss: Enemy
	for node in get_tree().get_nodes_in_group(&"bosses"):
		var boss := node as Enemy
		if boss != null and boss.data.id == game.boss_plan.final_boss_id:
			final_boss = boss
		elif boss != null and earlier_boss == null:
			earlier_boss = boss
	_check(final_boss != null, "final boss must exist at 10 minutes")
	if earlier_boss != null:
		earlier_boss.take_damage(100000000.0, &"test")
		await get_tree().process_frame
		_check(game.current_boss == final_boss and game.hud.boss_panel.visible and game.hud.boss_label.text == String(game._boss_presentation(final_boss.data).name), "defeating an older boss must keep the active final boss HUD visible with its campaign presentation name")
	if final_boss != null:
		final_boss.take_damage(100000000.0, &"test")
	_check(game.experience_rewards.calculate_boss_orb_count(DataRegistry.bosses[0].experience_value, 1) >= 22 and game.experience_rewards.calculate_boss_orb_count(DataRegistry.bosses[3].experience_value, 4) >= 40, "boss experience rewards must split into a tier-scaled large orb burst")
	var original_cursor_data := game.target_cursor.data
	game.target_cursor.data = DataRegistry.get_cursor(&"gold")
	game.experience.reset()
	var auto_awarded_orb := game.experience_rewards.spawn_orb(game.target_cursor.global_position, 10.0)
	game.experience_rewards.award_orb(auto_awarded_orb, auto_awarded_orb.global_position)
	_check(is_equal_approx(game.experience.total_experience, 13.0), "automatic boss-orb payout must use the same cursor experience multiplier as direct collection")
	game.target_cursor.data = original_cursor_data
	var finalization_deadline_msec := Time.get_ticks_msec() + 4000
	while not game.game_finished and Time.get_ticks_msec() < finalization_deadline_msec:
		await get_tree().process_frame
	_check(game.game_finished, "defeating the final boss must finish the run")
	_check(bool(GameSession.last_result.get("victory", false)), "final boss defeat must produce a victory result")
	_check(GameSession.last_result.get("stage_id", "") == "standard_20m" and GameSession.last_result.has("challenge_level") and GameSession.last_result.has("challenge_experience_multiplier"), "run results must retain the stage and selected challenge modifiers needed for permanent progression")
	_check(GameSession.last_result.has("outcome_summary") and (GameSession.last_result.outcome_summary as Dictionary).has("formation") and (GameSession.last_result.outcome_summary as Dictionary).has("status") and (GameSession.last_result.outcome_summary as Dictionary).has("spawn"), "run results must retain formation, status, and Spawn contribution summaries")
	_check(not game.selecting_upgrade and game.pending_level_ups == 0 and not game.level_up_panel.visible, "finishing a run must dismiss pending level-up overlays before showing the result")
	_check(not get_tree().paused and game.hud.result_panel.visible, "the final result must remain visible and interactive after a reward-triggered level-up")
	var result_viewport_rect := Rect2(Vector2.ZERO, game.get_viewport_rect().size)
	_check(result_viewport_rect.encloses(game.hud.result_panel.get_global_rect()) and result_viewport_rect.encloses(game.hud.restart_button.get_global_rect()) and result_viewport_rect.encloses(game.hud.menu_button.get_global_rect()), "the result panel and both navigation buttons must remain fully inside the 1280x720 viewport")
	_check(is_equal_approx(Engine.time_scale, 1.0) and game.hud.speed_button.disabled, "finishing a run must restore normal speed and lock the speed control")
	_check(game.hud.result_backdrop.visible and game.hud.range_button.disabled and game.hud.pause_button.disabled, "the result modal must block battlefield controls and disable remaining combat actions")

	game.enemy_spawner.stop()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	AudioManager.muted = true
	AudioManager.release_voice_pool()
	if failures.is_empty():
		print("SMOKE TEST PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
