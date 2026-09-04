class_name CoreAttackExecutionService
extends RefCounted

const DEFAULT_PIERCE_HALF_WIDTH := 64.0
const DEFAULT_RAIL_HALF_WIDTH := 64.0
const DEFAULT_LUCKY_MIN := 0.35
const DEFAULT_LUCKY_MAX := 2.0
const STABLE_CRITICAL_MULTIPLIER := 1.8
const PRISM_REFRACT_RANGE := 260.0
const PIERCE_EXPLOSION_RADIUS := 105.0
const PIERCE_CHAIN_RANGE := 220.0
const HIGHROLL_THRESHOLD := 2.4
const HIGHROLL_EXPLOSION_RADIUS := 120.0
const LUCKY_CHAIN_RANGE := 210.0

func resolve_attack_damage(damage: float, modifiers: Dictionary, attack_count: int) -> float:
	if modifiers.has("overheat_round") and attack_count % 5 == 0:
		return damage * float(modifiers.overheat_round)
	return damage

func execute(
		attack_type: StringName,
		enemies: Array[Enemy],
		core_position: Vector2,
		cursor_position: Vector2,
		battlefield_end_x: float,
		attack_range: float,
		plan: Dictionary,
		modifiers: Dictionary,
		damage: float,
		attack_count: int,
		closest_target_callback: Callable,
		hit_callback: Callable
	) -> Dictionary:
	var hit_targets: Array[Enemy] = []
	var lucky_roll := _lucky_roll(attack_type, modifiers, attack_count)
	match attack_type:
		&"pierce":
			var profile := _build_pierce_profile(enemies, core_position, cursor_position, battlefield_end_x, plan, modifiers)
			hit_targets = profile.targets
			for target in hit_targets:
				hit_callback.call(target, damage * float(profile.damage_multiplier), &"pierce")
		&"radial":
			hit_targets = _execute_radial(enemies, core_position, attack_range, plan, damage, hit_callback)
		&"random":
			if not enemies.is_empty():
				var random_target := RunRng.pick(enemies) as Enemy
				hit_targets.append(random_target)
				hit_callback.call(random_target, damage * lucky_roll, &"core")
		_:
			var closest_target := closest_target_callback.call(enemies) as Enemy
			if closest_target != null:
				hit_targets.append(closest_target)
				hit_callback.call(closest_target, damage, &"core")
	return {"hit_targets": hit_targets, "lucky_roll": lucky_roll}

func execute_abyss_presence(
		enemies: Array[Enemy],
		core_position: Vector2,
		base_attack_range: float,
		damage: float,
		plan: Dictionary,
		consume_callback: Callable,
		hit_callback: Callable
	) -> Dictionary:
	var radius := base_attack_range * float(plan.attack_range_multiplier) * float(plan.abyss_presence_radius_multiplier)
	var targets: Array[Enemy] = enemies.filter(func(enemy: Enemy) -> bool:
		return enemy.active and enemy.global_position.distance_to(core_position) <= radius
	)
	if targets.is_empty() or not bool(consume_callback.call()):
		return {"triggered": false, "targets": targets, "radius": radius, "hit_count": 0}
	var hit_count := 0
	var hit_damage := damage * float(plan.abyss_presence_damage_multiplier)
	for _hit_index in int(plan.abyss_presence_hits):
		for target in targets:
			if target.active:
				hit_callback.call(target, hit_damage, &"core_abyss_presence")
				hit_count += 1
	return {"triggered": true, "targets": targets, "radius": radius, "hit_count": hit_count}

func execute_specializations(
		primary: Enemy,
		damage: float,
		lucky_roll: float,
		modifiers: Dictionary,
		active_enemies_callback: Callable,
		radius_query_callback: Callable,
		closest_other_callback: Callable,
		hit_callback: Callable,
		presentation_callback: Callable
	) -> Dictionary:
	var result := {
		"applied": false,
		"dealt": 0.0,
		"hit_count": 0,
		"stage_ids": [],
		"hits": [],
	}
	if not is_instance_valid(primary) or not active_enemies_callback.is_valid() or not radius_query_callback.is_valid() or not closest_other_callback.is_valid() or not hit_callback.is_valid() or not presentation_callback.is_valid():
		return result
	_execute_prism_refract(primary, damage, modifiers, active_enemies_callback, closest_other_callback, hit_callback, presentation_callback, result)
	_execute_pierce_explosion(primary, damage, modifiers, active_enemies_callback, radius_query_callback, closest_other_callback, hit_callback, presentation_callback, result)
	_execute_highroll_explosion(primary, damage, lucky_roll, modifiers, radius_query_callback, hit_callback, presentation_callback, result)
	_execute_lucky_chain(primary, damage, lucky_roll, modifiers, active_enemies_callback, closest_other_callback, hit_callback, presentation_callback, result)
	result.applied = not (result.stage_ids as Array).is_empty()
	return result

