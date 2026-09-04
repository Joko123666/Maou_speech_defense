class_name FormationBoardPreview
extends Control

var board_width: int = 6
var board_height: int = 4
var snapshot: Array = []
var guard_border_color: Color = Color("f4cf62")

func configure(board_snapshot: Array, width: int = 6, height: int = 4, candidate_id: StringName = &"") -> void:
	snapshot = board_snapshot.duplicate(true)
	board_width = maxi(width, 1)
	board_height = maxi(height, 1)
	guard_border_color = Color("f4cf62")
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate(candidate_id) if campaign != null and candidate_id != &"" else null
	var faction := campaign.faction(candidate.faction_id) if candidate != null else null
	if faction != null:
		guard_border_color = faction.accent_color
	queue_redraw()

func _draw() -> void:
	var gap := 3.0
	var cell_size := minf(
		(size.x - gap * float(board_width - 1)) / float(board_width),
		(size.y - gap * float(board_height - 1)) / float(board_height)
	)
	if cell_size <= 0.0:
		return
	var grid_size := Vector2(
		cell_size * board_width + gap * (board_width - 1),
		cell_size * board_height + gap * (board_height - 1)
	)
	var origin := (size - grid_size) * 0.5
	var occupied: Dictionary = {}
	for placement_value in snapshot:
		if placement_value is not Dictionary:
			continue
		var placement := placement_value as Dictionary
		for cell_value in placement.get("cells", []):
			if cell_value is not Dictionary:
				continue
			var cell := cell_value as Dictionary
			occupied[Vector2i(int(cell.get("x", -1)), int(cell.get("y", -1)))] = {
				"tower_id": StringName(cell.get("tower_id", "")),
				"is_guard": bool(placement.get("is_guard", false)),
			}
	for y in board_height:
		for x in board_width:
			var board_cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(x, y) * (cell_size + gap), Vector2.ONE * cell_size)
			var fill := Color("122431")
			var border := Color("315264")
			if occupied.has(board_cell):
				var entry := occupied[board_cell] as Dictionary
				var tower := DataRegistry.get_tower(entry.tower_id)
				fill = tower.color.darkened(0.28) if tower != null else Color("557180")
				border = guard_border_color if bool(entry.is_guard) else (tower.color.lightened(0.2) if tower != null else Color("a8bbc4"))
			draw_rect(rect, fill, true)
			draw_rect(rect, border, false, 2.0 if occupied.has(board_cell) else 1.0)
