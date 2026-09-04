class_name CombatRangeOverlay
extends Node2D

signal inspection_snapshot_changed(snapshot: Dictionary)

const CORE_COLOR := Color("65e0c0")
const LABEL_COLOR := Color("d7f7ff")
const CORE_HOVER_RADIUS := 68.0
const TOWER_HOVER_RADIUS := 42.0
const SNAPSHOT_REFRESH_SECONDS := 0.15

var core: DefenseCore
var loadout: LoadoutManager
var battlefield: Battlefield
var inspection_mode: bool = false
var inspected_kind: StringName = &""
var inspected_stable_id: StringName = &""
var inspected_column: TowerColumn
var inspected_row: int = -1
var inspection_pinned: bool = false
var snapshot_refresh_remaining: float = 0.0
var last_snapshot: Dictionary = {}

func _ready() -> void:
	visible = true

func setup(target_core: DefenseCore, target_loadout: LoadoutManager, target_battlefield: Battlefield) -> void:
	core = target_core
	loadout = target_loadout
	battlefield = target_battlefield
	refresh()

func set_overlay_enabled(enabled: bool) -> void:
	inspection_mode = enabled
	if not enabled:
		clear_inspection()
	else:
		inspection_pinned = false
	queue_redraw()

func is_overlay_enabled() -> bool:
	return inspection_mode

func is_inspection_pinned() -> bool:
	return inspection_pinned

func get_inspection_snapshot() -> Dictionary:
	return _build_inspection_snapshot().duplicate(true)

func refresh() -> void:
	if not _validate_inspection():
		clear_inspection()
	else:
		_emit_inspection_snapshot(true)
	queue_redraw()

func inspect_at(world_position: Vector2, pin_selection: bool = true) -> bool:
	var candidate := _find_candidate(world_position)
	if candidate.is_empty():
		clear_inspection()
		return false
	_set_inspection(candidate, pin_selection)
	return true

func clear_inspection() -> void:
	var had_inspection := inspected_kind != &"" or not last_snapshot.is_empty()
	inspected_kind = &""
	inspected_stable_id = &""
	inspected_column = null
	inspected_row = -1
	inspection_pinned = false
	snapshot_refresh_remaining = 0.0
	last_snapshot.clear()
	if had_inspection:
		inspection_snapshot_changed.emit({})
	queue_redraw()

func get_inspected_range() -> float:
	if inspected_kind == &"core" and is_instance_valid(core) and core.data != null:
		return _get_core_attack_range()
	if inspected_kind == &"tower" and is_instance_valid(inspected_column) and inspected_row >= 0:
		return inspected_column.get_attack_range(inspected_row)
	return 0.0

func get_visible_tower_count() -> int:
	if loadout == null:
		return 0
	var result := 0
	for column in loadout.columns:
		if not is_instance_valid(column):
			continue
		for row_index in column.row_towers.size():
			if column.get_tower_data(row_index) != null and column.get_attack_range(row_index) > 0.0:
				result += 1
	return result

func _process(delta: float) -> void:
	if not is_instance_valid(core) or loadout == null:
		return
	if not _validate_inspection():
		clear_inspection()
	if not inspection_pinned:
		var mouse_world := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		var candidate := _find_candidate(mouse_world)
		if not candidate.is_empty():
			_set_inspection(candidate, false)
		elif inspected_kind != &"":
			clear_inspection()
	if inspected_kind != &"":
		snapshot_refresh_remaining -= delta
		if snapshot_refresh_remaining <= 0.0:
			snapshot_refresh_remaining = SNAPSHOT_REFRESH_SECONDS
			_emit_inspection_snapshot(true)

func _unhandled_input(event: InputEvent) -> void:
	if inspection_pinned and event.is_action_pressed(&"ui_cancel"):
		clear_inspection()
		get_viewport().set_input_as_handled()
		return
	if not inspection_mode:
		return
	var screen_position := Vector2.ZERO
	var is_selection := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		screen_position = event.position
		is_selection = true
	elif event is InputEventScreenTouch and event.pressed:
		screen_position = event.position
		is_selection = true
	if not is_selection:
		return
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	inspect_at(world_position, true)
	get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _validate_inspection() or battlefield == null:
		return
	if inspected_kind == &"core":
		_draw_core_range()
	elif inspected_kind == &"tower":
		_draw_tower_range(inspected_column, inspected_row)

func _draw_core_range() -> void:
	var origin := to_local(core.global_position)
	var attack_range := _get_core_attack_range()
	draw_arc(origin, attack_range, 0.0, TAU, 160, Color(CORE_COLOR, 0.86), 3.0, true)
	draw_dashed_line(origin, origin + Vector2.RIGHT * attack_range, Color(CORE_COLOR, 0.58), 2.0, 12.0, true)
	draw_circle(origin, 6.0, CORE_COLOR)
	draw_circle(origin + Vector2.RIGHT * attack_range, 7.0, Color(CORE_COLOR, 0.85))
	_draw_range_label(origin + Vector2(20.0, -54.0), "%s · %.0f px" % [ConceptService.term(&"core"), attack_range], CORE_COLOR)