func _lucky_roll(attack_type: StringName, modifiers: Dictionary, attack_count: int) -> float:
	if attack_type != &"random":
		return 1.0
	var lucky_roll := RunRng.rangef(float(modifiers.get("lucky_min", DEFAULT_LUCKY_MIN)), float(modifiers.get("lucky_max", DEFAULT_LUCKY_MAX)))
	var stable_interval := int(modifiers.get("stable_critical", 0))
	if stable_interval > 0 and attack_count % stable_interval == 0:
		return STABLE_CRITICAL_MULTIPLIER
	return lucky_roll

func _execute_prism_refract(
		primary: Enemy,
		damage: float,
		modifiers: Dictionary,
		active_enemies_callback: Callable,
		closest_other_callback: Callable,
		hit_callback: Callable,
		presentation_callback: Callable,
		result: Dictionary
	) -> void:
	if not modifiers.has("prism_refract"):
		return
	var target := _closest_active_other(primary, PRISM_REFRACT_RANGE, active_enemies_callback, closest_other_callback)
	if target == null:
		return
	_apply_specialization_hit(target, damage * float(modifiers.prism_refract), &"core_prism", hit_callback, result)
	(result.stage_ids as Array).append(&"core_prism")
	presentation_callback.call({"type": &"link", "source": &"core_prism", "from": primary.global_position, "to": target.global_position, "duration": 0.25})

func _execute_pierce_explosion(
		primary: Enemy,
		damage: float,
		modifiers: Dictionary,
		active_enemies_callback: Callable,
		radius_query_callback: Callable,
		closest_other_callback: Callable,
		hit_callback: Callable,
		presentation_callback: Callable,
		result: Dictionary
	) -> void:
	if not modifiers.has("pierce_explosion"):
		return
	for target in _active_radius_targets(primary.global_position, PIERCE_EXPLOSION_RADIUS, radius_query_callback):
		if target != primary:
			_apply_specialization_hit(target, damage * float(modifiers.pierce_explosion), &"core_pierce_blast", hit_callback, result)
	(result.stage_ids as Array).append(&"core_pierce_blast")
	presentation_callback.call({"type": &"burst", "source": &"core_pierce_blast", "position": primary.global_position, "radius": PIERCE_EXPLOSION_RADIUS, "strength": 0.55})
	if not modifiers.has("pierce_explosion_chain"):
		return
	var chain_target := _closest_active_other(primary, PIERCE_CHAIN_RANGE, active_enemies_callback, closest_other_callback)
	if chain_target == null:
		return
	_apply_specialization_hit(chain_target, damage * float(modifiers.pierce_explosion_chain), &"core_pierce_chain", hit_callback, result)
	(result.stage_ids as Array).append(&"core_pierce_chain")

func _execute_highroll_explosion(
		primary: Enemy,
		damage: float,
		lucky_roll: float,
		modifiers: Dictionary,
		radius_query_callback: Callable,
		hit_callback: Callable,
		presentation_callback: Callable,
		result: Dictionary
	) -> void:
	if not modifiers.has("highroll_explosion") or lucky_roll < HIGHROLL_THRESHOLD:
		return
	for target in _active_radius_targets(primary.global_position, HIGHROLL_EXPLOSION_RADIUS, radius_query_callback):
		if target != primary:
			_apply_specialization_hit(target, damage * lucky_roll * float(modifiers.highroll_explosion), &"core_highroll", hit_callback, result)
	(result.stage_ids as Array).append(&"core_highroll")
	presentation_callback.call({"type": &"burst", "source": &"core_highroll", "position": primary.global_position, "radius": HIGHROLL_EXPLOSION_RADIUS, "strength": 0.72})

func _execute_lucky_chain(
		primary: Enemy,
		damage: float,
		lucky_roll: float,
		modifiers: Dictionary,
		active_enemies_callback: Callable,
		closest_other_callback: Callable,
		hit_callback: Callable,
		presentation_callback: Callable,
		result: Dictionary
	) -> void:
	if not modifiers.has("lucky_chain_threshold") or lucky_roll < float(modifiers.lucky_chain_threshold):
		return
	var chain_source := primary
	var stage_recorded := false
	for _chain_index in int(modifiers.get("lucky_chain_count", 1)):
		var chain_target := _closest_active_other(chain_source, LUCKY_CHAIN_RANGE, active_enemies_callback, closest_other_callback)
		if chain_target == null:
			break
		_apply_specialization_hit(chain_target, damage * float(modifiers.lucky_chain_damage), &"core_lucky_chain", hit_callback, result)
		if not stage_recorded:
			(result.stage_ids as Array).append(&"core_lucky_chain")
			stage_recorded = true
		presentation_callback.call({"type": &"link", "source": &"core_lucky_chain", "from": chain_source.global_position, "to": chain_target.global_position, "duration": 0.2})
		chain_source = chain_target

