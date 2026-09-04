class_name UiUxM4UnitInfoContractTest
extends RefCounted

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	var battlefield := Battlefield.new()
	root.add_child(battlefield)
	var column_container := Node2D.new()
	root.add_child(column_container)
	var loadout := LoadoutManager.new()
	root.add_child(loadout)
	loadout.setup(battlefield, column_container)
	var formation := _first_placeable_normal_formation(loadout)
	_expect(formation != null, "M4 contract fixture must find a placeable normal formation", failures)
	if formation == null:
		loadout.queue_free()
		column_container.queue_free()
		battlefield.queue_free()
		return failures
	var placement := loadout.get_valid_board_placements(formation)[0] as Dictionary
	var placement_id := loadout.place_formation_block(formation, placement.anchor as Vector2i, bool(placement.vertical_flipped))
	_expect(placement_id != &"", "M4 contract fixture must place a normal formation", failures)
	var tower_probe := _first_tower(loadout)
	_expect(not tower_probe.is_empty(), "M4 contract fixture must expose a placed defender", failures)

	var core := DefenseCore.new()
	root.add_child(core)
	core.position = battlefield.get_core_position()
	var core_data := DataRegistry.get_core(GameSession.selected_core_id)
	if core_data == null:
		core_data = DataRegistry.cores[0]
	core.configure(core_data)

	var overlay := CombatRangeOverlay.new()
	root.add_child(overlay)
	overlay.set_process(false)
	overlay.setup(core, loadout, battlefield)
	var emitted_snapshots: Array[Dictionary] = []
	overlay.inspection_snapshot_changed.connect(func(snapshot: Dictionary) -> void: emitted_snapshots.append(snapshot.duplicate(true)))
	var presenter := UnitInfoPresenter.new()
	var popover := (load("res://scenes/ui/components/unit_info_popover.tscn") as PackedScene).instantiate() as UnitInfoPopover
	root.add_child(popover)

	overlay.inspect_at(core.global_position, false)
	var core_selection := overlay.get_inspection_snapshot()
	var core_snapshot := presenter.present(core_selection, core, loadout, battlefield)
	_expect(not core_selection.is_empty() and not overlay.is_inspection_pinned() and not emitted_snapshots.is_empty() and core_selection == emitted_snapshots.back(), "M4 hover preview must emit a copied selection snapshot without pinning", failures)
	_expect(core_snapshot.get("stable_id", &"") == core.data.id and (core_snapshot.get("role_tags", []) as Array).has("후보") and String(core_snapshot.get("faction_label", "")).begins_with("팩션 ·"), "M4 candidate presentation must expose stable identity plus text faction and role semantics", failures)
	_expect(not _contains_runtime_node(core_selection) and not _contains_runtime_node(core_snapshot), "M4 UI snapshots must not retain combat Node references", failures)
	popover.show_snapshot(core_snapshot, Vector2.ZERO, Vector2i(1280, 720), Rect2i(36, 24, 1208, 672))
	_validate_corner_clamp(popover, core_snapshot, failures)

	if not tower_probe.is_empty():
		var column := tower_probe.column as TowerColumn
		var row_index := int(tower_probe.row)
		var tower := column.get_tower_data(row_index)
		overlay.set_overlay_enabled(true)
		_expect(overlay.inspect_at(column.get_attack_origin(row_index), true) and overlay.is_inspection_pinned(), "M4 touch/click selection must pin the inspected defender", failures)
		var tower_selection := overlay.get_inspection_snapshot()
		var tower_snapshot := presenter.present(tower_selection, core, loadout, battlefield, func(target_column: TowerColumn, target_row: int) -> float: return target_column.get_damage(target_row))
		_expect(tower_snapshot.get("stable_id", &"") == tower.id and tower_snapshot.get("range_pixels", 0.0) == overlay.get_inspected_range(), "M4 range circle and popover snapshot must resolve the same stable defender and range", failures)
		_expect((tower_snapshot.get("role_tags", []) as Array).has("일반 수비") and String(tower_snapshot.get("faction_label", "")).begins_with("소속 ·") and String(tower_snapshot.get("status_label", "")) == "정상 작동", "M4 defender presentation must remain distinguishable without relying on color", failures)
		popover.show_snapshot(tower_snapshot, Vector2(640.0, 360.0), Vector2i(1280, 720), Rect2i(36, 24, 1208, 672))
		_expect(popover.visible and popover.get_snapshot().get("stable_id", &"") == tower_selection.stable_id and popover.close_button.custom_minimum_size.x >= UiTokens.TOUCH_TARGET_MIN and popover.close_button.focus_mode == Control.FOCUS_ALL, "M4 pinned popover must mirror the range target and expose a touch-sized close action", failures)
		_validate_corner_clamp(popover, tower_snapshot, failures)

		column.disable_row_for(row_index, 2.0)
		var disabled_snapshot := presenter.present(tower_selection, core, loadout, battlefield)
		_expect(String(disabled_snapshot.get("status_label", "")) == "행동 불능", "M4 status text must expose disabled defenders without color dependence", failures)
		var cancel := InputEventAction.new()
		cancel.action = &"ui_cancel"
		cancel.pressed = true
		overlay._unhandled_input(cancel)
		_expect(overlay.get_inspection_snapshot().is_empty() and not overlay.is_inspection_pinned(), "M4 ESC must clear a pinned selection before opening another screen", failures)

		overlay.inspect_at(column.get_attack_origin(row_index), true)
		var outside_touch := InputEventScreenTouch.new()
		outside_touch.position = Vector2(-200.0, -200.0)
		outside_touch.pressed = true
		overlay._unhandled_input(outside_touch)
		_expect(overlay.get_inspection_snapshot().is_empty(), "M4 an outside touch must dismiss the pinned selection", failures)

		overlay.inspect_at(column.get_attack_origin(row_index), true)
		column.row_towers[row_index] = null
		overlay.refresh()
		_expect(overlay.get_inspection_snapshot().is_empty() and presenter.present(tower_selection, core, loadout, battlefield).is_empty(), "M4 removed or replaced defenders must invalidate both overlay and presenter snapshots", failures)

	popover.queue_free()
	overlay.queue_free()
	core.queue_free()
	loadout.queue_free()
	column_container.queue_free()
	battlefield.queue_free()
	return failures

