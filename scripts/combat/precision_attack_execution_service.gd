class_name PrecisionAttackExecutionService
extends RefCounted

const DEFAULT_EXECUTE_RATIO := 0.10
const DEFAULT_COLLATERAL_WIDTH := 28.0
const DEFAULT_EXECUTE_STUN_RADIUS := 115.0
const DEFAULT_MARK_DURATION := 5.0

func build_execute_profile(
		modifiers: Dictionary,
		target: Enemy,
		guard_overrides: Dictionary,
		sudden_death: bool
	) -> Dictionary:
	return {
		"modifiers": modifiers,
		"execute_ratio": float(modifiers.get("execute_ratio", DEFAULT_EXECUTE_RATIO)),
		"execute_source": &"pierce" if bool(modifiers.get("armor_pierce", false)) else &"execute",
		"execute_position": target.global_position,
		"enemy_data": target.data,
		"guard_overrides": guard_overrides,
		"sudden_death": sudden_death,
	}

func execute_verdict(
		enemies: Array[Enemy],
		target: Enemy,
		origin: Vector2,
		damage: float,
		profile: Dictionary,
		verdict: Dictionary,
		primary_hit_callback: Callable,
		collateral_hit_callback: Callable,
		stun_target_query: Callable
	) -> Dictionary:
	var dealt := float(primary_hit_callback.call(target, verdict, profile))
	var collateral_result := _execute_collateral(
		enemies,
		target,
		origin,
		damage,
		profile.modifiers,
		collateral_hit_callback
	)
	dealt += float(collateral_result.dealt)
	if bool(verdict.get("executed", false)):
		_apply_execute_stun(target, profile.modifiers, stun_target_query)
	return {
		"target": target,
		"dealt": dealt,
		"hit_count": 1 + int(collateral_result.hit_count),
	}

func execute_mark(
		target: Enemy,
		damage: float,
		modifiers: Dictionary,
		mark_power: float,
		primary_hit_callback: Callable
	) -> Dictionary:
	var dealt := float(primary_hit_callback.call(target, damage))
	var duration := float(modifiers.get("mark_duration", DEFAULT_MARK_DURATION))
	target.apply_status(&"mark", duration, mark_power)
	if modifiers.has("hex_slow"):
		target.apply_slow(&"succubus_hex", duration, float(modifiers.hex_slow))
	return {"target": target, "dealt": dealt, "hit_count": 1}

func _execute_collateral(
		enemies: Array[Enemy],
		target: Enemy,
		origin: Vector2,
		damage: float,
		modifiers: Dictionary,
		collateral_hit_callback: Callable
	) -> Dictionary:
	if not modifiers.has("collateral_damage"):
		return {"dealt": 0.0, "hit_count": 0}
	var dealt := 0.0
	var hit_count := 0
	var collateral_damage := damage * float(modifiers.collateral_damage)
	for collateral_target in _targets_near_segment(
			enemies,
			origin,
			target.global_position,
			float(modifiers.get("collateral_width", DEFAULT_COLLATERAL_WIDTH))
		):
		if collateral_target == target or not collateral_target.active:
			continue
		dealt += float(collateral_hit_callback.call(collateral_target, collateral_damage))
		hit_count += 1
	return {"dealt": dealt, "hit_count": hit_count}

func _apply_execute_stun(target: Enemy, modifiers: Dictionary, stun_target_query: Callable) -> void:
	if not modifiers.has("execute_stun"):
		return
	var stun_targets: Array[Enemy] = []
	stun_targets.assign(stun_target_query.call(
		target.global_position,
		float(modifiers.get("execute_stun_radius", DEFAULT_EXECUTE_STUN_RADIUS))
	) as Array)
	for stun_target in stun_targets:
		if stun_target != target:
			stun_target.apply_status(&"stun", float(modifiers.execute_stun), 1.0)

func _targets_near_segment(enemies: Array[Enemy], start: Vector2, end: Vector2, half_width: float) -> Array[Enemy]:
	return enemies.filter(func(enemy: Enemy) -> bool:
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		return enemy.global_position.distance_to(closest) <= half_width
	)
