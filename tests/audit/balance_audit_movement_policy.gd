class_name BalanceAuditMovementPolicy
extends RefCounted

var id: StringName = &"high"
var recovery_active := false
var recovery_empty_grace := 0
var last_recovery_position := Vector2.ZERO
var recovery_patrol_index := 0

func _init(policy_id: StringName = &"high") -> void:
	id = policy_id if policy_id in BalanceAuditSkillPolicy.IDS else &"high"

func command_interval() -> float:
	return float({&"high": 0.75, &"average": 1.75, &"low": 4.5}.get(id, 1.75))

func choose_destination(game: GameController) -> Dictionary:
	if game == null or id == &"low":
		return {}
	var enemies := game._active_enemies()
	if enemies.is_empty():
		return {}
	var closest_regular: Enemy
	var closest_regular_distance := INF
	var bosses: Array[Enemy] = []
	for enemy in enemies:
		if enemy.data.is_boss:
			bosses.append(enemy)
		else:
			var breach_distance := enemy.get_distance_to_core_face()
			if breach_distance < closest_regular_distance:
				closest_regular = enemy
				closest_regular_distance = breach_distance
	if id == &"high":
		var emergency_ratio := 0.65 if bosses.is_empty() else 2.0
		if closest_regular != null and closest_regular_distance <= game.battlefield.get_column_spacing() * emergency_ratio:
			return {"position": Vector2(game.core.global_position.x + game.battlefield.get_column_spacing() * 0.8, closest_regular.global_position.y), "reason": "visible breach interception", "target_enemy_id": String(closest_regular.data.id)}
	var recovery := _experience_recovery_destination(game, enemies)
	if not recovery.is_empty():
		return recovery
	var candidates: Array[Enemy] = bosses if id == &"high" and not bosses.is_empty() else enemies
	var target := candidates[0]
	var best_distance := target.global_position.distance_squared_to(game.core.global_position)
	for enemy in candidates:
		var distance := enemy.global_position.distance_squared_to(game.core.global_position)
		if distance < best_distance:
			target = enemy
			best_distance = distance
	return {"position": target.global_position, "reason": "visible %s threat" % ("boss" if target.data.is_boss else "nearest"), "target_enemy_id": String(target.data.id)}

func _experience_recovery_destination(game: GameController, enemies: Array[Enemy]) -> Dictionary:
	if game.target_cursor == null:
		return {}
	var closest_breach_distance := INF
	for enemy in enemies:
		closest_breach_distance = minf(closest_breach_distance, enemy.get_distance_to_core_face())
	var enter_columns := 1.5 if id == &"high" else 2.5
	var column_spacing := game.battlefield.get_column_spacing()
	if id == &"average" and recovery_active:
		return _next_recovery_patrol(game)
	if recovery_active:
		if id == &"high" and closest_breach_distance <= column_spacing * 0.9:
			recovery_active = false
			return {}
	elif closest_breach_distance <= column_spacing * enter_columns:
		return {}
	else:
		recovery_active = true
	var orbs: Array[ExperienceOrb] = []
	for node in game.get_tree().get_nodes_in_group(&"experience_orbs"):
		var orb := node as ExperienceOrb
		if orb != null and not orb.is_queued_for_deletion() and orb.source_channel == &"base":
			orbs.append(orb)
	if orbs.is_empty():
		if recovery_active and recovery_empty_grace < 1 and last_recovery_position != Vector2.ZERO:
			recovery_empty_grace += 1
			return {
				"position": last_recovery_position,
				"reason": "visible safe Base XP recovery",
				"target_orb_channel": "base",
			}
		recovery_active = false
		recovery_empty_grace = 0
		return {}
	recovery_empty_grace = 0
	if id == &"average":
		recovery_active = true
		return _next_recovery_patrol(game)
	# Moving orb coordinates differ by sub-frames across speed multipliers. Aggregate
	# immutable drop origins into fixed cells so the audit agent makes the same
	# decision at 1x, 2x, and 3x while still pursuing the richest visible cluster.
	var collection_radius := maxf(game.target_cursor.get_effective_collection_radius() * ExperienceRewardService.BASE_ORB_COLLECTION_RADIUS_MULTIPLIER, 1.0)
	var cell_size := maxf(collection_radius * 1.25, 32.0)
	var cluster_values := {}
	for orb in orbs:
		var cell := Vector2i(floori(orb.spawn_origin.x / cell_size), floori(orb.spawn_origin.y / cell_size))
		cluster_values[cell] = float(cluster_values.get(cell, 0.0)) + maxf(orb.value, 0.0)
	var best_cell := Vector2i.ZERO
	var best_value := -INF
	var best_core_distance := INF
	for cell_value in cluster_values:
		var cell := cell_value as Vector2i
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
		var cluster_value := float(cluster_values[cell])
		var core_distance := center.distance_squared_to(game.core.global_position)
		if cluster_value > best_value or (is_equal_approx(cluster_value, best_value) and (core_distance < best_core_distance or (is_equal_approx(core_distance, best_core_distance) and _cell_precedes(cell, best_cell)))):
			best_cell = cell
			best_value = cluster_value
			best_core_distance = core_distance
	last_recovery_position = (Vector2(best_cell) + Vector2(0.5, 0.5)) * cell_size
	return {
		"position": last_recovery_position,
		"reason": "visible safe Base XP recovery",
		"target_orb_channel": "base",
	}

func _cell_precedes(left: Vector2i, right: Vector2i) -> bool:
	return left.x < right.x or (left.x == right.x and left.y < right.y)

func _next_recovery_patrol(game: GameController) -> Dictionary:
	var points := [
		Vector2(0.78, 0.78),
		Vector2(0.78, 0.78),
		Vector2(0.78, 0.18),
		Vector2(0.78, 0.58),
		Vector2(0.78, 0.18),
		Vector2(0.58, 0.78),
		Vector2(0.58, 0.78),
		Vector2(0.58, 0.78),
		Vector2(0.58, 0.18),
		Vector2(0.58, 0.18),
		Vector2(0.58, 0.18),
		Vector2(0.58, 0.18),
		Vector2(0.78, 0.58),
		Vector2(0.98, 0.58),
		Vector2(0.58, 0.78),
		Vector2(0.58, 0.78),
	]
	var normalized: Vector2 = points[recovery_patrol_index % points.size()]
	recovery_patrol_index += 1
	var rect := game.battlefield.get_battle_rect()
	last_recovery_position = rect.position + rect.size * normalized
	return {
		"position": last_recovery_position,
		"reason": "visible safe Base XP recovery",
		"target_orb_channel": "base",
	}
