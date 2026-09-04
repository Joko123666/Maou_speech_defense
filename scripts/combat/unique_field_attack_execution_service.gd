class_name UniqueFieldAttackExecutionService
extends RefCounted

const RADIAL_MIN_DAMAGE_MULTIPLIER := 0.68
const RADIAL_PRESENTATION_LIMIT := 6
const RANDOM_MIN_DAMAGE_MULTIPLIER := 0.72
const RANDOM_MAX_DAMAGE_MULTIPLIER := 1.48
const RANDOM_TARGET_LIMIT := 4

func execute_radial(
		enemies: Array[Enemy],
		origin: Vector2,
		attack_range: float,
		damage: float,
		hit_callback: Callable
	) -> Dictionary:
	var dealt := 0.0
	var normalized_range := maxf(attack_range, 1.0)
	for hit_index in enemies.size():
		var target := enemies[hit_index]
		var distance_ratio := clampf(origin.distance_to(target.global_position) / normalized_range, 0.0, 1.0)
		var radial_damage := damage * lerpf(1.0, RADIAL_MIN_DAMAGE_MULTIPLIER, distance_ratio)
		dealt += float(hit_callback.call(target, radial_damage, hit_index < RADIAL_PRESENTATION_LIMIT))
	return {"dealt": dealt, "hit_count": enemies.size()}

func execute_random(
		enemies: Array[Enemy],
		damage: float,
		first_target_callback: Callable,
		hit_callback: Callable
	) -> Dictionary:
	var target: Enemy
	var dealt := 0.0
	var random_pool: Array[Enemy] = enemies.duplicate()
	var hit_count := mini(random_pool.size(), RANDOM_TARGET_LIMIT)
	for _shot in hit_count:
		var random_target := RunRng.pick(random_pool) as Enemy
		random_pool.erase(random_target)
		if target == null:
			target = random_target
			first_target_callback.call(random_target)
		var lucky_damage := damage * RunRng.rangef(RANDOM_MIN_DAMAGE_MULTIPLIER, RANDOM_MAX_DAMAGE_MULTIPLIER)
		dealt += float(hit_callback.call(random_target, lucky_damage))
	return {"target": target, "dealt": dealt, "hit_count": hit_count}
