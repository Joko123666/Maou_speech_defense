class_name CursorAttackExecutionService
extends RefCounted

const FINAL_SLASH_LENGTH_MULTIPLIER := 1.55
const FINAL_SLASH_WIDTH_MULTIPLIER := 0.34
const FINAL_SLASH_DAMAGE_MULTIPLIER := 0.85
const SPLIT_ZONE_OFFSET := 96.0
const SPLIT_ZONE_RADIUS_MULTIPLIER := 0.62
const SPLIT_ZONE_DAMAGE_MULTIPLIER := 0.55
const CHARGED_EXPLOSION_RADIUS_MULTIPLIER := 1.35
const HORSE_AREA_RADIUS_MULTIPLIER := 0.72

var repeat_target: Enemy
var repeat_hits: int = 0

func execute_primary(
		attack_type: StringName,
		candidates: Array[Enemy],
		target_position: Vector2,
		damage: float,
		radius: float,
		knockback: float,
		modifiers: Dictionary,
		retainer_plan: Dictionary,
		closest_target_callback: Callable,
		retainer_damage_multiplier_callback: Callable,
		hit_callback: Callable,
		retainer_knockback_multiplier_callback: Callable,
		boosted_knockback_callback: Callable,
		break_boss_lock_callback: Callable
	) -> Dictionary:
	if attack_type in [&"area", &"zone"] or bool(retainer_plan.get("force_area", false)):
		return _execute_area_primary(candidates, target_position, damage, radius, knockback, modifiers, retainer_plan, retainer_damage_multiplier_callback, hit_callback, retainer_knockback_multiplier_callback, boosted_knockback_callback, break_boss_lock_callback)
	return _execute_single_primary(attack_type, candidates, target_position, damage, knockback, modifiers, retainer_plan, closest_target_callback, hit_callback, retainer_knockback_multiplier_callback, boosted_knockback_callback, break_boss_lock_callback)

func execute_damage_followups(
		target_position: Vector2,
		damage: float,
		radius: float,
		stationary_ratio: float,
		modifiers: Dictionary,
		retainer_plan: Dictionary,
		segment_query_callback: Callable,
		radius_query_callback: Callable,
		damage_callback: Callable,
		presentation_callback: Callable
	) -> float:
	var dealt := 0.0
	if bool(retainer_plan.get("final_slash", false)):
		dealt += _execute_final_slash(target_position, damage, radius, retainer_plan, segment_query_callback, damage_callback, presentation_callback)
	if bool(modifiers.get("split_zone", false)):
		dealt += _execute_split_zones(target_position, damage, radius, radius_query_callback, damage_callback, presentation_callback)
	if modifiers.has("charged_explosion") and stationary_ratio >= 1.0:
		var charged_radius := radius * CHARGED_EXPLOSION_RADIUS_MULTIPLIER
		dealt += _damage_radius(target_position, charged_radius, damage * float(modifiers.charged_explosion), &"cursor_charge", radius_query_callback, damage_callback)
		presentation_callback.call({"type": &"charged_explosion", "position": target_position, "radius": charged_radius})
	if modifiers.has("jugdied_horse_area"):
		var horse_radius := radius * HORSE_AREA_RADIUS_MULTIPLIER * float(modifiers.get("jugdied_horse_radius", 1.0))
		dealt += _damage_radius(target_position, horse_radius, damage * float(modifiers.jugdied_horse_area), &"jugdied_horse", radius_query_callback, damage_callback)
		presentation_callback.call({"type": &"horse_area", "position": target_position, "radius": horse_radius})
	return dealt

func _execute_area_primary(
		candidates: Array[Enemy],
		target_position: Vector2,
		damage: float,
		radius: float,
		knockback: float,
		modifiers: Dictionary,
		retainer_plan: Dictionary,
		retainer_damage_multiplier_callback: Callable,
		hit_callback: Callable,
		retainer_knockback_multiplier_callback: Callable,
		boosted_knockback_callback: Callable,
		break_boss_lock_callback: Callable
	) -> Dictionary:
	var dealt := 0.0
	for enemy in candidates:
		if enemy.global_position.distance_to(target_position) > radius:
			continue
		var multiplier := float(retainer_damage_multiplier_callback.call(enemy, target_position, radius, retainer_plan))
		dealt += _execute_hit(enemy, damage * multiplier, true, knockback, modifiers, retainer_plan, hit_callback, retainer_knockback_multiplier_callback, boosted_knockback_callback, break_boss_lock_callback)
	return {"dealt": dealt, "damage": damage, "target": null}

