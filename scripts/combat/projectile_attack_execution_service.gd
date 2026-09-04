class_name ProjectileAttackExecutionService
extends RefCounted

const DEFAULT_EDGE_DAMAGE_MULTIPLIER := 0.55
const AREA_PRESENTATION_LIMIT := 5
const AREA_IMPACT_POINT_LIMIT := 9

func build_volley_profile(behavior: StringName, damage: float, modifiers: Dictionary, attack_count: int) -> Dictionary:
	var profile := {"count": 1, "damage": damage, "warcry_triggered": false}
	if behavior != &"rapid":
		return profile
	profile.count = clampi(int(modifiers.get("volley_shots", 1)), 1, 3)
	profile.damage = damage * float(modifiers.get("volley_damage", 1.0))
	var warcry_interval := int(modifiers.get("warcry_interval", 0))
	profile.warcry_triggered = warcry_interval > 0 and attack_count % warcry_interval == 0
	if bool(profile.warcry_triggered):
		profile.damage *= float(modifiers.get("warcry_damage", 1.0))
	return profile

func build_motion_profile(behavior: StringName, volley_index: int, tower_color: Color) -> Dictionary:
	var profile := {
		"speed": 680.0,
		"length": 38.0,
		"tint": Color.WHITE,
		"uses_artillery_fallback": false,
	}
	match behavior:
		&"rapid":
			profile.speed = 680.0 + volley_index * 55.0
			profile.length = 30.0 + volley_index * 3.0
		&"area":
			profile.speed = 320.0
			profile.length = 46.0
			profile.uses_artillery_fallback = true
		&"unique_single":
			profile.speed = 760.0
			profile.length = 44.0
			profile.tint = tower_color.lightened(0.28)
	return profile

func execute_area(
		impact_position: Vector2,
		effective_radius: float,
		damage: float,
		modifiers: Dictionary,
		target_query: Callable,
		hit_callback: Callable,
		followup_callback: Callable,
		closest_target_callback: Callable
	) -> Dictionary:
	var targets: Array[Enemy] = []
	targets.assign(target_query.call(impact_position, effective_radius) as Array)
	var impact_points: Array[Vector2] = [impact_position]
	var dealt := 0.0
	for hit_index in targets.size():
		var target := targets[hit_index]
		var distance_ratio := clampf(target.global_position.distance_to(impact_position) / maxf(effective_radius, 1.0), 0.0, 1.0)
		var hit_damage := damage * lerpf(1.0, float(modifiers.get("edge_damage", DEFAULT_EDGE_DAMAGE_MULTIPLIER)), distance_ratio)
		dealt += float(hit_callback.call(
			target,
			hit_damage,
			hit_index < AREA_PRESENTATION_LIMIT,
			0.48 + (1.0 - distance_ratio) * 0.22
		))
		if impact_points.size() < AREA_IMPACT_POINT_LIMIT:
			impact_points.append(target.global_position)
	dealt += float(followup_callback.call(targets))
	return {
		"terminal_miss": false,
		"dealt": dealt,
		"hit_count": targets.size(),
		"hit_target": closest_target_callback.call(targets, impact_position) as Enemy,
		"effective_area_radius": effective_radius,
		"impact_points": impact_points,
	}

func execute_direct(
		hit_target: Enemy,
		impact_position: Vector2,
		effective_area_radius: float,
		damage: float,
		damage_callback: Callable,
		common_status_callback: Callable,
		behavior_hit_callback: Callable,
		presentation_callback: Callable,
		followup_callback: Callable
	) -> Dictionary:
	if hit_target == null or not hit_target.active:
		return {"terminal_miss": true}
	var dealt := float(damage_callback.call(hit_target, damage))
	common_status_callback.call(hit_target, damage)
	behavior_hit_callback.call(hit_target, damage, dealt)
	presentation_callback.call(hit_target, damage)
	dealt += float(followup_callback.call(hit_target, damage))
	return {
		"terminal_miss": false,
		"dealt": dealt,
		"hit_count": 1,
		"hit_target": hit_target,
		"effective_area_radius": effective_area_radius,
		"impact_points": [impact_position],
	}