func _apply_specialization_hit(target: Enemy, hit_damage: float, source: StringName, hit_callback: Callable, result: Dictionary) -> void:
	var dealt := float(hit_callback.call(target, hit_damage, source))
	result.dealt = float(result.dealt) + dealt
	result.hit_count = int(result.hit_count) + 1
	(result.hits as Array).append({"target": target, "damage": hit_damage, "source": source, "dealt": dealt})

func _closest_active_other(source: Enemy, maximum_distance: float, active_enemies_callback: Callable, closest_other_callback: Callable) -> Enemy:
	var active_enemies: Array[Enemy] = []
	active_enemies.assign(active_enemies_callback.call() as Array)
	return closest_other_callback.call(active_enemies, source, maximum_distance) as Enemy

func _active_radius_targets(center: Vector2, radius: float, radius_query_callback: Callable) -> Array[Enemy]:
	var targets: Array[Enemy] = []
	for target in radius_query_callback.call(center, radius) as Array:
		if is_instance_valid(target) and target.active:
			targets.append(target)
	return targets

func _build_pierce_profile(
		enemies: Array[Enemy],
		core_position: Vector2,
		cursor_position: Vector2,
		battlefield_end_x: float,
		plan: Dictionary,
		modifiers: Dictionary
	) -> Dictionary:
	if bool(plan.charm_radial):
		return _build_charm_radial_profile(enemies, cursor_position, plan)
	if bool(modifiers.get("coordinate_rail", false)):
		return _build_coordinate_rail_profile(enemies, core_position, cursor_position, modifiers)
	return _build_cursor_band_profile(enemies, core_position, cursor_position, battlefield_end_x, plan)

func _build_charm_radial_profile(enemies: Array[Enemy], cursor_position: Vector2, plan: Dictionary) -> Dictionary:
	var radial_targets := enemies.duplicate()
	radial_targets.sort_custom(func(left: Enemy, right: Enemy) -> bool:
		return left.global_position.distance_squared_to(cursor_position) < right.global_position.distance_squared_to(cursor_position)
	)
	var target_limit := mini(int(plan.charm_radial_targets), radial_targets.size())
	var hit_targets: Array[Enemy] = []
	hit_targets.assign(radial_targets.slice(0, target_limit))
	return {"targets": hit_targets, "damage_multiplier": float(plan.charm_radial_damage_multiplier)}

func _build_coordinate_rail_profile(enemies: Array[Enemy], core_position: Vector2, cursor_position: Vector2, modifiers: Dictionary) -> Dictionary:
	var hit_targets := _targets_near_segment(enemies, core_position, cursor_position, float(modifiers.get("rail_width", DEFAULT_RAIL_HALF_WIDTH)))
	_sort_targets_along_segment(hit_targets, core_position, cursor_position)
	return {"targets": hit_targets, "damage_multiplier": 1.0}

func _build_cursor_band_profile(enemies: Array[Enemy], core_position: Vector2, cursor_position: Vector2, battlefield_end_x: float, plan: Dictionary) -> Dictionary:
	var half_width := DEFAULT_PIERCE_HALF_WIDTH * float(plan.pierce_width_multiplier)
	var hit_targets: Array[Enemy] = enemies.filter(func(enemy: Enemy) -> bool:
		return enemy.active and absf(enemy.global_position.y - cursor_position.y) <= half_width
	)
	var beam_start := Vector2(core_position.x, cursor_position.y)
	_sort_targets_along_segment(hit_targets, beam_start, Vector2(battlefield_end_x, beam_start.y))
	return {"targets": hit_targets, "damage_multiplier": 1.0}

func _execute_radial(enemies: Array[Enemy], core_position: Vector2, attack_range: float, plan: Dictionary, damage: float, hit_callback: Callable) -> Array[Enemy]:
	var hit_targets: Array[Enemy] = []
	var radial_range := attack_range * float(plan.attack_range_multiplier)
	for target in enemies:
		var distance_to_center := target.global_position.distance_to(core_position)
		if distance_to_center > radial_range:
			continue
		hit_targets.append(target)
		hit_callback.call(target, damage, &"core")
		var center_radius := float(plan.abyss_center_radius)
		if target.active and center_radius > 0.0 and distance_to_center <= center_radius:
			hit_callback.call(target, damage * float(plan.abyss_center_damage_multiplier), &"core_abyss_center")
	return hit_targets

func _targets_near_segment(enemies: Array[Enemy], start: Vector2, end: Vector2, half_width: float) -> Array[Enemy]:
	return enemies.filter(func(enemy: Enemy) -> bool:
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		return enemy.global_position.distance_to(closest) <= half_width
	)

func _sort_targets_along_segment(targets: Array[Enemy], start: Vector2, end: Vector2) -> void:
	var direction := start.direction_to(end)
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	targets.sort_custom(func(left: Enemy, right: Enemy) -> bool:
		var left_progress := (left.global_position - start).dot(direction)
		var right_progress := (right.global_position - start).dot(direction)
		if is_equal_approx(left_progress, right_progress):
			return left.get_instance_id() < right.get_instance_id()
		return left_progress < right_progress
	)
