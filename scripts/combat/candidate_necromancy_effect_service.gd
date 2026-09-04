class_name CandidateNecromancyEffectService
extends RefCounted

const EXPIRATION_DAMAGE_SOURCE := &"spirit_expiration"

func apply_generation_fear(
		generation_position: Vector2,
		candidate_modifier_callback: Callable,
		radius_query_callback: Callable
	) -> Dictionary:
	var result := _empty_generation_fear_result()
	if not candidate_modifier_callback.is_valid() or not radius_query_callback.is_valid():
		return result
	if not bool(candidate_modifier_callback.call(&"spirit_generation_fear", false)):
		result.reason = &"inactive_growth"
		return result
	result.eligible = true
	result.reason = &"resolved"
	result.radius = maxf(float(candidate_modifier_callback.call(&"spirit_generation_fear_radius", 120.0)), 0.0)
	result.duration = maxf(float(candidate_modifier_callback.call(&"spirit_generation_fear_duration", 4.0)), 0.0)
	result.power = maxf(float(candidate_modifier_callback.call(&"spirit_generation_fear_power", 0.8)), 0.0)
	var queried_targets: Array = radius_query_callback.call(generation_position, float(result.radius))
	for value in queried_targets:
		var enemy := value as Enemy
		if not is_instance_valid(enemy) or not enemy.active:
			continue
		if not enemy.apply_fear(float(result.duration), float(result.power)):
			continue
		(result.targets as Array[Enemy]).append(enemy)
		result.feared_count = int(result.feared_count) + 1
	return result

func apply_expiration_blast(
		expire_position: Vector2,
		summon_damage: float,
		candidate_modifier_callback: Callable,
		radius_query_callback: Callable
	) -> Dictionary:
	var result := _empty_expiration_blast_result()
	if summon_damage <= 0.0:
		result.reason = &"invalid_damage"
		return result
	if not candidate_modifier_callback.is_valid() or not radius_query_callback.is_valid():
		return result
	if not bool(candidate_modifier_callback.call(&"spirit_expiration_blast", false)):
		result.reason = &"inactive_growth"
		return result
	result.eligible = true
	result.reason = &"resolved"
	result.radius = maxf(float(candidate_modifier_callback.call(&"spirit_expiration_radius", 110.0)), 0.0)
	result.damage_per_target = summon_damage * maxf(float(candidate_modifier_callback.call(&"spirit_expiration_damage", 0.55)), 0.0)
	var queried_targets: Array = radius_query_callback.call(expire_position, float(result.radius))
	for value in queried_targets:
		var enemy := value as Enemy
		if not is_instance_valid(enemy) or not enemy.active:
			continue
		(result.targets as Array[Enemy]).append(enemy)
		result.damage = float(result.damage) + enemy.take_damage(float(result.damage_per_target), EXPIRATION_DAMAGE_SOURCE, true)
		result.hit_count = int(result.hit_count) + 1
	return result

func _empty_generation_fear_result() -> Dictionary:
	return {
		"eligible": false,
		"reason": &"invalid_dependencies",
		"radius": 0.0,
		"duration": 0.0,
		"power": 0.0,
		"feared_count": 0,
		"targets": [] as Array[Enemy],
	}

func _empty_expiration_blast_result() -> Dictionary:
	return {
		"eligible": false,
		"reason": &"invalid_dependencies",
		"radius": 0.0,
		"damage_per_target": 0.0,
		"damage": 0.0,
		"hit_count": 0,
		"targets": [] as Array[Enemy],
	}
