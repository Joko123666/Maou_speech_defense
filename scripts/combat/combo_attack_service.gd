class_name ComboAttackService
extends RefCounted

func resolve_line_charge(
	profile: ComboAttackProfileData,
	origin: Vector2,
	destination: Vector2,
	enemies: Array[Enemy],
	base_damage: float,
	damage_multiplier: float = 1.0,
	knockback_multiplier: float = 1.0,
	path_width_multiplier: float = 1.0
) -> Dictionary:
	var result := {"damage": 0.0, "targets": [] as Array[Enemy]}
	if profile == null or origin.is_equal_approx(destination) or base_damage <= 0.0:
		return result
	var targets: Array[Enemy] = []
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or not enemy.active:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, origin, destination)
		if closest.distance_to(enemy.global_position) <= profile.path_half_width * path_width_multiplier + enemy.data.radius:
			targets.append(enemy)
	_sort_along_path(targets, origin, destination)
	var dealt := 0.0
	for enemy in targets:
		dealt += enemy.take_damage(base_damage * profile.damage_multiplier * damage_multiplier, &"retainer_combo", true)
		if enemy.active and profile.knockback > 0.0:
			enemy.apply_knockback(profile.knockback * knockback_multiplier)
	result.damage = dealt
	result.targets = targets
	return result

func _sort_along_path(targets: Array[Enemy], origin: Vector2, destination: Vector2) -> void:
	var direction := origin.direction_to(destination)
	targets.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return (a.global_position - origin).dot(direction) < (b.global_position - origin).dot(direction)
	)