static func _first_placeable_normal_formation(loadout: LoadoutManager) -> TowerFormationData:
	for formation in DataRegistry.formations:
		if formation != null and not formation.is_guard and not loadout.get_valid_board_placements(formation).is_empty():
			return formation
	return null

static func _first_tower(loadout: LoadoutManager) -> Dictionary:
	for column in loadout.columns:
		for row_index in column.row_towers.size():
			if column.get_tower_data(row_index) != null:
				return {"column": column, "row": row_index}
	return {}

static func _validate_corner_clamp(popover: UnitInfoPopover, snapshot: Dictionary, failures: Array[String]) -> void:
	var safe_rect := Rect2i(36, 24, 1208, 672)
	for anchor in [Vector2(0.0, 0.0), Vector2(1280.0, 0.0), Vector2(0.0, 720.0), Vector2(1280.0, 720.0)]:
		popover.show_snapshot(snapshot, anchor, Vector2i(1280, 720), safe_rect)
		var panel_rect := popover.get_panel_rect()
		var safe_bounds := popover.get_safe_bounds()
		_expect(safe_bounds.encloses(panel_rect), "M4 popover must remain inside mocked OS insets at anchor %s" % anchor, failures)

static func _contains_runtime_node(value: Variant) -> bool:
	if value is Node:
		return true
	if value is Dictionary:
		for nested in (value as Dictionary).values():
			if _contains_runtime_node(nested):
				return true
	elif value is Array:
		for nested in value as Array:
			if _contains_runtime_node(nested):
				return true
	return false

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
