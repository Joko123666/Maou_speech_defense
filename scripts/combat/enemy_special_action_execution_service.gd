class_name EnemySpecialActionExecutionService
extends RefCounted

const SHIFT_MINIMUM_DISTANCE := 90.0
const SHIFT_MAXIMUM_DISTANCE := 175.0
const SHIFT_EDGE_MARGIN := 20.0
const CLEANSE_RADIUS := 150.0
const SUPPORT_RADIUS := 170.0
const FORTIFY_RADIUS := 175.0
const SUPPORT_DURATION := 3.5
const SUPPORT_POWER := 0.22
const FORTIFY_DURATION := 3.5
const FORTIFY_POWER := 5.0
const NORMAL_DISABLE_DURATION := 3.0
const BOSS_DISABLE_DURATION := 5.0
const REINFORCEMENT_COUNT := 3
const REINFORCEMENT_HEALTH_MULTIPLIER := 1.4
const REINFORCEMENT_SPEED_MULTIPLIER := 1.15

func execute(
		action: StringName,
		source: Enemy,
		battle_rect_callback: Callable,
		roll_callback: Callable,
		range_callback: Callable,
		pick_callback: Callable,
		radius_query_callback: Callable,
		lane_callback: Callable,
		move_callback: Callable,
		disable_column_callback: Callable,
		reinforcement_pool_callback: Callable,
		clamp_position_callback: Callable,
		spawn_callback: Callable
	) -> Dictionary:
	var result := _empty_result(action)
	if not is_instance_valid(source):
		result.reason = &"invalid_source"
		return result
	match action:
		&"shift_position":
			return _execute_shift(source, battle_rect_callback, roll_callback, range_callback, lane_callback, move_callback, result)
		&"cleanse_area":
			return _execute_cleanse(source, radius_query_callback, result)
		&"support_buff":
			return _execute_area_status(source, SUPPORT_RADIUS, &"haste", SUPPORT_DURATION, SUPPORT_POWER, radius_query_callback, result)
		&"fortify_area":
			return _execute_area_status(source, FORTIFY_RADIUS, &"fortify", FORTIFY_DURATION, FORTIFY_POWER, radius_query_callback, result)
		&"disable_column":
			return _execute_disable(source, disable_column_callback, result)
		&"summon":
			return _execute_reinforcements(source, reinforcement_pool_callback, pick_callback, clamp_position_callback, lane_callback, spawn_callback, result)
	result.reason = &"unknown_action"
	return result

func _execute_shift(source: Enemy, battle_rect_callback: Callable, roll_callback: Callable, range_callback: Callable, lane_callback: Callable, move_callback: Callable, result: Dictionary) -> Dictionary:
	if not battle_rect_callback.is_valid() or not roll_callback.is_valid() or not range_callback.is_valid() or not lane_callback.is_valid() or not move_callback.is_valid():
		return result
	var rect: Rect2 = battle_rect_callback.call()
	var direction := -1.0 if float(roll_callback.call()) < 0.5 else 1.0
	var first_distance := float(range_callback.call(SHIFT_MINIMUM_DISTANCE, SHIFT_MAXIMUM_DISTANCE))
	var shifted_y := source.global_position.y + direction * first_distance
	var minimum_y := rect.position.y + SHIFT_EDGE_MARGIN
	var maximum_y := rect.end.y - SHIFT_EDGE_MARGIN
	if shifted_y < minimum_y or shifted_y > maximum_y:
		result.reversed_at_edge = true
		result.second_distance = float(range_callback.call(SHIFT_MINIMUM_DISTANCE, SHIFT_MAXIMUM_DISTANCE))
		shifted_y = source.global_position.y - direction * float(result.second_distance)
	shifted_y = clampf(shifted_y, minimum_y, maximum_y)
	var lane := int(lane_callback.call(Vector2(source.global_position.x, shifted_y)))
	move_callback.call(shifted_y, lane)
	result.applied = true
	result.reason = &"resolved"
	result.direction = direction
	result.first_distance = first_distance
	result.shifted_y = shifted_y
	result.lane = lane
	return result

