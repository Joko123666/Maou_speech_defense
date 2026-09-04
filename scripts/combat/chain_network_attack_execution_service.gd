class_name ChainNetworkAttackExecutionService
extends RefCounted

const SEGMENT_HALF_WIDTH := 20.0
const FORWARD_DAMAGE_FALLOFF := 0.86

func build_relay_path(source_column: TowerColumn, source_row: int, columns: Array[TowerColumn]) -> Array[Vector2]:
	if not is_instance_valid(source_column):
		return []
	var source_tower := source_column.get_tower_data(source_row)
	if source_tower == null or source_tower.behavior != &"chain":
		return []
	var source_origin := source_column.get_attack_origin(source_row)
	var link_range := source_column.get_chain_link_range(source_row)
	if link_range <= 0.0:
		return [source_origin]
	return build_path(source_origin, link_range, _collect_relay_points(source_column, source_row, columns))

func build_path(origin: Vector2, link_range: float, relay_points: Array[Vector2]) -> Array[Vector2]:
	var path: Array[Vector2] = [origin]
	if link_range <= 0.0:
		return path
	var remaining := relay_points.duplicate()
	while not remaining.is_empty():
		var nearest_index := _nearest_relay_index(path.back(), remaining, link_range)
		if nearest_index < 0:
			break
		path.append(remaining[nearest_index])
		remaining.remove_at(nearest_index)
	return path

func execute(
		relay_points: Array[Vector2],
		damage: float,
		network_multiplier: float,
		modifiers: Dictionary,
		target_query: Callable,
		forward_hit_callback: Callable,
		return_hit_callback: Callable
	) -> Dictionary:
	var forward_result := _execute_forward(
		relay_points,
		damage,
		network_multiplier,
		target_query,
		forward_hit_callback
	)
	var dealt := float(forward_result.dealt)
	var return_triggered := modifiers.has("relay_return")
	if return_triggered:
		dealt += _execute_return(
			relay_points,
			damage,
			network_multiplier,
			float(modifiers.relay_return),
			float(modifiers.get("relay_return_falloff", FORWARD_DAMAGE_FALLOFF)),
			target_query,
			return_hit_callback
		)
	return {
		"target": forward_result.target as Enemy,
		"dealt": dealt,
		"hit_count": int(forward_result.hit_count),
		"return_triggered": return_triggered,
	}

func _execute_forward(
		relay_points: Array[Vector2],
		damage: float,
		network_multiplier: float,
		target_query: Callable,
		forward_hit_callback: Callable
	) -> Dictionary:
	var target: Enemy
	var dealt := 0.0
	var hit_ids: Dictionary = {}
	for segment_index in range(relay_points.size() - 1):
		var segment_start := relay_points[segment_index]
		var segment_end := relay_points[segment_index + 1]
		for chain_target in _query_targets(target_query, segment_start, segment_end):
			var target_id := chain_target.get_instance_id()
			if hit_ids.has(target_id):
				continue
			hit_ids[target_id] = true
			if target == null:
				target = chain_target
			var relay_damage := damage * network_multiplier * pow(FORWARD_DAMAGE_FALLOFF, segment_index)
			dealt += float(forward_hit_callback.call(chain_target, segment_start, relay_damage))
	return {"target": target, "dealt": dealt, "hit_count": hit_ids.size()}

func _execute_return(
		relay_points: Array[Vector2],
		damage: float,
		network_multiplier: float,
		return_multiplier: float,
		return_falloff: float,
		target_query: Callable,
		return_hit_callback: Callable
	) -> float:
	var dealt := 0.0
	for segment_index in range(relay_points.size() - 2, -1, -1):
		var segment_start := relay_points[segment_index + 1]
		var segment_end := relay_points[segment_index]
		for return_target in _query_targets(target_query, segment_start, segment_end):
			var return_damage := damage * network_multiplier * return_multiplier * pow(return_falloff, segment_index)
			dealt += float(return_hit_callback.call(return_target, return_damage))
	return dealt

func _query_targets(target_query: Callable, segment_start: Vector2, segment_end: Vector2) -> Array[Enemy]:
	var targets: Array[Enemy] = []
	targets.assign(target_query.call(segment_start, segment_end, SEGMENT_HALF_WIDTH) as Array)
	return targets

func _collect_relay_points(source_column: TowerColumn, source_row: int, columns: Array[TowerColumn]) -> Array[Vector2]:
	var relay_points: Array[Vector2] = []
	var relay_columns: Array[TowerColumn] = columns.duplicate()
	if source_column not in relay_columns:
		relay_columns.append(source_column)
	for relay_column in relay_columns:
		if not is_instance_valid(relay_column):
			continue
		for relay_row in relay_column.row_towers.size():
			if relay_column == source_column and relay_row == source_row:
				continue
			var relay_tower := relay_column.get_tower_data(relay_row)
			if relay_tower != null and relay_tower.behavior == &"chain":
				relay_points.append(relay_column.get_attack_origin(relay_row))
	return relay_points

func _nearest_relay_index(origin: Vector2, relay_points: Array[Vector2], max_distance: float) -> int:
	var nearest_index := -1
	var nearest_distance_squared := max_distance * max_distance
	for relay_index in relay_points.size():
		var distance_squared := origin.distance_squared_to(relay_points[relay_index])
		if distance_squared <= nearest_distance_squared and (nearest_index < 0 or distance_squared < nearest_distance_squared):
			nearest_distance_squared = distance_squared
			nearest_index = relay_index
	return nearest_index
