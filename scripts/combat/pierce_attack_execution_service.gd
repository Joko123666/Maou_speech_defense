class_name PierceAttackExecutionService
extends RefCounted

const DEFAULT_BAND_WIDTH := 24.0
const UNIQUE_BAND_WIDTH := 34.0
const DEFAULT_EXPLOSION_RADIUS := 90.0
const DEFAULT_EXPLOSION_DELAY := 0.3
const MIN_EXPLOSION_DELAY := 0.01
const EXPLOSION_EDGE_MULTIPLIER := 0.58
const PRESENTATION_LIMIT := 6

func build_band_profile(behavior: StringName, modifiers: Dictionary, attack_count: int) -> Dictionary:
	var power_shot_interval := int(modifiers.get("power_shot_hits", 0))
	var power_shot := behavior == &"pierce" and power_shot_interval > 0 and attack_count % power_shot_interval == 0
	var width := UNIQUE_BAND_WIDTH if behavior == &"unique_pierce" else DEFAULT_BAND_WIDTH
	if power_shot:
		width *= float(modifiers.get("power_shot_width", 1.0))
	return {
		"width": width,
		"power_shot": power_shot,
		"damage_multiplier": float(modifiers.get("power_shot_damage", 1.0)) if power_shot else 1.0,
		"missing_health_multiplier": float(modifiers.get("missing_health", 0.0)),
	}

func build_explosive_plan(behavior: StringName, modifiers: Dictionary, target: Enemy, damage: float) -> Dictionary:
	if behavior != &"pierce" or target == null or not bool(modifiers.get("explosive_arrow", false)):
		return {"deferred": false}
	return {
		"deferred": true,
		"position": target.global_position,
		"damage": damage * float(modifiers.get("explosion_damage", 1.0)),
		"radius": float(modifiers.get("explosion_radius", DEFAULT_EXPLOSION_RADIUS)),
		"delay": float(modifiers.get("explosion_delay", DEFAULT_EXPLOSION_DELAY)),
	}

func explosion_delay_seconds(plan: Dictionary) -> float:
	return maxf(float(plan.get("delay", DEFAULT_EXPLOSION_DELAY)), MIN_EXPLOSION_DELAY)

func run_deferred_explosion(
		plan: Dictionary,
		wait_callback: Callable,
		execution_active_callback: Callable,
		tracked_targets_callback: Callable,
		target_query_callback: Callable,
		hit_callback: Callable,
		completion_callback: Callable
	) -> Dictionary:
	var result := _empty_deferred_explosion_result()
	if not bool(plan.get("deferred", false)):
		return result
	if not wait_callback.is_valid() or not execution_active_callback.is_valid() or not tracked_targets_callback.is_valid() or not target_query_callback.is_valid() or not hit_callback.is_valid() or not completion_callback.is_valid():
		return result
	var timeout_signal: Signal = wait_callback.call(explosion_delay_seconds(plan))
	await timeout_signal
	if not completion_callback.is_valid():
		result.cancelled = true
		return result
	result = resolve_deferred_explosion(
		plan,
		execution_active_callback,
		tracked_targets_callback,
		target_query_callback,
		hit_callback
	)
	if bool(result.completed):
		completion_callback.call(result)
	return result

func resolve_deferred_explosion(
		plan: Dictionary,
		execution_active_callback: Callable,
		tracked_targets_callback: Callable,
		target_query_callback: Callable,
		hit_callback: Callable
	) -> Dictionary:
	var result := _empty_deferred_explosion_result()
	if not bool(plan.get("deferred", false)):
		return result
	if not execution_active_callback.is_valid() or not tracked_targets_callback.is_valid() or not target_query_callback.is_valid() or not hit_callback.is_valid():
		return result
	if not bool(execution_active_callback.call()):
		result.cancelled = true
		return result
	var tracked_targets: Array[Enemy] = []
	tracked_targets.assign(tracked_targets_callback.call() as Array)
	var impact_position: Vector2 = plan.position
	var radius := float(plan.radius)
	var targets: Array[Enemy] = []
	targets.assign(target_query_callback.call(impact_position, radius) as Array)
	var hit_result := execute_explosion(targets, impact_position, float(plan.damage), radius, hit_callback)
	result.completed = true
	result.position = impact_position
	result.radius = radius
	result.damage = float(plan.damage)
	result.delay = explosion_delay_seconds(plan)
	result.tracked_targets = tracked_targets
	result.targets = targets
	result.hit_count = int(hit_result.hit_count)
	result.dealt = float(hit_result.dealt)
	return result

func execute_band(
		origin: Vector2,
		beam_end: Vector2,
		damage: float,
		profile: Dictionary,
		target_query: Callable,
		hit_callback: Callable
	) -> Dictionary:
	var targets: Array[Enemy] = []
	targets.assign(target_query.call(origin, beam_end, float(profile.width)) as Array)
	_sort_targets_along_segment(targets, origin, beam_end)
	var dealt := 0.0
	for hit_index in targets.size():
		var target := targets[hit_index]
		var missing_multiplier := 1.0 + (1.0 - target.get_health_ratio()) * float(profile.missing_health_multiplier)
		var hit_damage := damage * missing_multiplier * float(profile.damage_multiplier)
		dealt += float(hit_callback.call(
			target,
			hit_damage,
			hit_index < PRESENTATION_LIMIT,
			0.86 if bool(profile.power_shot) else 0.72
		))
	return {"dealt": dealt, "hit_count": targets.size()}

func execute_explosion(
		targets: Array[Enemy],
		impact_position: Vector2,
		damage: float,
		radius: float,
		hit_callback: Callable
	) -> Dictionary:
	var dealt := 0.0
	for hit_index in targets.size():
		var target := targets[hit_index]
		var distance_ratio := clampf(target.global_position.distance_to(impact_position) / maxf(radius, 1.0), 0.0, 1.0)
		var hit_damage := damage * lerpf(1.0, EXPLOSION_EDGE_MULTIPLIER, distance_ratio)
		dealt += float(hit_callback.call(target, hit_damage, hit_index < PRESENTATION_LIMIT))
	return {"dealt": dealt, "hit_count": targets.size()}

func _empty_deferred_explosion_result() -> Dictionary:
	return {
		"completed": false,
		"cancelled": false,
		"position": Vector2.ZERO,
		"radius": 0.0,
		"damage": 0.0,
		"delay": 0.0,
		"tracked_targets": [],
		"targets": [],
		"hit_count": 0,
		"dealt": 0.0,
	}

func _sort_targets_along_segment(targets: Array[Enemy], start: Vector2, end: Vector2) -> void:
	var direction := start.direction_to(end)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	targets.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		var progress_a := (a.global_position - start).dot(direction)
		var progress_b := (b.global_position - start).dot(direction)
		if not is_equal_approx(progress_a, progress_b):
			return progress_a < progress_b
		return a.get_instance_id() < b.get_instance_id()
	)
