class_name TargetingService
extends RefCounted

var density_queries := DensityQueryService.new()

func closest_to(enemies: Array, target_position: Vector2, prefer_boss: bool = false) -> Enemy:
	var result: Enemy
	var best_distance := INF
	for value in enemies:
		var enemy := value as Enemy
		if not _is_valid_target(enemy):
			continue
		var distance := enemy.global_position.distance_squared_to(target_position)
		if prefer_boss and enemy.data != null and enemy.data.is_boss:
			distance *= 0.0225
		if distance < best_distance or (is_equal_approx(distance, best_distance) and _stable_id(enemy) < _stable_id(result)):
			best_distance = distance
			result = enemy
	return result

func frontmost_to_core(enemies: Array[Enemy], core_position: Vector2) -> Enemy:
	var result: Enemy
	for enemy in enemies:
		if _is_valid_target(enemy) and _is_more_advanced(enemy, result, core_position):
			result = enemy
	return result

func lowest_current_health(enemies: Array[Enemy], core_position: Vector2) -> Enemy:
	var result: Enemy
	var best_health := INF
	for enemy in enemies:
		if not _is_valid_target(enemy):
			continue
		if enemy.current_health < best_health or (is_equal_approx(enemy.current_health, best_health) and _is_more_advanced(enemy, result, core_position)):
			best_health = enemy.current_health
			result = enemy
	return result

func highest_current_health(enemies: Array[Enemy], core_position: Vector2 = Vector2.ZERO) -> Enemy:
	var result: Enemy
	var best_health := -INF
	for enemy in enemies:
		if not _is_valid_target(enemy):
			continue
		if enemy.current_health > best_health or (is_equal_approx(enemy.current_health, best_health) and _is_more_advanced(enemy, result, core_position)):
			best_health = enemy.current_health
			result = enemy
	return result

func highest_breach_pressure(enemies: Array[Enemy], core_position: Vector2) -> Enemy:
	var result: Enemy
	var best_pressure := -INF
	for enemy in enemies:
		if not _is_valid_target(enemy) or enemy.data == null:
			continue
		var slow_power := float(enemy.statuses.get(&"slow", {}).get("power", 0.0))
		var haste_power := float(enemy.statuses.get(&"haste", {}).get("power", 0.0))
		var effective_speed := enemy.data.move_speed * enemy.speed_multiplier * (1.0 + haste_power) * (1.0 - clampf(slow_power, 0.0, 0.8))
		var remaining_distance := maxf(enemy.get_distance_to_core_face(), 24.0)
		var pressure := effective_speed / remaining_distance
		if pressure > best_pressure or (is_equal_approx(pressure, best_pressure) and _is_more_advanced(enemy, result, core_position)):
			best_pressure = pressure
			result = enemy
	return result

func highest_reward_value(enemies: Array[Enemy], core_position: Vector2) -> Enemy:
	var result: Enemy
	var best_score := -INF
	for enemy in enemies:
		if not _is_valid_target(enemy) or enemy.data == null:
			continue
		var missing_health_bonus := 2.0 - enemy.get_health_ratio()
		var score := enemy.data.experience_value * missing_health_bonus / sqrt(maxf(enemy.current_health, 1.0))
		if score > best_score or (is_equal_approx(score, best_score) and _is_more_advanced(enemy, result, core_position)):
			best_score = score
			result = enemy
	return result

func select_by_rule(
		enemies: Array[Enemy],
		rule: StringName,
		core_position: Vector2,
		cursor_position: Vector2,
		density_radius: float
	) -> Enemy:
	if enemies.is_empty():
		return null
	var candidates := _priority_candidates(enemies) if rule in [&"closest_core", &"breach_pressure", &"reward_value"] else enemies
	match rule:
		&"lowest_health":
			return lowest_current_health(candidates, core_position)
		&"highest_health":
			return highest_current_health(candidates, core_position)
		&"cursor_lane":
			return closest_to(candidates, cursor_position)
		&"density":
			return density_queries.select_densest(candidates, maxf(density_radius, 90.0), core_position)
		&"breach_pressure":
			return highest_breach_pressure(candidates, core_position)
		&"reward_value":
			return highest_reward_value(candidates, core_position)
	return frontmost_to_core(candidates, core_position)

func filter_in_radius(enemies: Array[Enemy], center: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var radius_squared := radius * radius
	for enemy in enemies:
		if _is_valid_target(enemy) and enemy.global_position.distance_squared_to(center) <= radius_squared:
			result.append(enemy)
	return result

func filter_in_horizontal_band(enemies: Array[Enemy], center_y: float, half_height: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in enemies:
		if _is_valid_target(enemy) and absf(enemy.global_position.y - center_y) <= half_height:
			result.append(enemy)
	return result

func filter_tower_range(
		enemies: Array[Enemy],
		origin: Vector2,
		attack_range: float,
		lane_center_y: float,
		lane_half_height: float,
		allow_cross_lane: bool
	) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var range_squared := attack_range * attack_range
	for enemy in enemies:
		if not _is_valid_target(enemy):
			continue
		if origin.distance_squared_to(enemy.global_position) > range_squared:
			continue
		if allow_cross_lane or absf(enemy.global_position.y - lane_center_y) <= lane_half_height:
			result.append(enemy)
	return result

func closest_other(enemies: Array[Enemy], source: Enemy, max_distance: float) -> Enemy:
	if not is_instance_valid(source):
		return null
	var result: Enemy
	var best_distance := max_distance
	for enemy in enemies:
		if enemy == source or not _is_valid_target(enemy):
			continue
		var distance := enemy.global_position.distance_to(source.global_position)
		if distance < best_distance:
			best_distance = distance
			result = enemy
	return result

func build_chain(enemies: Array[Enemy], first_target: Enemy, max_hops: int, hop_range: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	if first_target == null:
		return result
	result.append(first_target)
	var current := first_target
	while result.size() < max_hops:
		var next_target: Enemy
		var best_distance := hop_range
		for enemy in enemies:
			if enemy in result or not _is_valid_target(enemy):
				continue
			var distance := current.global_position.distance_to(enemy.global_position)
			if distance < best_distance:
				best_distance = distance
				next_target = enemy
		if next_target == null:
			break
		result.append(next_target)
		current = next_target
	return result

func _is_valid_target(enemy: Enemy) -> bool:
	return is_instance_valid(enemy) and enemy.active

func _priority_candidates(enemies: Array[Enemy]) -> Array[Enemy]:
	var highest_priority := 0.0
	for enemy in enemies:
		if _is_valid_target(enemy) and enemy.data != null:
			highest_priority = maxf(highest_priority, enemy.data.target_priority)
	if highest_priority <= 0.0:
		return enemies
	return enemies.filter(func(enemy: Enemy) -> bool: return _is_valid_target(enemy) and enemy.data != null and is_equal_approx(enemy.data.target_priority, highest_priority))

func _is_more_advanced(candidate: Enemy, current: Enemy, _core_position: Vector2) -> bool:
	if current == null:
		return true
	var candidate_progress := candidate.get_distance_to_core_face()
	var current_progress := current.get_distance_to_core_face()
	if not is_equal_approx(candidate_progress, current_progress):
		return candidate_progress < current_progress
	return _stable_id(candidate) < _stable_id(current)

func _stable_id(enemy: Enemy) -> int:
	return enemy.get_instance_id() if is_instance_valid(enemy) else 9223372036854775807