func _get_core_attack_range() -> float:
	if not is_instance_valid(core) or core.data == null:
		return 0.0
	var candidate_multiplier := 1.0
	if loadout != null:
		candidate_multiplier = float(loadout.get_candidate_modifier(&"core_attack_range", 1.0))
	return core.data.attack_range * candidate_multiplier

func _draw_tower_range(column: TowerColumn, row_index: int) -> void:
	var tower := column.get_tower_data(row_index)
	if tower == null:
		return
	var attack_range := column.get_attack_range(row_index)
	var origin := to_local(column.get_attack_origin(row_index))
	var range_color := tower.color if tower.color.a > 0.0 else Color("8fe8ff")
	draw_circle(origin, attack_range, Color(range_color, 0.045))
	draw_arc(origin, attack_range, 0.0, TAU, 96, Color(range_color, 0.88), 2.4, true)
	draw_dashed_line(origin, origin + Vector2.RIGHT * attack_range, Color(range_color, 0.58), 1.5, 9.0, true)
	draw_circle(origin, 5.0, Color(range_color, 0.95))
	var range_cells := attack_range / maxf(battlefield.get_column_spacing(), 1.0)
	_draw_range_label(origin + Vector2(18.0, -38.0), "%s · %.2f칸" % [tower.display_name, range_cells], range_color)

func _draw_range_label(label_position: Vector2, label: String, color: Color) -> void:
	var text_size := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15)
	var panel_rect := Rect2(label_position - Vector2(7.0, 18.0), text_size + Vector2(14.0, 9.0))
	draw_rect(panel_rect, Color(0.02, 0.055, 0.075, 0.94), true)
	draw_rect(panel_rect, Color(color, 0.85), false, 1.0)
	draw_string(ThemeDB.fallback_font, label_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, LABEL_COLOR)

func _find_candidate(world_position: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	if is_instance_valid(core) and core.data != null and core.active:
		var core_distance := world_position.distance_to(core.global_position)
		if core_distance <= CORE_HOVER_RADIUS:
			best = {"kind": &"core", "stable_id": core.data.id, "distance": core_distance}
			best_distance = core_distance
	if loadout == null:
		return best
	for column in loadout.columns:
		if not is_instance_valid(column):
			continue
		for row_index in column.row_towers.size():
			var tower := column.get_tower_data(row_index)
			if tower == null:
				continue
			var distance := world_position.distance_to(column.get_attack_origin(row_index))
			if distance <= TOWER_HOVER_RADIUS and distance < best_distance:
				best = {"kind": &"tower", "stable_id": tower.id, "column": column, "row": row_index, "distance": distance}
				best_distance = distance
	return best

func _set_inspection(candidate: Dictionary, pin_selection: bool) -> void:
	var next_kind: StringName = candidate.get("kind", &"")
	var next_stable_id: StringName = candidate.get("stable_id", &"")
	var next_column: TowerColumn = candidate.get("column", null) as TowerColumn
	var next_row: int = int(candidate.get("row", -1))
	var changed := inspected_kind != next_kind or inspected_stable_id != next_stable_id or inspected_column != next_column or inspected_row != next_row or inspection_pinned != pin_selection
	inspected_kind = next_kind
	inspected_stable_id = next_stable_id
	inspected_column = next_column
	inspected_row = next_row
	inspection_pinned = pin_selection
	if changed:
		snapshot_refresh_remaining = SNAPSHOT_REFRESH_SECONDS
		_emit_inspection_snapshot(true)
		queue_redraw()

func _validate_inspection() -> bool:
	if inspected_kind == &"":
		return true
	if inspected_kind == &"core":
		return is_instance_valid(core) and core.data != null and core.active and (inspected_stable_id == &"" or core.data.id == inspected_stable_id)
	if inspected_kind == &"tower":
		if not is_instance_valid(inspected_column) or inspected_row < 0 or inspected_row >= inspected_column.row_towers.size():
			return false
		var tower := inspected_column.get_tower_data(inspected_row)
		return tower != null and (inspected_stable_id == &"" or tower.id == inspected_stable_id)
	return false

func _build_inspection_snapshot() -> Dictionary:
	if inspected_kind == &"" or not _validate_inspection():
		return {}
	if inspected_kind == &"core":
		return {
			"schema_version": 1,
			"kind": &"core",
			"stable_id": core.data.id,
			"world_position": core.global_position,
			"range_pixels": get_inspected_range(),
			"pinned": inspection_pinned,
		}
	var tower := inspected_column.get_tower_data(inspected_row)
	return {
		"schema_version": 1,
		"kind": &"tower",
		"stable_id": tower.id,
		"column_index": inspected_column.column_index,
		"row_index": inspected_row,
		"world_position": inspected_column.get_attack_origin(inspected_row),
		"range_pixels": get_inspected_range(),
		"pinned": inspection_pinned,
		"guard": inspected_column.is_guard_formation,
	}

func _emit_inspection_snapshot(force: bool = false) -> void:
	var snapshot := _build_inspection_snapshot()
	if not force and snapshot == last_snapshot:
		return
	last_snapshot = snapshot.duplicate(true)
	inspection_snapshot_changed.emit(last_snapshot.duplicate(true))
