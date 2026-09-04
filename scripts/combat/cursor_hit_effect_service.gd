class_name CursorHitEffectService
extends RefCounted

const WEAK_MARK_DURATION := 4.5
const COLLISION_MARK_DURATION := 4.0
const SHATTER_MARK_DURATION := 3.5
const SHATTER_RADIUS := 120.0
const SHATTER_POWER_MULTIPLIER := 0.6
const COLLISION_DAMAGE_SOURCE := &"cursor_collision"

func execute(
		target: Enemy,
		damage: float,
		is_area: bool,
		modifiers: Dictionary,
		primary_damage_callback: Callable,
		collision_damage_callback: Callable,
		radius_query_callback: Callable
	) -> Dictionary:
	var result := _empty_result()
	if not is_instance_valid(target) or not target.active:
		result.reason = &"invalid_target"
		return result
	if not primary_damage_callback.is_valid() or not collision_damage_callback.is_valid() or not radius_query_callback.is_valid():
		return result
	result.resolved = true
	result.reason = &"resolved"
	result.reward_multiplier = maxf(float(modifiers.get("reward_mark", 0.0)), 0.0)
	if modifiers.has("reward_mark"):
		target.experience_multiplier = maxf(target.experience_multiplier, float(result.reward_multiplier))
		result.reward_mark_reserved = true
	result.primary_damage = float(primary_damage_callback.call(target, damage, is_area))
	result.target_survived_primary = target.active
	if not target.active:
		return result
	_apply_primary_statuses(target, modifiers, result)
	if modifiers.has("reward_mark"):
		target.experience_multiplier = maxf(target.experience_multiplier, float(result.reward_multiplier))
		result.reward_mark_preserved = true
	_apply_collision(target, damage, modifiers, collision_damage_callback, result)
	if not target.active:
		return result
	_apply_shatter_spread(target, modifiers, radius_query_callback, result)
	return result

func _apply_primary_statuses(target: Enemy, modifiers: Dictionary, result: Dictionary) -> void:
	if not modifiers.has("weak_mark"):
		return
	_apply_status(target, &"mark", WEAK_MARK_DURATION, float(modifiers.weak_mark), &"weak_mark", result)
	if bool(modifiers.get("tower_pierce_mark", false)):
		_apply_status(target, &"pierce_mark", WEAK_MARK_DURATION, 1.0, &"tower_pierce_mark", result)

func _apply_collision(target: Enemy, damage: float, modifiers: Dictionary, collision_damage_callback: Callable, result: Dictionary) -> void:
	if not modifiers.has("collision_damage") or not target.active:
		return
	result.collision_requested = true
	result.collision_requested_damage = damage * float(modifiers.collision_damage)
	result.collision_damage = float(collision_damage_callback.call(target, float(result.collision_requested_damage), COLLISION_DAMAGE_SOURCE))
	result.target_survived_collision = target.active
	if modifiers.has("collision_mark") and target.active:
		_apply_status(target, &"mark", COLLISION_MARK_DURATION, float(modifiers.collision_mark), &"collision_mark", result)

func _apply_shatter_spread(target: Enemy, modifiers: Dictionary, radius_query_callback: Callable, result: Dictionary) -> void:
	if not bool(modifiers.get("shatter_spread", false)) or not target.active:
		return
	result.spread_requested = true
	var nearby_targets: Array[Enemy] = []
	nearby_targets.assign(radius_query_callback.call(target.global_position, SHATTER_RADIUS) as Array)
	var spread_power := float(modifiers.get("weak_mark", 0.0)) * SHATTER_POWER_MULTIPLIER
	for nearby in nearby_targets:
		if not is_instance_valid(nearby) or nearby == target:
			continue
		if not nearby.apply_status(&"mark", SHATTER_MARK_DURATION, spread_power):
			continue
		(result.spread_targets as Array[Enemy]).append(nearby)
		result.spread_count = int(result.spread_count) + 1

func _apply_status(target: Enemy, status_id: StringName, duration: float, power: float, effect_id: StringName, result: Dictionary) -> bool:
	if not target.apply_status(status_id, duration, power):
		return false
	(result.applied_effects as Array[StringName]).append(effect_id)
	return true

func _empty_result() -> Dictionary:
	return {
		"resolved": false,
		"reason": &"invalid_dependencies",
		"primary_damage": 0.0,
		"target_survived_primary": false,
		"reward_mark_reserved": false,
		"reward_mark_preserved": false,
		"reward_multiplier": 0.0,
		"collision_requested": false,
		"collision_requested_damage": 0.0,
		"collision_damage": 0.0,
		"target_survived_collision": false,
		"spread_requested": false,
		"spread_count": 0,
		"spread_targets": [] as Array[Enemy],
		"applied_effects": [] as Array[StringName],
	}
