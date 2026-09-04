class_name FormationBoardContractTest
extends RefCounted

static func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var line := TowerFormationData.new().configure_cells(
		&"contract_line",
		"계약 직선",
		"2셀 가로 블록",
		[
			FormationCellData.new().configure(Vector2i(0, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(1, 0), &"pierce"),
		]
	)
	_check(line.get_shape_errors().is_empty(), "a normalized connected two-cell formation must be valid", failures)
	var board := FormationBoardState.new(6, 4)
	_check(board.valid_placements(line).size() == 20, "a horizontal two-cell formation must have twenty placements on an empty 6x4 board", failures)
	_check(board.place(&"first", line, Vector2i(0, 0)), "a valid formation must commit to the board", failures)
	_check(not board.can_place(line, Vector2i(1, 0)), "formation placement must reject overlapping cells", failures)
	_check(board.can_place(line, Vector2i(2, 0)), "formation placement must preserve unrelated empty cells", failures)
	_check(board.get_occupied_count() == 2 and board.build_snapshot().size() == 1, "board occupancy and snapshots must preserve committed formations", failures)
	_check(board.move(&"first", line, Vector2i(4, 3)), "a committed formation must move before final confirmation", failures)
	_check(board.occupied_cells.has(Vector2i(4, 3)) and board.occupied_cells.has(Vector2i(5, 3)), "moving a formation must update every occupied cell", failures)
	_check(not board.move(&"first", line, Vector2i(5, 3)), "an invalid move must fail", failures)
	_check(board.occupied_cells.has(Vector2i(4, 3)), "a failed move must restore the previous placement", failures)

	var corner := TowerFormationData.new().configure_cells(
		&"contract_corner",
		"계약 모서리",
		"상하 반전 가능한 3셀 블록",
		[
			FormationCellData.new().configure(Vector2i(0, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(0, 1), &"area"),
			FormationCellData.new().configure(Vector2i(1, 1), &"slow"),
		]
	)
	var flipped := board.transformed_cells(corner, Vector2i.ZERO, true)
	_check((flipped[0] as Dictionary).cell == Vector2i(0, 1) and (flipped[1] as Dictionary).cell == Vector2i(0, 0), "vertical flip must mirror local Y without rotating X", failures)

	var symmetric := TowerFormationData.new().configure_cells(
		&"contract_symmetric",
		"계약 대칭",
		"반전해도 같은 2×2 블록",
		[
			FormationCellData.new().configure(Vector2i(0, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(1, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(0, 1), &"rapid"),
			FormationCellData.new().configure(Vector2i(1, 1), &"rapid"),
		]
	)
	var symmetric_board := FormationBoardState.new(6, 4)
	_check(symmetric_board.valid_placements(symmetric).size() == 15, "a vertically symmetric 2x2 formation must report each physical placement once", failures)

	var disconnected := TowerFormationData.new().configure_cells(
		&"contract_disconnected",
		"잘못된 편대",
		"분리된 셀",
		[
			FormationCellData.new().configure(Vector2i(0, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(2, 0), &"area"),
		]
	)
	_check("\n".join(disconnected.get_shape_errors()).contains("connected"), "formation validation must reject disconnected cells", failures)
	return failures

static func run_runtime(host: Node) -> PackedStringArray:
	var failures := PackedStringArray()
	var battlefield := Battlefield.new()
	var container := Node2D.new()
	var loadout := LoadoutManager.new()
	host.add_child(battlefield)
	host.add_child(container)
	host.add_child(loadout)
	loadout.setup(battlefield, container)
	var block := TowerFormationData.new().configure_cells(
		&"runtime_corner",
		"런타임 모서리",
		"두 열에 걸친 실제 전투 블록",
		[
			FormationCellData.new().configure(Vector2i(0, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(1, 0), &"pierce"),
			FormationCellData.new().configure(Vector2i(0, 1), &"area"),
		]
	)
	var owner_id := loadout.place_formation_block(block, Vector2i(2, 1))
	_check(owner_id != &"", "block runtime must commit a valid multi-column formation", failures)
	_check(loadout.columns.size() == 2, "a multi-column formation must create one combat slice per occupied board column", failures)
	_check(loadout.columns.all(func(column: TowerColumn) -> bool: return column.placement_id == owner_id), "every combat slice must retain its formation owner", failures)
	_check(loadout.placement_service.placed_formation_slices.has(owner_id), "the placement service must own combat slices by their committed board owner", failures)
	_check(loadout.get_installed_tower_ids().size() == 3 and loadout.get_board_snapshot().size() == 1, "block runtime must expose installed tower types and one formation snapshot", failures)
	var occupied_before_rejection := loadout.board_state.get_occupied_count()
	var columns_before_rejection := loadout.columns.size()
	_check(loadout.place_formation_block(block, Vector2i(2, 1)) == &"" and loadout.board_state.get_occupied_count() == occupied_before_rejection and loadout.columns.size() == columns_before_rejection, "a rejected placement must leave both board ownership and combat slices unchanged", failures)
	_check(loadout.remove_formation_block(owner_id) and loadout.board_state.get_occupied_count() == 0 and loadout.columns.is_empty() and loadout.placement_service.placed_formation_slices.is_empty(), "removing a block formation must release every occupied cell and combat slice", failures)
	loadout.free()
	container.free()
	battlefield.free()
	return failures

static func _check(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
