class_name FormationPlacementService
extends RefCounted

var board_state := FormationBoardState.new(Battlefield.COLUMN_COUNT, Battlefield.LANE_COUNT)
var placed_formation_slices: Dictionary = {}
var next_placement_serial: int = 1

var battlefield: Battlefield
var column_container: Node2D
var columns: Array[TowerColumn] = []
var tower_type_levels: Dictionary = {}
var tower_branch_ids: Dictionary = {}
var tower_attack_callback := Callable()
var column_state_callback := Callable()

func configure(
	target_board_state: FormationBoardState,
	target_battlefield: Battlefield,
	target_container: Node2D,
	target_columns: Array[TowerColumn],
	target_tower_type_levels: Dictionary,
	target_tower_branch_ids: Dictionary,
	attack_callback: Callable,
	state_callback: Callable
) -> void:
	board_state = target_board_state
	battlefield = target_battlefield
	column_container = target_container
	columns = target_columns
	tower_type_levels = target_tower_type_levels
	tower_branch_ids = target_tower_branch_ids
	tower_attack_callback = attack_callback
	column_state_callback = state_callback
	placed_formation_slices.clear()
	next_placement_serial = 1

func place(
	formation: TowerFormationData,
	anchor: Vector2i,
	vertical_flipped: bool,
	guard: bool,
	requested_id: StringName
) -> Dictionary:
	var result := {"owner_id": &"", "tower_ids": []}
	if formation == null or battlefield == null or column_container == null:
		return result
	var owner_id := requested_id
	if owner_id == &"":
		owner_id = StringName("formation_%d" % next_placement_serial)
		next_placement_serial += 1
	if not board_state.place(owner_id, formation, anchor, vertical_flipped, guard):
		return result
	var entries_by_column := _entries_by_column(formation, anchor, vertical_flipped)
	var slices: Array[TowerColumn] = []
	for column_x in entries_by_column:
		var slice := _create_slice(int(column_x), tower_type_levels, tower_branch_ids)
		var slice_entries: Array[Dictionary] = []
		slice_entries.assign(entries_by_column[column_x] as Array)
		if not slice.equip_formation_cells(formation, slice_entries, owner_id, guard):
			_rollback(owner_id, slices, slice)
			return result
		columns.append(slice)
		slices.append(slice)
	placed_formation_slices[owner_id] = slices
	result.owner_id = owner_id
	result.tower_ids = formation.get_tower_ids()
	return result

func remove(owner_id: StringName) -> bool:
	if not placed_formation_slices.has(owner_id) or not board_state.remove(owner_id):
		return false
	for slice in placed_formation_slices[owner_id] as Array:
		columns.erase(slice)
		if is_instance_valid(slice):
			slice.queue_free()
	placed_formation_slices.erase(owner_id)
	return true

func _entries_by_column(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool) -> Dictionary:
	var result: Dictionary = {}
	for entry in board_state.transformed_cells(formation, anchor, vertical_flipped):
		var board_cell := entry.cell as Vector2i
		if not result.has(board_cell.x):
			result[board_cell.x] = []
		(result[board_cell.x] as Array).append(entry)
	return result

func _create_slice(column_x: int, tower_type_levels: Dictionary, tower_branch_ids: Dictionary) -> TowerColumn:
	var slice := TowerColumn.new()
	column_container.add_child(slice)
	slice.setup(column_x, battlefield.get_column_x(column_x), battlefield)
	if tower_attack_callback.is_valid():
		slice.attack_requested.connect(tower_attack_callback)
	if column_state_callback.is_valid():
		slice.state_changed.connect(column_state_callback)
	slice.set_shared_progress(tower_type_levels, tower_branch_ids)
	return slice

func _rollback(owner_id: StringName, created_slices: Array[TowerColumn], failed_slice: TowerColumn) -> void:
	for slice in created_slices:
		columns.erase(slice)
		slice.queue_free()
	failed_slice.queue_free()
	board_state.remove(owner_id)
