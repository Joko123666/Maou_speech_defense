class_name EnemySpatialIndex
extends RefCounted

var cell_size: float = 160.0
var tracked_enemies: Array[Enemy] = []
var cells: Dictionary = {}
var enemy_cells: Dictionary = {}

func register_enemy(enemy: Enemy) -> void:
	if is_instance_valid(enemy) and enemy not in tracked_enemies:
		tracked_enemies.append(enemy)
		var key := _cell_for(enemy.global_position)
		enemy_cells[enemy.get_instance_id()] = key
		_add_to_cell(key, enemy)

func unregister_enemy(enemy: Enemy) -> void:
	if enemy == null:
		return
	tracked_enemies.erase(enemy)
	var instance_id := enemy.get_instance_id()
	if enemy_cells.has(instance_id):
		_remove_from_cell(enemy_cells[instance_id] as Vector2i, enemy)
		enemy_cells.erase(instance_id)

func update_enemy(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy not in tracked_enemies:
		return
	var instance_id := enemy.get_instance_id()
	var next_key := _cell_for(enemy.global_position)
	var previous_key: Vector2i = enemy_cells.get(instance_id, next_key)
	if previous_key == next_key:
		return
	_remove_from_cell(previous_key, enemy)
	enemy_cells[instance_id] = next_key
	_add_to_cell(next_key, enemy)

func get_active_enemies() -> Array[Enemy]:
	var active: Array[Enemy] = []
	var retained: Array[Enemy] = []
	for enemy in tracked_enemies:
		if not is_instance_valid(enemy):
			continue
		retained.append(enemy)
		if enemy.active:
			active.append(enemy)
	tracked_enemies = retained
	return active

func query_radius(center: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var radius_squared := radius * radius
	var minimum_cell := _cell_for(center - Vector2.ONE * radius)
	var maximum_cell := _cell_for(center + Vector2.ONE * radius)
	for cell_x in range(minimum_cell.x, maximum_cell.x + 1):
		for cell_y in range(minimum_cell.y, maximum_cell.y + 1):
			var key := Vector2i(cell_x, cell_y)
			var cell_enemies: Array = cells.get(key, [])
			for value in cell_enemies:
				var enemy := value as Enemy
				if is_instance_valid(enemy) and enemy.active and enemy.global_position.distance_squared_to(center) <= radius_squared:
					result.append(enemy)
	return result

func query_segment(start: Vector2, finish: Vector2, padding: float = 80.0) -> Array[Enemy]:
	var center := start.lerp(finish, 0.5)
	var broadphase_radius := start.distance_to(finish) * 0.5 + maxf(padding, 0.0)
	return query_radius(center, broadphase_radius)

func clear() -> void:
	tracked_enemies.clear()
	cells.clear()
	enemy_cells.clear()

func _add_to_cell(key: Vector2i, enemy: Enemy) -> void:
	var cell_enemies: Array = cells.get(key, [])
	if enemy not in cell_enemies:
		cell_enemies.append(enemy)
	cells[key] = cell_enemies

func _remove_from_cell(key: Vector2i, enemy: Enemy) -> void:
	if not cells.has(key):
		return
	var cell_enemies: Array = cells[key]
	cell_enemies.erase(enemy)
	if cell_enemies.is_empty():
		cells.erase(key)
	else:
		cells[key] = cell_enemies

func _cell_for(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / cell_size), floori(world_position.y / cell_size))