func _execute_single_primary(
		attack_type: StringName,
		candidates: Array[Enemy],
		target_position: Vector2,
		damage: float,
		knockback: float,
		modifiers: Dictionary,
		retainer_plan: Dictionary,
		closest_target_callback: Callable,
		hit_callback: Callable,
		retainer_knockback_multiplier_callback: Callable,
		boosted_knockback_callback: Callable,
		break_boss_lock_callback: Callable
	) -> Dictionary:
	var target := _select_target(attack_type, candidates, target_position, modifiers, closest_target_callback)
	if target == null:
		return {"dealt": 0.0, "damage": damage, "target": null}
	damage *= _repeat_damage_multiplier(target, modifiers)
	var dealt := 0.0
	var strike_count := maxi(int(retainer_plan.get("strike_count", 1)), 1)
	var strike_damage := float(retainer_plan.get("strike_damage", 1.0))
	for _strike in strike_count:
		if not is_instance_valid(target) or not target.active:
			break
		dealt += _execute_hit(target, damage * strike_damage, false, knockback, modifiers, retainer_plan, hit_callback, retainer_knockback_multiplier_callback, boosted_knockback_callback, break_boss_lock_callback)
	return {"dealt": dealt, "damage": damage, "target": target}

func _execute_hit(
		target: Enemy,
		damage: float,
		is_area: bool,
		knockback: float,
		modifiers: Dictionary,
		retainer_plan: Dictionary,
		hit_callback: Callable,
		retainer_knockback_multiplier_callback: Callable,
		boosted_knockback_callback: Callable,
		break_boss_lock_callback: Callable
	) -> float:
	var dealt := float(hit_callback.call(target, damage, is_area, modifiers, retainer_plan))
	var knockback_multiplier := float(retainer_knockback_multiplier_callback.call(target, retainer_plan))
	target.apply_knockback(knockback * knockback_multiplier)
	if knockback_multiplier > 1.0:
		boosted_knockback_callback.call()
	break_boss_lock_callback.call(target)
	return dealt

func _select_target(attack_type: StringName, candidates: Array[Enemy], target_position: Vector2, modifiers: Dictionary, closest_target_callback: Callable) -> Enemy:
	if bool(modifiers.get("tracking", false)) and is_instance_valid(repeat_target) and repeat_target.active and repeat_target in candidates:
		return repeat_target
	return closest_target_callback.call(candidates, target_position, attack_type == &"heavy") as Enemy

func _repeat_damage_multiplier(target: Enemy, modifiers: Dictionary) -> float:
	if target == repeat_target:
		repeat_hits += 1
	else:
		repeat_target = target
		repeat_hits = 1
	if not modifiers.has("repeat_damage_step"):
		return 1.0
	return 1.0 + minf(maxf(repeat_hits - 1, 0) * float(modifiers.repeat_damage_step), float(modifiers.get("repeat_damage_cap", 0.0)))

func _execute_final_slash(
		target_position: Vector2,
		damage: float,
		radius: float,
		retainer_plan: Dictionary,
		segment_query_callback: Callable,
		damage_callback: Callable,
		presentation_callback: Callable
	) -> float:
	var slash_start := target_position
	var slash_finish := target_position + Vector2(radius * FINAL_SLASH_LENGTH_MULTIPLIER, 0.0)
	var half_width := radius * FINAL_SLASH_WIDTH_MULTIPLIER
	var slash_targets := 0
	var dealt := 0.0
	for enemy in segment_query_callback.call(slash_start, slash_finish, half_width) as Array[Enemy]:
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, slash_start, slash_finish)
		var enemy_radius := enemy.data.radius if enemy.data != null else 0.0
		if closest.distance_to(enemy.global_position) > half_width + enemy_radius:
			continue
		dealt += float(damage_callback.call(enemy, damage * float(retainer_plan.get("final_slash_damage", FINAL_SLASH_DAMAGE_MULTIPLIER)), &"kanda_final_slash"))
		slash_targets += 1
	presentation_callback.call({"type": &"final_slash", "start": slash_start, "finish": slash_finish, "radius": half_width, "target_count": slash_targets})
	return dealt

func _execute_split_zones(
		target_position: Vector2,
		damage: float,
		radius: float,
		radius_query_callback: Callable,
		damage_callback: Callable,
		presentation_callback: Callable
	) -> float:
	var split_radius := radius * SPLIT_ZONE_RADIUS_MULTIPLIER
	var dealt := 0.0
	for offset in [-SPLIT_ZONE_OFFSET, SPLIT_ZONE_OFFSET]:
		var split_position := target_position + Vector2(0.0, offset)
		dealt += _damage_radius(split_position, split_radius, damage * SPLIT_ZONE_DAMAGE_MULTIPLIER, &"cursor_split_zone", radius_query_callback, damage_callback)
		presentation_callback.call({"type": &"split_zone", "position": split_position, "radius": split_radius})
	return dealt

func _damage_radius(position: Vector2, radius: float, damage: float, source: StringName, radius_query_callback: Callable, damage_callback: Callable) -> float:
	var dealt := 0.0
	for enemy in radius_query_callback.call(position, radius) as Array[Enemy]:
		dealt += float(damage_callback.call(enemy, damage, source))
	return dealt