func _execute_cleanse(source: Enemy, radius_query_callback: Callable, result: Dictionary) -> Dictionary:
	if not radius_query_callback.is_valid():
		return result
	result.radius = CLEANSE_RADIUS
	var targets := _query_targets(source.global_position, CLEANSE_RADIUS, radius_query_callback)
	for enemy in targets:
		enemy.clear_statuses()
	result.applied = true
	result.reason = &"resolved"
	result.affected_count = targets.size()
	result.targets = targets
	return result

func _execute_area_status(source: Enemy, radius: float, status_id: StringName, duration: float, power: float, radius_query_callback: Callable, result: Dictionary) -> Dictionary:
	if not radius_query_callback.is_valid():
		return result
	result.radius = radius
	result.status_id = status_id
	result.duration = duration
	result.power = power
	var targets := _query_targets(source.global_position, radius, radius_query_callback)
	for enemy in targets:
		if enemy.apply_status(status_id, duration, power):
			(result.targets as Array[Enemy]).append(enemy)
			result.affected_count = int(result.affected_count) + 1
	result.applied = true
	result.reason = &"resolved"
	return result

func _execute_disable(source: Enemy, disable_column_callback: Callable, result: Dictionary) -> Dictionary:
	if source.data == null:
		result.reason = &"missing_source_data"
		return result
	if not disable_column_callback.is_valid():
		return result
	result.disable_duration = BOSS_DISABLE_DURATION if source.data.is_boss else NORMAL_DISABLE_DURATION
	disable_column_callback.call(float(result.disable_duration))
	result.applied = true
	result.reason = &"resolved"
	result.is_boss = source.data.is_boss
	return result

func _execute_reinforcements(source: Enemy, reinforcement_pool_callback: Callable, pick_callback: Callable, clamp_position_callback: Callable, lane_callback: Callable, spawn_callback: Callable, result: Dictionary) -> Dictionary:
	if not reinforcement_pool_callback.is_valid() or not pick_callback.is_valid() or not clamp_position_callback.is_valid() or not lane_callback.is_valid() or not spawn_callback.is_valid():
		return result
	var pool: Array[EnemyData] = []
	pool.assign(reinforcement_pool_callback.call() as Array)
	if pool.is_empty():
		result.reason = &"empty_pool"
		return result
	result.requested_count = REINFORCEMENT_COUNT
	for index in REINFORCEMENT_COUNT:
		var summon_data := pick_callback.call(pool) as EnemyData
		if summon_data == null:
			continue
		var summon_angle := -0.55 + index * 0.55
		var raw_position := source.position + Vector2.from_angle(summon_angle) * (48.0 + index * 16.0)
		var summon_position: Vector2 = clamp_position_callback.call(raw_position)
		var lane := int(lane_callback.call(summon_position))
		var spawned := spawn_callback.call(summon_data, summon_position, lane, REINFORCEMENT_HEALTH_MULTIPLIER, REINFORCEMENT_SPEED_MULTIPLIER) as Enemy
		(result.reinforcements as Array[Dictionary]).append({"data": summon_data, "angle": summon_angle, "raw_position": raw_position, "position": summon_position, "lane": lane, "spawned": spawned})
		if is_instance_valid(spawned):
			result.spawned_count = int(result.spawned_count) + 1
	result.applied = true
	result.reason = &"resolved"
	return result

func _query_targets(center: Vector2, radius: float, radius_query_callback: Callable) -> Array[Enemy]:
	var result: Array[Enemy] = []
	result.assign(radius_query_callback.call(center, radius) as Array)
	return result.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy))

func _empty_result(action: StringName) -> Dictionary:
	return {
		"applied": false,
		"reason": &"invalid_dependencies",
		"action": action,
		"affected_count": 0,
		"targets": [] as Array[Enemy],
		"radius": 0.0,
		"status_id": &"",
		"duration": 0.0,
		"power": 0.0,
		"direction": 0.0,
		"first_distance": 0.0,
		"second_distance": 0.0,
		"reversed_at_edge": false,
		"shifted_y": 0.0,
		"lane": -1,
		"disable_duration": 0.0,
		"is_boss": false,
		"requested_count": 0,
		"spawned_count": 0,
		"reinforcements": [] as Array[Dictionary],
	}
