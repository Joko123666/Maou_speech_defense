class_name SkeletonAreaFollowupService
extends RefCounted

const LIGHTNING_SOURCE := &"common_shock"

func execute(
		area_targets: Array[Enemy],
		attack_damage: float,
		modifiers: Dictionary,
		fire_zone_callback: Callable,
		bone_shard_callback: Callable,
		lightning_damage_callback: Callable,
		lightning_presentation_callback: Callable
	) -> Dictionary:
	var result := _empty_result()
	if modifiers.has("fire_zone_duration") and fire_zone_callback.is_valid():
		fire_zone_callback.call()
		result.fire_zone_requested = true
	if modifiers.has("bone_shard_count") and bone_shard_callback.is_valid():
		bone_shard_callback.call()
		result.bone_shards_requested = true
	if not modifiers.has("lightning_damage") or not lightning_damage_callback.is_valid():
		return result
	result.lightning_requested = true
	result.lightning_damage = attack_damage * float(modifiers.lightning_damage)
	var hit_targets: Array[Enemy] = []
	var dealt := 0.0
	for target in area_targets:
		if not is_instance_valid(target) or not target.active:
			continue
		dealt += float(lightning_damage_callback.call(target, float(result.lightning_damage), LIGHTNING_SOURCE))
		hit_targets.append(target)
		if lightning_presentation_callback.is_valid():
			lightning_presentation_callback.call(target)
	result.lightning_dealt = dealt
	result.lightning_hit_targets = hit_targets
	return result

func _empty_result() -> Dictionary:
	return {
		"fire_zone_requested": false,
		"bone_shards_requested": false,
		"lightning_requested": false,
		"lightning_damage": 0.0,
		"lightning_dealt": 0.0,
		"lightning_hit_targets": [],
	}
