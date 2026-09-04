class_name SpiritAttackExecutionService
extends RefCounted

const DAMAGE_SOURCE := &"spirit_summon"

func execute(
		fallback_origin: Vector2,
		base_damage: float,
		requested: int,
		spirit_damage_multiplier: float,
		blast_radius: float,
		active_enemies_callback: Callable,
		reserve_callback: Callable,
		target_picker_callback: Callable,
		curse_callback: Callable,
		radius_query_callback: Callable,
		damage_callback: Callable,
		presentation_callback: Callable,
		update_summon_callback: Callable
	) -> Dictionary:
	var result := _empty_batch_result()
	result.requested_count = maxi(requested, 0)
	if requested <= 0:
		result.reason = &"invalid_request"
		return result
	if not _dependencies_valid(active_enemies_callback, reserve_callback, target_picker_callback, curse_callback, radius_query_callback, damage_callback, presentation_callback, update_summon_callback):
		return result
	if _active_enemies(active_enemies_callback).is_empty():
		result.reason = &"no_targets"
		return result
	for _release_index in int(result.requested_count):
		var release_result := execute_single(
			fallback_origin, base_damage, spirit_damage_multiplier, blast_radius,
			active_enemies_callback, reserve_callback, target_picker_callback, curse_callback,
			radius_query_callback, damage_callback, presentation_callback, update_summon_callback
		)
		if not bool(release_result.released):
			result.stop_reason = StringName(release_result.reason)
			break
		(result.releases as Array[Dictionary]).append(release_result)
		result.released_count = int(result.released_count) + 1
		result.damage = float(result.damage) + float(release_result.damage)
		result.hit_count = int(result.hit_count) + int(release_result.hit_count)
	result.resolved = int(result.released_count) > 0
	result.reason = &"resolved" if bool(result.resolved) else StringName(result.stop_reason)
	if int(result.released_count) == int(result.requested_count):
		result.stop_reason = &"completed"
	return result

func execute_single(
		fallback_origin: Vector2,
		base_damage: float,
		spirit_damage_multiplier: float,
		blast_radius: float,
		active_enemies_callback: Callable,
		reserve_callback: Callable,
		target_picker_callback: Callable,
		curse_callback: Callable,
		radius_query_callback: Callable,
		damage_callback: Callable,
		presentation_callback: Callable,
		update_summon_callback: Callable
	) -> Dictionary:
	var result := _empty_release_result()
	if not _dependencies_valid(active_enemies_callback, reserve_callback, target_picker_callback, curse_callback, radius_query_callback, damage_callback, presentation_callback, update_summon_callback):
		return result
	var live_targets := _active_enemies(active_enemies_callback)
	if live_targets.is_empty():
		result.reason = &"no_targets"
		return result
	var summon_entries: Array = reserve_callback.call(1, fallback_origin)
	if summon_entries.is_empty():
		result.reason = &"reservation_rejected"
		return result
	var summon_entry: Dictionary = summon_entries[0]
	var spirit_target := target_picker_callback.call(live_targets) as Enemy
	if not is_instance_valid(spirit_target) or not spirit_target.active:
		result.reason = &"invalid_target"
		return result
	var spirit_origin: Vector2 = summon_entry.get("position", fallback_origin)
	var curse_generation := int(summon_entry.get("curse_generation", 0))
	var curse_applied := bool(curse_callback.call(spirit_target, curse_generation))
	var spirit_damage := base_damage * spirit_damage_multiplier * float(summon_entry.get("damage_multiplier", 1.0))
	var blast_targets: Array[Enemy] = []
	blast_targets.assign(radius_query_callback.call(spirit_target.global_position, blast_radius) as Array)
	var used_primary_fallback := blast_targets.is_empty()
	if used_primary_fallback:
		blast_targets.append(spirit_target)
	var dealt := 0.0
	for blast_target in blast_targets:
		dealt += float(damage_callback.call(blast_target, spirit_damage, DAMAGE_SOURCE, true))
	var target_position := spirit_target.global_position
	presentation_callback.call(spirit_origin, target_position, blast_radius)
	var summon_id := int(summon_entry.get("id", -1))
	update_summon_callback.call(summon_id, target_position, spirit_damage)
	result.released = true
	result.reason = &"released"
	result.damage = dealt
	result.hit_count = blast_targets.size()
	result.target = spirit_target
	result.origin = spirit_origin
	result.target_position = target_position
	result.spirit_damage = spirit_damage
	result.summon_id = summon_id
	result.curse_generation = curse_generation
	result.curse_applied = curse_applied
	result.used_primary_fallback = used_primary_fallback
	result.targets = blast_targets
	return result

func _active_enemies(active_enemies_callback: Callable) -> Array[Enemy]:
	var result: Array[Enemy] = []
	result.assign(active_enemies_callback.call() as Array)
	return result

func _dependencies_valid(
		active_enemies_callback: Callable,
		reserve_callback: Callable,
		target_picker_callback: Callable,
		curse_callback: Callable,
		radius_query_callback: Callable,
		damage_callback: Callable,
		presentation_callback: Callable,
		update_summon_callback: Callable
	) -> bool:
	return active_enemies_callback.is_valid() and reserve_callback.is_valid() and target_picker_callback.is_valid() and curse_callback.is_valid() and radius_query_callback.is_valid() and damage_callback.is_valid() and presentation_callback.is_valid() and update_summon_callback.is_valid()

func _empty_batch_result() -> Dictionary:
	return {
		"resolved": false,
		"reason": &"invalid_dependencies",
		"stop_reason": &"invalid_dependencies",
		"requested_count": 0,
		"released_count": 0,
		"damage": 0.0,
		"hit_count": 0,
		"releases": [] as Array[Dictionary],
	}

func _empty_release_result() -> Dictionary:
	return {
		"released": false,
		"reason": &"invalid_dependencies",
		"damage": 0.0,
		"hit_count": 0,
		"target": null,
		"origin": Vector2.ZERO,
		"target_position": Vector2.ZERO,
		"spirit_damage": 0.0,
		"summon_id": -1,
		"curse_generation": 0,
		"curse_applied": false,
		"used_primary_fallback": false,
		"targets": [] as Array[Enemy],
	}
