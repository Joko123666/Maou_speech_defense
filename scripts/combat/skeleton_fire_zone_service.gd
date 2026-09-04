class_name SkeletonFireZoneService
extends RefCounted

const TICK_SECONDS := 0.25

func build_profile(owner_instance_id: int, zone_serial: int, attack_damage: float, modifiers: Dictionary, burn_profile: Dictionary) -> Dictionary:
	var burn_ratio := maxf(float(modifiers.get("fire_zone_burn_ratio", 0.12)), float(burn_profile.get("damage_ratio", 0.05)))
	return {
		"duration": maxf(float(modifiers.get("fire_zone_duration", 3.5)), 0.0),
		"radius": maxf(float(modifiers.get("fire_zone_radius", 72.0)), 0.0),
		"source_key": StringName("skeleton_fire_zone:%d:%d" % [owner_instance_id, zone_serial]),
		"burn_damage": maxf(attack_damage, 0.0) * burn_ratio,
		"burn_duration": float(burn_profile.get("duration", 4.0)),
		"burn_stacks": int(burn_profile.get("max_stacks", 1)),
		"burn_minimum_decay": float(burn_profile.get("minimum_decay_ratio", 0.25)),
		"burn_reset_decay": bool(burn_profile.get("reset_decay_on_reapply", true)),
		"tick_seconds": TICK_SECONDS,
		"tick_count": tick_count_for_duration(float(modifiers.get("fire_zone_duration", 3.5))),
	}

func tick_count_for_duration(duration: float) -> int:
	return ceili(maxf(duration, 0.0) / TICK_SECONDS)

func run_zone(
		zone_position: Vector2,
		profile: Dictionary,
		active_callback: Callable,
		target_query_callback: Callable,
		wait_callback: Callable,
		burn_event_callback: Callable
	) -> Dictionary:
	var result := {"ticks": 0, "burns": 0, "affected_enemy_ids": {}}
	if not active_callback.is_valid() or not target_query_callback.is_valid() or not wait_callback.is_valid():
		return result
	var remaining := float(profile.get("duration", 0.0))
	while remaining > 0.0:
		if not active_callback.is_valid() or not bool(active_callback.call()):
			break
		var tick_result := apply_tick(zone_position, profile, result.affected_enemy_ids, target_query_callback, burn_event_callback)
		result.ticks = int(result.ticks) + 1
		result.burns = int(result.burns) + int(tick_result.burns)
		if not wait_callback.is_valid():
			break
		var timeout_signal: Signal = wait_callback.call(TICK_SECONDS)
		await timeout_signal
		remaining -= TICK_SECONDS
	return result

func apply_tick(
		zone_position: Vector2,
		profile: Dictionary,
		affected_enemy_ids: Dictionary,
		target_query_callback: Callable,
		burn_event_callback: Callable
	) -> Dictionary:
	var result := {"burns": 0, "targets": []}
	if not target_query_callback.is_valid() or float(profile.get("radius", 0.0)) <= 0.0:
		return result
	var targets: Array[Enemy] = []
	targets.assign(target_query_callback.call(zone_position, float(profile.radius)) as Array)
	var applied_targets: Array[Enemy] = []
	for target in targets:
		if not is_instance_valid(target) or not target.active:
			continue
		var enemy_id := target.get_instance_id()
		if affected_enemy_ids.has(enemy_id):
			continue
		affected_enemy_ids[enemy_id] = true
		var reignited := target.has_common_ailment(&"burn")
		target.apply_common_burn(
			profile.source_key,
			float(profile.burn_damage),
			float(profile.burn_duration),
			int(profile.burn_stacks),
			float(profile.burn_minimum_decay),
			bool(profile.burn_reset_decay)
		)
		applied_targets.append(target)
		if burn_event_callback.is_valid():
			burn_event_callback.call({"target": target, "reignited": reignited})
	result.burns = applied_targets.size()
	result.targets = applied_targets
	return result
