class_name GuardAbilityController
extends RefCounted

var frenzy_states: Dictionary = {}

func resolve_confirmed_attack(column: TowerColumn, row_index: int, tower: TowerData, impact_position: Vector2, attack_damage: float, hit_count: int, loadout: LoadoutManager, spatial_index: EnemySpatialIndex) -> Dictionary:
	var result := {"damage": 0.0, "hit_count": 0, "mode": &"", "position": impact_position, "radius": 0.0, "devotion_added": 0}
	if column == null or tower == null or not column.is_guard_formation or tower.id != &"sapphire_lance" or hit_count <= 0:
		return result
	if bool(loadout.get_guard_modifier(&"guard_devotion", false)):
		var maximum := maxi(int(loadout.get_guard_modifier(&"guard_devotion_max_stacks", 30)), 1)
		var stack_gain := maxi(int(loadout.get_guard_modifier(&"guard_devotion_stacks_per_hit", 1)), 1) * hit_count
		var previous := loadout.get_guard_runtime_value(&"devotion")
		var current := loadout.add_guard_runtime_value(&"devotion", stack_gain, maximum)
		result.devotion_added = roundi(current - previous)
	if bool(loadout.get_guard_modifier(&"guard_hit_shockwave", false)):
		var radius := float(loadout.get_guard_modifier(&"guard_hit_shockwave_radius", 76.0))
		var shockwave_damage := attack_damage * float(loadout.get_guard_modifier(&"guard_hit_shockwave_damage", 0.42))
		var targets := spatial_index.query_radius(impact_position, radius)
		for enemy in targets:
			result["damage"] = float(result.damage) + enemy.take_damage(shockwave_damage, &"guard_shockwave", true)
		result.hit_count = targets.size()
		result.mode = &"shockwave"
		result.radius = radius
	return result

func consume_candidate_active(columns: Array[TowerColumn], loadout: LoadoutManager, base_duration: float) -> Dictionary:
	var result := {"consumed_stacks": 0, "extension": 0.0, "disabled_duration": 0.0}
	if not bool(loadout.get_guard_modifier(&"guard_devotion", false)):
		return result
	var consumed := roundi(loadout.consume_guard_runtime_value(&"devotion"))
	var extension := devotion_extension(
		consumed,
		float(loadout.get_guard_modifier(&"guard_devotion_extension_per_stack", 0.1)),
		float(loadout.get_guard_modifier(&"guard_devotion_max_extension", 3.0))
	)
	var disabled_duration := maxf(base_duration, 0.1) + extension
	for column in columns:
		if not column.is_guard_formation:
			continue
		for row_index in column.row_towers.size():
			var tower := column.get_tower_data(row_index)
			if tower != null and tower.id == &"sapphire_lance":
				column.disable_row_for(row_index, disabled_duration)
	result.consumed_stacks = consumed
	result.extension = extension
	result.disabled_duration = disabled_duration
	return result

static func devotion_extension(stacks: int, seconds_per_stack: float, maximum_extension: float) -> float:
	return minf(maxi(stacks, 0) * maxf(seconds_per_stack, 0.0), maxf(maximum_extension, 0.0))

func is_attack_suppressed(column: TowerColumn, row_index: int) -> bool:
	var state: Dictionary = frenzy_states.get(_frenzy_key(column, row_index), {})
	return state.get("phase", &"idle") in [&"frenzy", &"return"]

