class_name FormationBoardState
extends RefCounted

const DEFAULT_WIDTH := 6
const DEFAULT_HEIGHT := 4

var width: int
var height: int
var forbidden_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
var placements: Dictionary = {}

func _init(board_width: int = DEFAULT_WIDTH, board_height: int = DEFAULT_HEIGHT) -> void:
	width = maxi(board_width, 1)
	height = maxi(board_height, 1)

func set_forbidden(cells: Array[Vector2i]) -> void:
	forbidden_cells.clear()
	for cell in cells:
		if is_inside(cell):
			forbidden_cells[cell] = true

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func is_empty(cell: Vector2i) -> bool:
	return is_inside(cell) and not forbidden_cells.has(cell) and not occupied_cells.has(cell)

func transformed_cells(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if formation == null:
		return result
	var maximum_y := formation.get_bounds().size.y - 1
	for formation_cell in formation.cells:
		if formation_cell == null:
			continue
		var local_offset := formation_cell.offset
		if vertical_flipped and formation.can_vertical_flip:
			local_offset.y = maximum_y - local_offset.y
		result.append({
			"cell": anchor + local_offset,
			"tower_id": formation_cell.tower_id,
		})
	return result

func can_place(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool = false, ignored_placement_id: StringName = &"") -> bool:
	if formation == null or formation.cells.is_empty():
		return false
	for entry in transformed_cells(formation, anchor, vertical_flipped):
		var cell := entry.cell as Vector2i
		if not is_inside(cell) or forbidden_cells.has(cell):
			return false
		if occupied_cells.has(cell) and occupied_cells[cell] != ignored_placement_id:
			return false
	return true

func valid_placements(formation: TowerFormationData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if formation == null:
		return result
	var seen_placements: Dictionary = {}
	var flip_options: Array[bool] = [false]
	if formation.can_vertical_flip and formation.get_bounds().size.y > 1:
		flip_options.append(true)
	for flipped in flip_options:
		for y in height:
			for x in width:
				var anchor := Vector2i(x, y)
				if can_place(formation, anchor, flipped):
					var signature := _placement_signature(formation, anchor, flipped)
					if seen_placements.has(signature):
						continue
					seen_placements[signature] = true
					result.append({"anchor": anchor, "vertical_flipped": flipped})
	return result

func _placement_signature(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool) -> String:
	var parts := PackedStringArray()
	for entry in transformed_cells(formation, anchor, vertical_flipped):
		var cell: Vector2i = entry.cell
		parts.append("%d,%d:%s" % [cell.x, cell.y, String(entry.tower_id)])
	parts.sort()
	return "|".join(parts)

func place(placement_id: StringName, formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool = false, is_guard: bool = false) -> bool:
	if placement_id == &"" or placements.has(placement_id) or not can_place(formation, anchor, vertical_flipped):
		return false
	var cells := transformed_cells(formation, anchor, vertical_flipped)
	placements[placement_id] = {
		"formation_id": formation.id,
		"anchor": anchor,
		"vertical_flipped": vertical_flipped and formation.can_vertical_flip,
		"is_guard": is_guard,
		"cells": cells,
	}
	for entry in cells:
		occupied_cells[entry.cell as Vector2i] = placement_id
	return true

func remove(placement_id: StringName) -> bool:
	if not placements.has(placement_id):
		return false
	var placement := placements[placement_id] as Dictionary
	for entry in placement.get("cells", []):
		occupied_cells.erase((entry as Dictionary).cell as Vector2i)
	placements.erase(placement_id)
	return true

func move(placement_id: StringName, formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool = false) -> bool:
	if not placements.has(placement_id):
		return false
	var previous := (placements[placement_id] as Dictionary).duplicate(true)
	remove(placement_id)
	if place(placement_id, formation, anchor, vertical_flipped, bool(previous.get("is_guard", false))):
		return true
	place(
		placement_id,
		formation,
		previous.get("anchor", Vector2i.ZERO) as Vector2i,
		bool(previous.get("vertical_flipped", false)),
		bool(previous.get("is_guard", false))
	)
	return false

func get_occupied_count() -> int:
	return occupied_cells.size()

func get_empty_count() -> int:
	return maxi(width * height - forbidden_cells.size() - occupied_cells.size(), 0)

func get_occupancy_ratio() -> float:
	return float(get_occupied_count() + forbidden_cells.size()) / float(width * height)

func get_isolated_empty_cell_count() -> int:
	var result := 0
	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			if not is_empty(cell):
				continue
			var has_empty_neighbor := false
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if is_empty(cell + direction):
					has_empty_neighbor = true
					break
			if not has_empty_neighbor:
				result += 1
	return result

func build_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var placement_ids: Array = placements.keys()
	placement_ids.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	for placement_id in placement_ids:
		var placement := placements[placement_id] as Dictionary
		var cell_snapshot: Array[Dictionary] = []
		for entry in placement.get("cells", []):
			var cell_entry := entry as Dictionary
			var board_cell := cell_entry.cell as Vector2i
			cell_snapshot.append({
				"x": board_cell.x,
				"y": board_cell.y,
				"tower_id": String(cell_entry.tower_id),
			})
		var anchor := placement.get("anchor", Vector2i.ZERO) as Vector2i
		result.append({
			"placement_id": String(placement_id),
			"formation_id": String(placement.get("formation_id", &"")),
			"anchor_x": anchor.x,
			"anchor_y": anchor.y,
			"vertical_flipped": bool(placement.get("vertical_flipped", false)),
			"is_guard": bool(placement.get("is_guard", false)),
			"cells": cell_snapshot,
		})
	return result
