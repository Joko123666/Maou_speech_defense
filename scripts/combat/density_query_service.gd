class_name DensityQueryService
extends RefCounted

func select_densest(enemies: Array[Enemy], radius: float, tie_break_position: Vector2) -> Enemy:
	if enemies.is_empty():
		return null
	var safe_radius := maxf(radius, 1.0)
	var density_cells: Dictionary = {}
	for enemy in enemies:
		if not _is_valid_target(enemy):
			continue
		var key := _cell_for(enemy.global_position, safe_radius)
		var cell_enemies: Array = density_cells.get(key, [])
		cell_enemies.append(enemy)
		density_cells[key] = cell_enemies
	var result: Enemy
	var best_neighbors := -1
	var best_progress := INF
	var best_vertical_distance := INF
	var best_id := 9223372036854775807
	var radius_squared := safe_radius * safe_radius
	for candidate in enemies:
		if not _is_valid_target(candidate):
			continue
		var neighbors := 0
		var candidate_cell := _cell_for(candidate.global_position, safe_radius)
		for cell_x in range(candidate_cell.x - 1, candidate_cell.x + 2):
			for cell_y in range(candidate_cell.y - 1, candidate_cell.y + 2):
				var nearby: Array = density_cells.get(Vector2i(cell_x, cell_y), [])
				for other_value in nearby:
					var other := other_value as Enemy
					if _is_valid_target(other) and candidate.global_position.distance_squared_to(other.global_position) <= radius_squared:
						neighbors += 1
		var progress := absf(candidate.global_position.x - tie_break_position.x)
		var vertical_distance := absf(candidate.global_position.y - tie_break_position.y)
		var candidate_id := candidate.get_instance_id()
		var better_tie := progress < best_progress or (is_equal_approx(progress, best_progress) and (vertical_distance < best_vertical_distance or (is_equal_approx(vertical_distance, best_vertical_distance) and candidate_id < best_id)))
		if neighbors > best_neighbors or (neighbors == best_neighbors and better_tie):
			result = candidate
			best_neighbors = neighbors
			best_progress = progress
			best_vertical_distance = vertical_distance
			best_id = candidate_id
	return result

func count_neighbors(candidate: Enemy, enemies: Array[Enemy], radius: float) -> int:
	if not _is_valid_target(candidate):
		return 0
	var result := 0
	var radius_squared := radius * radius
	for other in enemies:
		if _is_valid_target(other) and candidate.global_position.distance_squared_to(other.global_position) <= radius_squared:
			result += 1
	return result

func _is_valid_target(enemy: Enemy) -> bool:
	return is_instance_valid(enemy) and enemy.active

func _cell_for(world_position: Vector2, size: float) -> Vector2i:
	return Vector2i(floori(world_position.x / size), floori(world_position.y / size))
