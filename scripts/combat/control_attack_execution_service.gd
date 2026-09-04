class_name ControlAttackExecutionService
extends RefCounted

const PRESENTATION_LIMIT := 6
const FROST_STACK_DURATION := 4.0
const FROST_BASE_DAMAGE := 18.0
const FROST_DAMAGE_PER_LEVEL := 6.0
const DEFAULT_OVERHEAT_DURATION := 1.0

func build_slow_profile(level: int, modifiers: Dictionary, attack_count: int, slow_power: float) -> Dictionary:
	var erosion_cycle := int(modifiers.get("erosion_cycle", 0))
	return {
		"level": level,
		"modifiers": modifiers,
		"erosion_pulse": erosion_cycle > 0 and attack_count % erosion_cycle == 0,
		"slow_power": slow_power,
	}

func execute_slow(
		enemies: Array[Enemy],
		primary_target: Enemy,
		origin: Vector2,
		slow_source: StringName,
		profile: Dictionary,
		common_status_callback: Callable,
		presentation_callback: Callable,
		frost_burst_callback: Callable
	) -> Dictionary:
	var dealt := 0.0
	var level := int(profile.level)
	var modifiers: Dictionary = profile.modifiers
	for hit_index in enemies.size():
		var slow_target := enemies[hit_index]
		slow_target.apply_slow(slow_source, 1.35 + level * 0.28, float(profile.slow_power))
		if bool(profile.erosion_pulse):
			slow_target.apply_status(&"stun", float(modifiers.get("erosion_stun", 0.0)), 1.0)
		common_status_callback.call(slow_target)
		dealt += _apply_frost_hit(slow_target, level, modifiers, frost_burst_callback)
		if hit_index < PRESENTATION_LIMIT:
			presentation_callback.call(slow_target, 1.0, 0.34 if slow_target == primary_target else 0.24)
	return {"target": primary_target, "dealt": dealt, "hit_count": enemies.size(), "origin": origin}

func _apply_frost_hit(target: Enemy, level: int, modifiers: Dictionary, frost_burst_callback: Callable) -> float:
	if not modifiers.has("frost_stack"):
		return 0.0
	var frost_count := int(target.statuses.get(&"frost_stack", {}).get("power", 0.0)) + 1
	if frost_count < int(modifiers.frost_stack):
		target.statuses[&"frost_stack"] = {"remaining": FROST_STACK_DURATION, "power": frost_count}
		target.trigger_status_visual(&"frost_stack")
		return 0.0
	target.statuses.erase(&"frost_stack")
	target.apply_status(&"stun", float(modifiers.frost_stun), 1.0)
	var frost_damage := FROST_BASE_DAMAGE + level * FROST_DAMAGE_PER_LEVEL
	var dealt := target.take_damage(frost_damage, &"common_shock", true)
	frost_burst_callback.call(target)
	return dealt

func build_knockback_profile(damage: float, push: float, modifiers: Dictionary, attack_count: int) -> Dictionary:
	var overheat_cycle := int(modifiers.get("overheat_cycle", 0))
	return {
		"damage": damage,
		"push": push,
		"overheat_triggered": overheat_cycle > 0 and attack_count % overheat_cycle == 0,
		"overheat_duration": float(modifiers.get("overheat_duration", DEFAULT_OVERHEAT_DURATION)),
	}

func execute_knockback(
		enemies: Array[Enemy],
		primary_target: Enemy,
		origin: Vector2,
		profile: Dictionary,
		hit_callback: Callable,
		overheat_callback: Callable
	) -> Dictionary:
	var dealt := 0.0
	for hit_index in enemies.size():
		var target := enemies[hit_index]
		dealt += float(hit_callback.call(
			target,
			float(profile.damage),
			hit_index < PRESENTATION_LIMIT,
			0.72 if target == primary_target else 0.42
		))
		target.apply_knockback(float(profile.push))
	if bool(profile.overheat_triggered):
		overheat_callback.call(float(profile.overheat_duration))
	return {"target": primary_target, "dealt": dealt, "hit_count": enemies.size(), "origin": origin}

func build_golem_profile(modifiers: Dictionary, origin: Vector2, targets: Array[Enemy], push_distance: float) -> Dictionary:
	return {
		"modifiers": modifiers,
		"origin": origin,
		"targets": targets,
		"push_distance": push_distance,
	}

func execute_golem(
		primary_target: Enemy,
		profile: Dictionary,
		control_event_callback: Callable,
		presentation_callback: Callable,
		recoil_callback: Callable
	) -> Dictionary:
	var targets: Array[Enemy] = profile.targets
	var modifiers: Dictionary = profile.modifiers
	for hit_index in targets.size():
		var target := targets[hit_index]
		var control_distance := 0.0
		if modifiers.has("gather"):
			control_distance = target.apply_forced_movement(profile.origin, float(profile.push_distance) * float(modifiers.gather), &"gather")
		else:
			control_distance = target.apply_knockback(float(profile.push_distance))
		if control_distance > 0.0:
			control_event_callback.call(target, control_distance)
		if hit_index < PRESENTATION_LIMIT:
			presentation_callback.call(target, 1.0, 0.52 if target == primary_target else 0.32)
	if modifiers.has("self_recoil"):
		recoil_callback.call(primary_target.global_position, float(modifiers.self_recoil))
	return {"target": primary_target, "dealt": 0.0, "hit_count": targets.size(), "origin": profile.origin}