func update_frenzy(delta: float, columns: Array[TowerColumn], loadout: LoadoutManager, spatial_index: EnemySpatialIndex, battle_rect: Rect2, tower_damage_multiplier: float, column_damage_multiplier: Callable) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not bool(loadout.get_guard_modifier(&"guard_frenzy", false)):
		_reset_frenzy_offsets()
		return events
	var active_keys: Dictionary = {}
	var interval := maxf(float(loadout.get_guard_modifier(&"guard_frenzy_interval", 10.0)), 1.0)
	var duration := maxf(float(loadout.get_guard_modifier(&"guard_frenzy_duration", 2.8)), 0.2)
	var movement_speed := maxf(float(loadout.get_guard_modifier(&"guard_frenzy_movement_speed", 170.0)), 1.0)
	var hit_radius := maxf(float(loadout.get_guard_modifier(&"guard_frenzy_radius", 42.0)), 8.0)
	var damage_ratio := maxf(float(loadout.get_guard_modifier(&"guard_frenzy_damage", 0.55)), 0.0)
	for column in columns:
		if not column.is_guard_formation:
			continue
		for row_index in column.row_towers.size():
			var tower := column.get_tower_data(row_index)
			if tower == null or tower.id != &"sapphire_lance":
				continue
			var key := _frenzy_key(column, row_index)
			active_keys[key] = true
			var state: Dictionary = frenzy_states.get(key, {
				"column": column, "row_index": row_index, "phase": &"idle",
				"cooldown": interval * (0.72 + float((column.column_index + row_index) % 4) * 0.08),
				"remaining": 0.0, "retarget": 0.0, "damage_tick": 0.0, "target": column.get_base_attack_origin(row_index),
			})
			var phase: StringName = state.get("phase", &"idle") as StringName
			if phase == &"idle":
				state.cooldown = float(state.get("cooldown", interval)) - delta
				if float(state.cooldown) <= 0.0:
					state.phase = &"frenzy"
					state.remaining = duration
					state.retarget = 0.0
					state.damage_tick = 0.0
					events.append({"type": &"frenzy_started", "column": column, "row_index": row_index, "tower": tower})
			elif phase == &"frenzy":
				state.remaining = float(state.get("remaining", duration)) - delta
				state.retarget = float(state.get("retarget", 0.0)) - delta
				state.damage_tick = float(state.get("damage_tick", 0.0)) - delta
				var current_position := column.get_attack_origin(row_index)
				var target_position := state.get("target", current_position) as Vector2
				if float(state.retarget) <= 0.0 or current_position.distance_to(target_position) <= 14.0:
					target_position = _random_battle_position(battle_rect)
					state.target = target_position
					state.retarget = 0.62
				var next_position := current_position.move_toward(target_position, movement_speed * delta)
				column.set_mobile_tower_offset(row_index, next_position - column.get_base_attack_origin(row_index))
				if float(state.damage_tick) <= 0.0:
					state.damage_tick = 0.22
					var dealt := 0.0
					var targets := spatial_index.query_radius(next_position, hit_radius)
					var tracked_enemies: Array[Enemy] = targets.duplicate()
					var contact_damage := column.get_damage(row_index) * tower_damage_multiplier * float(column_damage_multiplier.call(column)) * damage_ratio
					for enemy in targets:
						dealt += enemy.take_damage(contact_damage, &"guard_frenzy", true)
					if not targets.is_empty():
						events.append({
							"type": &"frenzy_hit", "column": column, "row_index": row_index, "tower": tower,
							"position": next_position, "radius": hit_radius, "damage": dealt,
							"hit_count": targets.size(), "tracked_enemies": tracked_enemies,
						})
				if float(state.remaining) <= 0.0:
					state.phase = &"return"
			elif phase == &"return":
				var offset := column.get_mobile_tower_offset(row_index).move_toward(Vector2.ZERO, movement_speed * 1.35 * delta)
				column.set_mobile_tower_offset(row_index, offset)
				if offset.is_zero_approx():
					state.phase = &"idle"
					state.cooldown = interval
					events.append({"type": &"frenzy_ended", "column": column, "row_index": row_index, "tower": tower})
			frenzy_states[key] = state
	for key in frenzy_states.keys():
		if not active_keys.has(key):
			var stale: Dictionary = frenzy_states[key]
			var stale_column := stale.get("column") as TowerColumn
			if is_instance_valid(stale_column):
				stale_column.set_mobile_tower_offset(int(stale.get("row_index", -1)), Vector2.ZERO)
			frenzy_states.erase(key)
	return events

func _reset_frenzy_offsets() -> void:
	for state_value in frenzy_states.values():
		var state := state_value as Dictionary
		var column := state.get("column") as TowerColumn
		if is_instance_valid(column):
			column.set_mobile_tower_offset(int(state.get("row_index", -1)), Vector2.ZERO)
	frenzy_states.clear()

func _frenzy_key(column: TowerColumn, row_index: int) -> String:
	return "%d:%d" % [column.get_instance_id() if is_instance_valid(column) else 0, row_index]

func _random_battle_position(battle_rect: Rect2) -> Vector2:
	var horizontal_margin := minf(48.0, battle_rect.size.x * 0.2)
	var vertical_margin := minf(42.0, battle_rect.size.y * 0.2)
	return Vector2(
		RunRng.rangef(battle_rect.position.x + horizontal_margin, battle_rect.end.x - horizontal_margin),
		RunRng.rangef(battle_rect.position.y + vertical_margin, battle_rect.end.y - vertical_margin)
	)

