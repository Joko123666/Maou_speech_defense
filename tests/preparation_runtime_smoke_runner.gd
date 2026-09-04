extends Node

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	await get_tree().process_frame
	AudioManager.muted = true
	var testing_bypass_backup := MetaProgressionService.testing_content_lock_bypass
	var session_backup := {
		"core": GameSession.selected_core_id,
		"cursor": GameSession.selected_cursor_id,
		"challenge": GameSession.selected_challenge_level,
		"decree": GameSession.selected_decree_id,
		"run_mode": GameSession.run_mode,
		"artifact_mode": GameSession.artifact_mode,
		"last_result": GameSession.last_result.duplicate(true),
	}
	MetaProgressionService.set_testing_content_lock_bypass(true)
	GameSession.selected_core_id = &"emerald"
	GameSession.selected_cursor_id = &"iron"
	GameSession.selected_challenge_level = 0
	GameSession.selected_decree_id = &""
	GameSession.run_mode = GameSession.RUN_MODE_STANDARD
	GameSession.artifact_mode = GameSession.ARTIFACT_MODE_NORMAL
	GameSession.last_result.clear()
	var packed := load("res://scenes/game/game.tscn") as PackedScene
	var preparation_game := packed.instantiate() as GameController
	preparation_game.testing_mode = true
	add_child(preparation_game)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(preparation_game.block_board_active and preparation_game.game_phase == GameTypes.GamePhase.PREPARATION and preparation_game.preparation_panel.visible, "default test runs must use the current block board and open mandatory guard preparation before combat")
	_check(
		preparation_game.preparation_panel.cell_buttons.all(func(button: Button) -> bool: return button.text.is_empty())
		and not preparation_game.preparation_panel.status_label.text.contains("열")
		and not preparation_game.preparation_panel.status_label.text.contains("행"),
		"formation placement boards must keep cell labels blank and omit board coordinates"
	)
	_check(
		preparation_game.preparation_panel.cell_buttons.filter(func(button: Button) -> bool: return button.tooltip_text.contains("배치 미리보기") and (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color != PreparationPanel.EMPTY_CELL_FILL).size() == preparation_game.preparation_panel.formation.cells.size(),
		"formation placement previews must identify every incoming defender by color without printing its name"
	)
	_check(preparation_game.enemy_spawner.elapsed == 0.0 and preparation_game.loadout.columns.is_empty() and not preparation_game.core.is_processing() and not preparation_game.target_cursor.is_processing(), "preparation must stop the timer, spawns, candidate attacks, retainer attacks, and tower runtime")
	var preparation_viewport_rect := Rect2(Vector2.ZERO, preparation_game.get_viewport().get_visible_rect().size)
	var start_button_rect := preparation_game.preparation_panel.confirm_button.get_global_rect()
	_check(
		preparation_viewport_rect.encloses(start_button_rect)
		and preparation_game.preparation_panel.confirm_button.custom_minimum_size.y >= 64.0
		and preparation_game.preparation_panel.status_label.text.contains("시작 버튼"),
		"guard preparation must expose an unmistakable touch-sized start action fully inside the fixed mobile viewport",
	)
	var start_touch := InputEventScreenTouch.new()
	start_touch.index = 0
	start_touch.position = start_button_rect.get_center()
	start_touch.pressed = true
	preparation_game.get_viewport().push_input(start_touch, true)
	var end_touch := start_touch.duplicate() as InputEventScreenTouch
	end_touch.pressed = false
	preparation_game.get_viewport().push_input(end_touch, true)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(preparation_game.game_phase == GameTypes.GamePhase.RUNNING and preparation_game.enemy_spawner.running, "a real screen-touch release on the visible preparation CTA must start the speech timer and combat")
	_check(preparation_game.loadout.board_state.get_occupied_count() == 4 and preparation_game.loadout.get_board_snapshot().size() == 1 and bool(preparation_game.loadout.get_board_snapshot()[0].is_guard), "Partason preparation must commit exactly one four-cell royal guard formation")
	var block_choices := preparation_game.loadout.generate_upgrade_choices()
	var formation_set_choices := block_choices.filter(func(choice: UpgradeData) -> bool: return choice.category == &"formation_set")
	var required_formation_choices := formation_set_choices.filter(func(choice: UpgradeData) -> bool: return bool(choice.offer_metadata.get(UpgradeOfferService.REQUIRED_INITIAL_FORMATION_META, false)))
	_check(formation_set_choices.size() in [1, 2] and required_formation_choices.size() == 1 and (formation_set_choices.size() == 1 or formation_set_choices[0].data_id != formation_set_choices[1].data_id) and not block_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"unique_formation"), "a block-board level-up must guarantee one protected initial formation, allow at most one different-size optional formation, and omit legacy guard offers")
	var formation_set := formation_set_choices[0] as UpgradeData
	var block_candidates := preparation_game.loadout.get_formation_candidates(preparation_game.loadout.get_formation_set_size(formation_set), 3)
	_check(not block_candidates.is_empty() and block_candidates.size() <= 3 and block_candidates.all(func(choice: UpgradeData) -> bool: return not preparation_game.loadout.get_valid_board_placements(DataRegistry.get_formation(choice.data_id)).is_empty()), "formation-set subchoices must be capped at three and remain placeable on the current board")
	_check(block_candidates.all(func(choice: UpgradeData) -> bool:
		var formation := DataRegistry.get_formation(choice.data_id)
		return (choice.offer_metadata.get("shape_class", &"") == formation.shape_class
			and int(choice.offer_metadata.get("distinct_tower_count", 0)) == formation.get_distinct_tower_count()
			and int(choice.offer_metadata.get("valid_position_count", 0)) == preparation_game.loadout.get_valid_board_placements(formation).size()
			and choice.description.contains(formation.get_shape_display_name())
			and choice.description.contains("%d병종" % formation.get_distinct_tower_count())
			and choice.description.contains("배치 %s" % formation.get_placement_difficulty_display_name()))
	), "formation-set A/B/C cards must present and retain shape, species count, placement difficulty, and valid-position metadata")
	preparation_game.pending_level_ups = 1
	preparation_game.pending_reward_levels.assign([2])
	preparation_game.selecting_upgrade = true
	preparation_game.game_phase = GameTypes.GamePhase.LEVEL_UP
	get_tree().paused = true
	preparation_game._on_upgrade_selected(formation_set)
	_check(preparation_game.level_up_panel.subchoice_mode and not preparation_game.level_up_panel.subchoice_return_allowed, "selecting a formation set must freeze its one-time subchoice list and block return to the main three choices")
	_check(preparation_game.level_up_panel.get_node("%Title").text.contains("편대 선택") and not preparation_game.level_up_panel.hint_label.text.contains("Lv.4"), "formation subchoices must use placement-specific title and guidance instead of specialization copy")
	var abandoned_choice := preparation_game.level_up_panel.choices[0]
	preparation_game._on_upgrade_selected(abandoned_choice)
	_check(preparation_game.pending_block_formation_choice == abandoned_choice and preparation_game.preparation_panel.visible and not preparation_game.preparation_panel.guard_mode, "selecting a formation recipe must irreversibly enter cell placement")
	_check(
		preparation_game.preparation_panel.cell_buttons.filter(func(button: Button) -> bool: return button.tooltip_text.contains("배치됨") and button.text.is_empty() and (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color != PreparationPanel.EMPTY_CELL_FILL).size() == 4,
		"installed guard cells must remain name-free color blocks while placing later formations"
	)
	var refund_before := preparation_game.experience.current_experience
	preparation_game._on_block_placement_abandoned(DataRegistry.get_formation(abandoned_choice.data_id))
	_check(preparation_game.pending_level_ups == 0 and preparation_game.experience.current_experience > refund_before and is_equal_approx(preparation_game.experience.current_experience, preparation_game.experience.get_requirement_for_reward_level(2) * 0.4), "voluntary placement abandonment must consume the reward and refund forty percent of its level requirement")
	var abandonment_events: Array = preparation_game.metrics.formation_metrics_snapshot().get("abandon_events", [])
	_check(not abandonment_events.is_empty() and abandonment_events.back().shape_class == String(DataRegistry.get_formation(abandoned_choice.data_id).shape_class) and int(abandonment_events.back().distinct_tower_count) == DataRegistry.get_formation(abandoned_choice.data_id).get_distinct_tower_count() and int(abandonment_events.back().valid_position_count) == int(abandoned_choice.offer_metadata.valid_position_count), "formation abandonment metrics must retain the offered shape, species, and placement-freedom context")
	var success_sets := preparation_game.loadout.generate_upgrade_choices().filter(func(choice: UpgradeData) -> bool: return choice.category == &"formation_set")
	if not success_sets.is_empty():
		var success_set := success_sets[0] as UpgradeData
		var success_candidates := preparation_game.loadout.get_formation_candidates(preparation_game.loadout.get_formation_set_size(success_set), 3)
		if not success_candidates.is_empty():
			preparation_game.pending_level_ups = 1
			preparation_game.pending_reward_levels.assign([3])
			preparation_game.selecting_upgrade = true
			preparation_game.game_phase = GameTypes.GamePhase.LEVEL_UP
			get_tree().paused = true
			preparation_game._on_upgrade_selected(success_candidates[0])
			var occupied_before_success := preparation_game.loadout.board_state.get_occupied_count()
			preparation_game.preparation_panel._confirm()
			_check(preparation_game.pending_level_ups == 0 and preparation_game.loadout.board_state.get_occupied_count() > occupied_before_success and preparation_game.loadout.get_board_snapshot().size() == 2, "confirming a frozen formation recipe must commit its cells and complete exactly one level-up reward")
	var formation_metric_snapshot := preparation_game.metrics.formation_metrics_snapshot()
	_check(not (formation_metric_snapshot.get("guard_placements", {}) as Dictionary).is_empty() and not (formation_metric_snapshot.get("formation_abandons", {}) as Dictionary).is_empty() and not (formation_metric_snapshot.get("set_abandons_by_size", {}) as Dictionary).is_empty(), "v0.10 metrics must retain guard placement and irreversible formation abandonment by id and size")
	_check((formation_metric_snapshot.get("board_occupancy_samples", []) as Array).size() >= 3 and (formation_metric_snapshot.get("isolated_empty_cell_samples", []) as Array).size() >= 3, "formation decisions must sample board occupancy and isolated empty cells")
	var guard_events := formation_metric_snapshot.get("guard_placement_events", []) as Array
	var abandon_events := formation_metric_snapshot.get("abandon_events", []) as Array
	var selection_events := formation_metric_snapshot.get("selection_events", []) as Array
	_check(guard_events.size() == 1 and int((guard_events[0] as Dictionary).get("empty_cells", -1)) == 20 and int((guard_events[0] as Dictionary).get("anchor_x", -1)) >= 0, "guard metrics must retain the confirmed anchor, orientation, and remaining board space after Partason's four-cell guard")
	_check(abandon_events.size() == 1 and float((abandon_events[0] as Dictionary).get("refund_experience", 0.0)) > 0.0 and int((abandon_events[0] as Dictionary).get("empty_cells", -1)) == 20, "formation abandonment metrics must retain timing, refund, and the four-cell guard's remaining empty cells")
	_check(selection_events.is_empty() or int((selection_events[0] as Dictionary).get("anchor_x", -1)) >= 0, "successful formation metrics must retain placement anchor and board context")
	var block_build_summary := preparation_game.loadout.get_build_summary()
	for placement in preparation_game.loadout.get_board_snapshot():
		var summary_formation := DataRegistry.get_formation(StringName(placement.formation_id))
		_check(summary_formation != null and block_build_summary.count(summary_formation.display_name) == preparation_game.loadout.get_board_snapshot().filter(func(entry: Dictionary) -> bool: return entry.formation_id == placement.formation_id).size(), "block build summary must list each placed formation once instead of repeating its combat slices")
	var block_balance_column := TowerColumn.new()
	add_child(block_balance_column)
	block_balance_column.set_process(false)
	block_balance_column.set_physics_process(false)
	block_balance_column.setup(5, preparation_game.battlefield.get_column_x(5), preparation_game.battlefield)
	block_balance_column.set_shared_progress({&"rapid": 1}, {})
	var block_slice_entries: Array[Dictionary] = [{"cell": Vector2i(5, 0), "tower_id": &"rapid"}]
	_check(block_balance_column.equip_formation_cells(DataRegistry.get_formation(&"duo"), block_slice_entries, &"block_balance_probe"), "block balance probe must equip a cell slice")
	_check(block_balance_column.uses_block_cells and is_equal_approx(block_balance_column.get_formation_output_multiplier(), 1.0), "v0.10 block slices must not apply retired 300-point output normalization")
	_check(is_equal_approx(block_balance_column.get_attack_interval(0), DataRegistry.get_tower(&"rapid").attack_interval) and is_equal_approx(block_balance_column.get_damage(0), DataRegistry.get_tower(&"rapid").damage), "v0.10 block slices must use raw tower damage and cadence without retired blank-cell bonuses")
	block_balance_column.queue_free()
	var formation_result := preparation_game.run_result_service.build_result(
		preparation_game.stage_data,
		preparation_game.boss_plan,
		preparation_game.enemy_spawner,
		preparation_game.experience,
		preparation_game.core,
		preparation_game.target_cursor,
		preparation_game.loadout,
		preparation_game.metrics,
		0,
		0,
		"없음",
		false,
		"formation-result-contract"
	)
	preparation_game.hud.formation_board_preview.configure(formation_result.formation_board, int(formation_result.formation_board_width), int(formation_result.formation_board_height))
	_check((formation_result.formation_board as Array).size() == preparation_game.loadout.get_board_snapshot().size() and preparation_game.hud.formation_board_preview.snapshot == formation_result.formation_board, "run results and the result preview must reproduce the final 4x6 board snapshot")
	preparation_game.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	MetaProgressionService.set_testing_content_lock_bypass(testing_bypass_backup)
	GameSession.selected_core_id = session_backup.core
	GameSession.selected_cursor_id = session_backup.cursor
	GameSession.selected_challenge_level = session_backup.challenge
	GameSession.selected_decree_id = session_backup.decree
	GameSession.run_mode = session_backup.run_mode
	GameSession.artifact_mode = session_backup.artifact_mode
	GameSession.last_result = session_backup.last_result
	AudioManager.release_voice_pool()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("PREPARATION RUNTIME SMOKE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