func resolve_projectile(column: TowerColumn, row_index: int, tower: TowerData, hit_target: Enemy, impact_position: Vector2, damage: float, attack_count: int, loadout: LoadoutManager, spatial_index: EnemySpatialIndex) -> Dictionary:
	var result := {"damage": 0.0, "mode": &"", "origin": impact_position, "end": impact_position, "position": impact_position, "radius": 0.0, "width": 0.0, "mechanic_id": &""}
	if tower == null or tower.id != &"emerald_guardian":
		return result
	var knockback_multiplier := float(loadout.get_guard_modifier(&"guard_knockback", 1.0)) if column.is_guard_formation else 1.0
	if is_instance_valid(hit_target) and hit_target.active:
		hit_target.apply_knockback(tower.status_power * knockback_multiplier)
	if not column.is_guard_formation:
		return result
	var profile := get_partason_auto_skill_profile(loadout)
	var mode: StringName = profile.get("mode", &"") as StringName
	var cycle := int(profile.get("cycle", 0))
	if bool(profile.get("disabled", false)) or mode == &"" or cycle <= 0 or attack_count <= 0 or attack_count % cycle != 0:
		return result
	var skill_damage := damage * float(profile.get("damage", 1.0))
	match mode:
		&"royal":
			var radius := float(profile.get("radius", 88.0))
			for enemy in spatial_index.query_radius(impact_position, radius):
				result["damage"] = float(result.damage) + enemy.take_damage(skill_damage, &"guard_royal", true)
			result.mode = mode
			result.radius = radius
			result.mechanic_id = &"partason_guard_royal"
		&"shield":
			var radius := float(profile.get("radius", 105.0))
			var push := float(loadout.get_guard_modifier(&"guard_auto_skill_knockback", 78.0))
			for enemy in spatial_index.query_radius(impact_position, radius):
				result["damage"] = float(result.damage) + enemy.take_damage(skill_damage, &"guard_shield", true)
				enemy.apply_knockback(push)
			result.mode = mode
			result.radius = radius
			result.mechanic_id = &"partason_guard_shield"
		&"sword":
			var origin := column.get_attack_origin(row_index)
			var direction := origin.direction_to(impact_position)
			if direction.is_zero_approx():
				direction = Vector2.RIGHT
			var end := origin + direction * column.get_attack_range(row_index)
			var width := float(loadout.get_guard_modifier(&"guard_auto_skill_width", 42.0))
			for enemy in _enemies_near_segment(spatial_index.get_active_enemies(), origin, end, width):
				result["damage"] = float(result.damage) + enemy.take_damage(skill_damage, &"guard_sword", true)
			result.mode = mode
			result.origin = origin
			result.end = end
			result.width = width
			result.mechanic_id = &"partason_guard_sword"
	return result

func get_partason_auto_skill_profile(loadout: LoadoutManager) -> Dictionary:
	if loadout == null:
		return {"disabled": true, "mode": &"", "cycle": 0, "damage": 0.0, "radius": 0.0}
	var disabled := bool(loadout.get_guard_modifier(&"guard_auto_skill_disabled", false))
	var mode: StringName = loadout.get_guard_modifier(&"guard_auto_skill_mode", &"royal") as StringName
	var cycle := maxi(int(loadout.get_guard_modifier(&"guard_auto_skill_cycle", 6)), 0)
	var base_damage := 0.62 if mode == &"royal" else 1.0
	var guard_damage := float(loadout.get_guard_modifier(&"guard_auto_skill_damage", base_damage))
	var candidate_damage := float(loadout.get_candidate_modifier(&"guard_auto_skill_damage", 1.0))
	var default_radius := 88.0 if mode == &"royal" else 105.0
	return {
		"disabled": disabled,
		"mode": mode,
		"cycle": cycle,
		"damage": guard_damage * candidate_damage,
		"radius": float(loadout.get_guard_modifier(&"guard_auto_skill_radius", default_radius)),
	}

func resolve_core_active(columns: Array[TowerColumn], loadout: LoadoutManager, spatial_index: EnemySpatialIndex, select_target: Callable, tower_damage_multiplier: float, column_damage_multiplier: Callable) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not bool(loadout.get_guard_modifier(&"guard_core_active_cast", false)):
		return results
	var radius := float(loadout.get_guard_modifier(&"guard_linked_skill_radius", 92.0))
	var damage_multiplier := float(loadout.get_guard_modifier(&"guard_linked_skill_damage", 0.72))
	var push := float(loadout.get_guard_modifier(&"guard_linked_skill_knockback", 80.0))
	for column in columns:
		if not column.is_guard_formation:
			continue
		for row_index in column.row_towers.size():
			var tower := column.get_tower_data(row_index)
			if tower == null or tower.id != &"emerald_guardian":
				continue
			var origin := column.get_attack_origin(row_index)
			var candidates := spatial_index.query_radius(origin, column.get_attack_range(row_index))
			var target := select_target.call(candidates, column, tower) as Enemy
			if target == null:
				continue
			var tracked_enemies: Array[Enemy] = spatial_index.get_active_enemies().duplicate()
			var impact_position := target.global_position
			var dealt := 0.0
			var hit_count := 0
			var linked_damage := column.get_damage(row_index) * tower_damage_multiplier * float(column_damage_multiplier.call(column)) * damage_multiplier
			for enemy in spatial_index.query_radius(impact_position, radius):
				dealt += enemy.take_damage(linked_damage, &"guard_liege", true)
				enemy.apply_knockback(push)
				hit_count += 1
			results.append({
				"column": column, "tower": tower, "origin": origin, "impact_position": impact_position,
				"radius": radius, "damage": dealt, "hit_count": hit_count, "tracked_enemies": tracked_enemies,
			})
	return results

func _enemies_near_segment(enemies: Array[Enemy], start: Vector2, end: Vector2, half_width: float) -> Array[Enemy]:
	return enemies.filter(func(enemy: Enemy) -> bool:
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		return enemy.global_position.distance_to(closest) <= half_width
	)
