class_name CombatEffect
extends Node2D

const MAX_ACTIVE_TOWER_HITS: int = 48
static var active_tower_hits: int = 0
static var active_effects: int = 0

var start_position: Vector2
var end_position: Vector2
var effect_color: Color = Color.WHITE
var area_radius: float = 0.0
var intensity: float = 0.25
var effect_style: StringName = &"trace"
var lifetime: float = 0.16
var remaining: float = 0.16
var spark_directions: Array[Vector2] = []
var path_points: Array[Vector2] = []
var impact_direction: Vector2 = Vector2.RIGHT
var battlefield_rect := Rect2()
var core_skill_type: StringName = &""
var stamp_texture: Texture2D
var counted_tower_hit: bool = false
var counted_active_effect: bool = false
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func setup(from: Vector2, to: Vector2, color: Color, radius: float = 0.0, strength: float = 0.2) -> void:
	_register_active_effect()
	start_position = from
	end_position = to
	effect_color = color
	area_radius = radius
	intensity = clampf(strength, 0.05, 1.0)
	effect_style = &"trace"
	lifetime = 0.13 + intensity * 0.09
	remaining = lifetime
	_prepare_sparks(4 + roundi(intensity * 4.0))
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_impact(at: Vector2, color: Color, radius: float = 0.0, strength: float = 0.25) -> void:
	_register_active_effect()
	start_position = at
	end_position = at
	effect_color = color
	area_radius = radius
	intensity = clampf(strength, 0.05, 1.0)
	effect_style = &"impact"
	lifetime = 0.2 + intensity * 0.16
	remaining = lifetime
	_prepare_sparks(6 + roundi(intensity * 8.0))
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_burst(at: Vector2, color: Color, radius: float = 110.0, strength: float = 0.8) -> void:
	_register_active_effect()
	start_position = at
	end_position = at
	effect_color = color
	area_radius = maxf(radius, 24.0)
	intensity = clampf(strength, 0.1, 1.0)
	effect_style = &"burst"
	lifetime = 0.42 + intensity * 0.24
	remaining = lifetime
	_prepare_sparks(10 + roundi(intensity * 10.0))
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_pattern(at: Vector2, color: Color, radius: float, style: StringName, strength: float = 0.6, duration: float = 0.55) -> void:
	_register_active_effect()
	start_position = at
	end_position = at
	effect_color = color
	area_radius = maxf(radius, 18.0)
	intensity = clampf(strength, 0.1, 1.0)
	effect_style = style
	lifetime = maxf(duration, 0.2)
	remaining = lifetime
	_prepare_sparks(8 + roundi(intensity * 8.0))
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_candidate_stamp(at: Vector2, texture: Texture2D, color: Color, radius: float, style: StringName, strength: float = 0.8, duration: float = 0.6) -> void:
	_register_active_effect()
	start_position = at
	end_position = at
	stamp_texture = texture
	effect_color = color
	area_radius = maxf(radius, 24.0)
	intensity = clampf(strength, 0.1, 1.0)
	effect_style = style
	lifetime = maxf(duration, 0.24)
	remaining = lifetime
	_prepare_sparks(6 + roundi(intensity * 6.0))
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_chain(points: Array[Vector2], color: Color, strength: float = 0.65) -> void:
	_register_active_effect()
	path_points = points.duplicate()
	start_position = path_points[0] if not path_points.is_empty() else Vector2.ZERO
	end_position = path_points.back() if not path_points.is_empty() else Vector2.ZERO
	effect_color = color
	intensity = clampf(strength, 0.1, 1.0)
	effect_style = &"chain"
	lifetime = 0.34 + intensity * 0.18
	remaining = lifetime
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_core_cast(origin: Vector2, target: Vector2, battle_rect: Rect2, color: Color, skill_type: StringName, duration: float) -> void:
	_register_active_effect()
	start_position = origin
	end_position = target
	battlefield_rect = battle_rect
	effect_color = color
	core_skill_type = skill_type
	effect_style = &"core_cast"
	intensity = 1.0
	lifetime = maxf(duration, 0.2)
	remaining = lifetime
	path_points.clear()
	if skill_type == &"barrage":
		var fractions: Array[Vector2] = [
			Vector2(0.76, 0.18), Vector2(0.47, 0.31), Vector2(0.88, 0.43), Vector2(0.60, 0.56),
			Vector2(0.34, 0.69), Vector2(0.79, 0.79), Vector2(0.52, 0.87), Vector2(0.93, 0.63),
		]
		for fraction in fractions:
			path_points.append(battlefield_rect.position + battlefield_rect.size * fraction)
	add_to_group(&"combat_effects")
	queue_redraw()

func setup_tower_hit(at: Vector2, color: Color, behavior: StringName, direction: Vector2, strength: float = 0.35, radius: float = 24.0) -> void:
	_register_active_effect()
	start_position = at
	end_position = at
	effect_color = color
	area_radius = maxf(radius, 16.0)
	intensity = clampf(strength, 0.12, 1.0)
	impact_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	effect_style = StringName("hit_%s" % behavior)
	counted_tower_hit = true
	active_tower_hits += 1
	lifetime = 0.22 + intensity * 0.18
	if behavior in [&"area", &"slow", &"mark", &"unique_radial", &"unique_random"]:
		lifetime += 0.12
	remaining = lifetime
	_prepare_sparks(5 + roundi(intensity * 7.0))
	add_to_group(&"combat_effects")
	queue_redraw()

func _exit_tree() -> void:
	if counted_active_effect:
		active_effects = maxi(active_effects - 1, 0)
		counted_active_effect = false
	if counted_tower_hit:
		active_tower_hits = maxi(active_tower_hits - 1, 0)
		counted_tower_hit = false

func _register_active_effect() -> void:
	if counted_active_effect:
		return
	counted_active_effect = true
	active_effects += 1

func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var alpha := clampf(remaining / maxf(lifetime, 0.01), 0.0, 1.0)
	var progress := 1.0 - alpha
	match effect_style:
		&"trace":
			_draw_trace(alpha, progress)
		&"burst":
			_draw_burst(alpha, progress)
		&"zone":
			_draw_zone(alpha, progress)
		&"slash":
			_draw_slash(alpha, progress)
		&"sigil":
			_draw_sigil(alpha, progress)
		&"shockwave":
			_draw_shockwave(alpha, progress)
		&"orbit":
			_draw_orbit(alpha, progress)
		&"chain":
			_draw_chain(alpha, progress)
		&"campaign_exit":
			_draw_campaign_exit(alpha, progress)
		&"jiane_dream_barrier":
			_draw_jiane_dream_barrier(alpha, progress)
		&"judaginda_verdict_seal":
			_draw_judaginda_verdict_seal(alpha, progress)
		&"core_cast":
			_draw_core_cast(progress)
		&"cursor_iron":
			_draw_cursor_iron(alpha, progress)
		&"cursor_silver":
			_draw_cursor_silver(alpha, progress)
		&"cursor_gold":
			_draw_cursor_gold(alpha, progress)
		&"cursor_platinum":
			_draw_cursor_platinum(alpha, progress)
		&"cursor_vanguard":
			_draw_cursor_platinum(alpha, progress)
		&"hit_rapid":
			_draw_rapid_hit(alpha, progress)
		&"hit_area":
			_draw_artillery_hit(alpha, progress)
		&"hit_pierce":
			_draw_pierce_hit(alpha, progress)
		&"hit_slow":
			_draw_frost_hit(alpha, progress)
		&"hit_knockback":
			_draw_kinetic_hit(alpha, progress)
		&"hit_execute":
			_draw_execute_hit(alpha, progress)
		&"hit_mark":
			_draw_mark_hit(alpha, progress)
		&"hit_chain":
			_draw_electric_hit(alpha, progress)
		&"hit_unique_single":
			_draw_rapid_hit(alpha, progress)
		&"hit_unique_pierce":
			_draw_pierce_hit(alpha, progress)
		&"hit_unique_radial":
			_draw_artillery_hit(alpha, progress)
		&"hit_unique_random":
			_draw_electric_hit(alpha, progress)
		_:
			_draw_impact(alpha, progress)

func _draw_campaign_exit(alpha: float, progress: float) -> void:
	var portal_radius := area_radius * lerpf(0.46, 1.0, sin(progress * PI * 0.5))
	var stamp_scale := 1.0 + sin(progress * PI) * 0.18
	var stamp_radius := area_radius * 0.44 * stamp_scale
	# 바닥 송환 포털과 위로 사라지는 투표용지형 입자를 함께 보여준다.
	draw_set_transform(end_position + Vector2(0.0, area_radius * 0.36), 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, portal_radius, Color(effect_color, alpha * 0.12))
	draw_arc(Vector2.ZERO, portal_radius, progress * TAU * 1.6, progress * TAU * 1.6 + PI * 1.55, 42, Color(effect_color.lightened(0.42), alpha * 0.9), 4.0, true)
	draw_arc(Vector2.ZERO, portal_radius * 0.68, -progress * TAU, -progress * TAU + PI * 1.35, 34, Color(effect_color, alpha * 0.72), 2.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var stamp_center := end_position - Vector2(0.0, area_radius * (0.14 + progress * 0.22))
	draw_circle(stamp_center, stamp_radius, Color(0.025, 0.035, 0.06, alpha * 0.7))
	draw_arc(stamp_center, stamp_radius, -PI * 0.5, TAU - PI * 0.5, 36, Color(effect_color.lightened(0.3), alpha), 3.4, true)
	draw_arc(stamp_center, stamp_radius * 0.72, progress * TAU, progress * TAU + PI * 1.55, 28, Color(effect_color, alpha * 0.86), 2.0, true)
	var check_points := PackedVector2Array([
		stamp_center + Vector2(-stamp_radius * 0.42, 0.0),
		stamp_center + Vector2(-stamp_radius * 0.1, stamp_radius * 0.3),
		stamp_center + Vector2(stamp_radius * 0.46, -stamp_radius * 0.32),
	])
	draw_polyline(check_points, Color.WHITE, 3.0 + intensity * 2.0, true)
	for particle_index in 5:
		var offset_x := lerpf(-area_radius * 0.54, area_radius * 0.54, float(particle_index) / 4.0)
		var rise := area_radius * (0.15 + progress * (0.65 + float(particle_index % 2) * 0.18))
		var particle_center := end_position + Vector2(offset_x, area_radius * 0.34 - rise)
		var particle_size := 3.0 + float(particle_index % 3)
		draw_rect(Rect2(particle_center - Vector2.ONE * particle_size, Vector2.ONE * particle_size * 2.0), Color(effect_color.lightened(0.5), alpha * 0.78), true)

func _draw_jiane_dream_barrier(alpha: float, progress: float) -> void:
	var pulse := 0.96 + sin(progress * PI) * 0.08
	_draw_stamp_texture(alpha * 0.82, pulse, sin(progress * PI) * 0.035)
	var barrier_radius := area_radius * (0.62 + progress * 0.32)
	draw_circle(end_position, barrier_radius, Color(effect_color, alpha * 0.055))
	draw_arc(end_position, barrier_radius, -PI * 0.92, PI * 0.92, 46, Color(effect_color.lightened(0.42), alpha * 0.9), 3.0 + intensity * 1.5, true)
	draw_arc(end_position, barrier_radius * 0.78, PI * 0.08, PI * 1.92, 38, Color(effect_color, alpha * 0.66), 1.8, true)
	_draw_sparks(alpha * 0.55, progress, area_radius * 0.72)

func _draw_judaginda_verdict_seal(alpha: float, progress: float) -> void:
	var stamp_scale := lerpf(1.34, 0.9, minf(progress * 2.6, 1.0))
	_draw_stamp_texture(alpha * 0.88, stamp_scale, 0.0)
	var seal_radius := area_radius * lerpf(0.52, 1.0, minf(progress * 1.8, 1.0))
	draw_arc(end_position, seal_radius, 0.0, TAU, 48, Color(effect_color, alpha * 0.82), 2.2 + intensity * 1.8, true)
	draw_line(end_position - Vector2(0.0, area_radius * 0.74), end_position + Vector2(0.0, area_radius * 0.78), Color(effect_color.lightened(0.44), alpha * 0.8), 2.0 + intensity, true)
	_draw_sparks(alpha * 0.62, progress, area_radius * 0.86)

func _draw_stamp_texture(alpha: float, scale_factor: float, rotation: float) -> void:
	if stamp_texture == null:
		return
	var draw_extent := area_radius * scale_factor
	draw_set_transform(end_position, rotation, Vector2.ONE)
	draw_texture_rect(stamp_texture, Rect2(Vector2(-draw_extent, -draw_extent), Vector2.ONE * draw_extent * 2.0), false, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_core_cast(progress: float) -> void:
	var pulse := 0.68 + sin(progress * TAU * 5.0) * 0.22
	var cast_alpha := clampf(0.42 + progress * 0.5, 0.0, 1.0)
	match core_skill_type:
		&"beam":
			var half_width := lerpf(118.0, 48.0, progress)
			var line_start := Vector2(battlefield_rect.position.x, end_position.y)
			var line_end := Vector2(battlefield_rect.end.x, end_position.y)
			draw_rect(Rect2(Vector2(line_start.x, end_position.y - half_width), Vector2(line_end.x - line_start.x, half_width * 2.0)), Color(effect_color, 0.035 + progress * 0.07), true)
			for side in [-1.0, 1.0]:
				var y := end_position.y + half_width * float(side)
				draw_line(Vector2(line_start.x, y), Vector2(line_end.x, y), Color(effect_color.lightened(0.42), cast_alpha * pulse), 2.0 + progress * 2.5, true)
			for ray_index in 5:
				var source := start_position + Vector2(0.0, lerpf(-66.0, 66.0, float(ray_index) / 4.0))
				draw_line(source, line_end, Color(effect_color, 0.12 + progress * 0.22), 1.2, true)
		&"radial":
			var max_radius := battlefield_rect.size.length() * 0.72
			for ring_index in 4:
				var ring_progress := clampf(progress - ring_index * 0.08, 0.0, 1.0)
				var radius := lerpf(max_radius, 72.0 + ring_index * 10.0, ring_progress)
				draw_arc(start_position, radius, 0.0, TAU, 72, Color(effect_color.lightened(0.1 * ring_index), cast_alpha * (0.82 - ring_index * 0.13)), 2.0 + progress * 2.0, true)
			for ray_index in 10:
				var direction := Vector2.from_angle(TAU * ray_index / 10.0 + progress * 0.7)
				draw_line(start_position + direction * 48.0, start_position + direction * lerpf(max_radius * 0.75, 104.0, progress), Color(effect_color, 0.12 + progress * 0.32), 1.4, true)
		&"wall":
			var spacing := 112.0
			for offset in [-spacing, 0.0, spacing]:
				var y := clampf(end_position.y + float(offset), battlefield_rect.position.y, battlefield_rect.end.y)
				var line_start := Vector2(battlefield_rect.position.x, y)
				var line_end := Vector2(battlefield_rect.end.x, y)
				draw_line(line_start, line_end, Color(effect_color, 0.08 + progress * 0.15), 30.0 - progress * 14.0, true)
				draw_line(line_start, line_end, Color(effect_color.lightened(0.48), cast_alpha * pulse), 2.5 + progress * 3.5, true)
				for node_index in 7:
					var node_position := line_start.lerp(line_end, float(node_index) / 6.0)
					draw_rect(Rect2(node_position - Vector2.ONE * (4.0 + progress * 3.0), Vector2.ONE * (8.0 + progress * 6.0)), Color(effect_color.lightened(0.3), cast_alpha), false, 2.0, true)
		&"barrage":
			for index in path_points.size():
				var point := path_points[index]
				var local_progress := clampf(progress * 1.35 - index * 0.045, 0.0, 1.0)
				var radius := lerpf(42.0, 13.0, local_progress)
				draw_arc(point, radius, local_progress * TAU * (1.0 if index % 2 == 0 else -1.0), local_progress * TAU + PI * 1.6, 22, Color(effect_color.lightened(0.4), cast_alpha * pulse), 2.0 + local_progress * 2.0, true)
				draw_line(point - Vector2(radius * 0.55, 0.0), point + Vector2(radius * 0.55, 0.0), Color(effect_color, cast_alpha * 0.74), 1.4, true)
				draw_line(point - Vector2(0.0, radius * 0.55), point + Vector2(0.0, radius * 0.55), Color(effect_color, cast_alpha * 0.74), 1.4, true)

func _draw_rapid_hit(alpha: float, progress: float) -> void:
	var perpendicular := impact_direction.orthogonal()
	var travel := area_radius * (0.35 + progress * 0.85)
	draw_line(end_position - impact_direction * 18.0, end_position + impact_direction * travel, Color(effect_color.lightened(0.5), alpha), 2.2 + intensity * 1.8, true)
	for side in [-1.0, 1.0]:
		var shard_direction: Vector2 = (impact_direction * 0.8 + perpendicular * float(side) * 0.58).normalized()
		draw_line(end_position + shard_direction * 5.0, end_position + shard_direction * travel * 0.72, Color(effect_color, alpha * 0.85), 1.4 + intensity, true)
	draw_circle(end_position, (5.0 + intensity * 5.0) * alpha, Color(effect_color.lightened(0.55), alpha * 0.82))

func _draw_artillery_hit(alpha: float, progress: float) -> void:
	var outer := area_radius * (0.25 + progress * 0.9)
	draw_circle(end_position, outer * 0.72, Color(effect_color, alpha * 0.1))
	for ring_index in 2:
		draw_arc(end_position, outer * (1.0 - ring_index * 0.28), 0.0, TAU, 30, Color(effect_color.lightened(0.22 * ring_index), alpha * (0.9 - ring_index * 0.25)), 2.3 + intensity * 1.8, true)
	for index in 7:
		var direction := Vector2.from_angle(TAU * index / 7.0 + 0.23)
		var debris_position := end_position + direction * outer * (0.65 + float(index % 2) * 0.2)
		var size := 2.0 + intensity * 2.5
		draw_set_transform(debris_position, progress * 4.0 + index, Vector2.ONE)
		draw_rect(Rect2(Vector2(-size, -size), Vector2(size * 2.0, size * 2.0)), Color(effect_color.darkened(0.2), alpha * 0.85), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pierce_hit(alpha: float, progress: float) -> void:
	var perpendicular := impact_direction.orthogonal()
	var length := area_radius * (1.0 + progress * 1.25)
	for offset in [-5.0, 0.0, 5.0]:
		var center: Vector2 = end_position + perpendicular * float(offset)
		draw_line(center - impact_direction * length, center + impact_direction * length, Color(effect_color.lightened(0.42), alpha * (1.0 if is_zero_approx(offset) else 0.48)), 2.4 if is_zero_approx(offset) else 1.2, true)
	draw_arc(end_position, area_radius * (0.45 + progress), impact_direction.angle() - 1.1, impact_direction.angle() + 1.1, 18, Color(effect_color, alpha * 0.82), 2.0, true)

func _draw_frost_hit(alpha: float, progress: float) -> void:
	var crystal_radius := area_radius * (0.45 + progress * 0.55)
	for index in 6:
		var direction := Vector2.from_angle(TAU * index / 6.0)
		draw_line(end_position, end_position + direction * crystal_radius, Color(effect_color.lightened(0.5), alpha), 1.6 + intensity, true)
		var branch_start := end_position + direction * crystal_radius * 0.55
		for side in [-1.0, 1.0]:
			var branch_direction: Vector2 = direction.rotated(float(side) * 0.72)
			draw_line(branch_start, branch_start + branch_direction * crystal_radius * 0.3, Color(effect_color, alpha * 0.78), 1.3, true)
	draw_arc(end_position, crystal_radius * 0.72, 0.0, TAU, 24, Color(effect_color, alpha * 0.55), 1.4, true)

func _draw_kinetic_hit(alpha: float, progress: float) -> void:
	var perpendicular := impact_direction.orthogonal()
	for wave_index in 3:
		var distance := area_radius * (0.25 + progress * (0.7 + wave_index * 0.18))
		var center := end_position + impact_direction * distance
		var half_width := area_radius * (0.28 + wave_index * 0.12)
		draw_polyline(PackedVector2Array([center - perpendicular * half_width, center + impact_direction * area_radius * 0.18, center + perpendicular * half_width]), Color(effect_color, alpha * (0.9 - wave_index * 0.2)), 2.5 + intensity, true)
	for streak_index in 4:
		var offset := perpendicular * lerpf(-area_radius * 0.42, area_radius * 0.42, float(streak_index) / 3.0)
		draw_line(end_position + offset - impact_direction * 14.0, end_position + offset + impact_direction * area_radius * (0.5 + progress), Color(effect_color.lightened(0.35), alpha * 0.55), 1.5, true)

func _draw_execute_hit(alpha: float, progress: float) -> void:
	var reach := area_radius * clampf(progress * 2.8, 0.0, 1.0)
	for angle_offset in [-0.78, 0.78]:
		var direction: Vector2 = impact_direction.rotated(float(angle_offset))
		draw_line(end_position - direction * reach, end_position + direction * reach, Color(effect_color, alpha * 0.28), 8.0 * intensity, true)
		draw_line(end_position - direction * reach, end_position + direction * reach, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.4 + intensity * 1.5, true)
	draw_arc(end_position, area_radius * (0.6 + progress * 0.45), -2.4, -0.72, 18, Color(effect_color, alpha), 2.4, true)

func _draw_mark_hit(alpha: float, progress: float) -> void:
	var rotation := progress * TAU
	var radius := area_radius * (0.72 + 0.12 * sin(progress * PI))
	var diamond := PackedVector2Array()
	for index in 4:
		diamond.append(end_position + Vector2.from_angle(rotation + PI * 0.25 + TAU * index / 4.0) * radius)
	diamond.append(diamond[0])
	draw_polyline(diamond, Color(effect_color, alpha), 2.2 + intensity, true)
	draw_line(end_position - Vector2(radius * 0.5, 0.0), end_position + Vector2(radius * 0.5, 0.0), Color(effect_color.lightened(0.48), alpha * 0.9), 1.8, true)
	draw_circle(end_position, 3.0 + intensity * 3.0, Color(effect_color.lightened(0.55), alpha))

func _draw_electric_hit(alpha: float, progress: float) -> void:
	for arc_index in 3:
		var angle := impact_direction.angle() + (arc_index - 1) * 1.65
		var direction := Vector2.from_angle(angle)
		var perpendicular := direction.orthogonal()
		var points := PackedVector2Array([end_position])
		for segment_index in range(1, 5):
			var ratio := float(segment_index) / 4.0
			points.append(end_position + direction * area_radius * ratio + perpendicular * sin(segment_index * 4.3 + progress * TAU * 2.0) * 5.0)
		draw_polyline(points, Color(effect_color.lightened(0.5), alpha), 1.8 + intensity, true)
	draw_circle(end_position, (4.0 + intensity * 4.0) * alpha, Color(1.0, 1.0, 1.0, alpha * 0.82))

func _draw_trace(alpha: float, progress: float) -> void:
	var width := 2.2 + intensity * 4.0
	draw_line(start_position, end_position, Color(effect_color, alpha * 0.28), width * 2.5, true)
	draw_line(start_position, end_position, Color(effect_color.lightened(0.35), alpha), width, true)
	var pulse_position := start_position.lerp(end_position, clampf(progress * 1.8, 0.0, 1.0))
	draw_circle(pulse_position, 3.0 + intensity * 5.0, Color(effect_color.lightened(0.5), alpha))
	if area_radius > 0.0:
		draw_arc(end_position, area_radius * (0.75 + progress * 0.25), 0.0, TAU, 36, Color(effect_color, alpha * 0.7), 1.5 + intensity * 1.5, true)

func _draw_impact(alpha: float, progress: float) -> void:
	var core_radius := 4.0 + intensity * 11.0
	var ring_radius := core_radius + progress * (20.0 + intensity * 34.0)
	draw_circle(end_position, core_radius * alpha, Color(effect_color.lightened(0.5), alpha * 0.75))
	draw_circle(end_position, ring_radius, Color(effect_color, alpha * 0.1))
	draw_arc(end_position, ring_radius, 0.0, TAU, 28, Color(effect_color, alpha), 1.8 + intensity * 2.0, true)
	_draw_sparks(alpha, progress, 14.0 + intensity * 32.0)
	if area_radius > 0.0:
		var area_progress := 0.68 + progress * 0.32
		draw_circle(end_position, area_radius * area_progress, Color(effect_color, alpha * 0.08))
		draw_arc(end_position, area_radius * area_progress, 0.0, TAU, 40, Color(effect_color, alpha * 0.8), 1.5 + intensity * 2.0, true)

func _draw_burst(alpha: float, progress: float) -> void:
	var outer_radius := area_radius * (0.18 + progress * 0.82)
	var inner_radius := outer_radius * 0.66
	draw_circle(end_position, inner_radius, Color(effect_color, alpha * 0.12))
	draw_arc(end_position, outer_radius, 0.0, TAU, 48, Color(effect_color, alpha), 2.0 + intensity * 3.5, true)
	draw_arc(end_position, inner_radius, 0.0, TAU, 36, Color(effect_color.lightened(0.4), alpha * 0.8), 1.4 + intensity * 2.0, true)
	_draw_sparks(alpha, progress, area_radius * 0.82)
	for index in 6:
		var direction := Vector2.from_angle(TAU * index / 6.0)
		draw_line(end_position + direction * inner_radius * 0.65, end_position + direction * outer_radius, Color(effect_color, alpha * 0.72), 1.5 + intensity, true)

func _draw_zone(alpha: float, progress: float) -> void:
	var breathing := 0.94 + sin(progress * TAU * 3.0) * 0.06
	draw_circle(end_position, area_radius * breathing, Color(effect_color, alpha * 0.055))
	for ring_index in 3:
		var ring_ratio := fmod(progress * 1.35 + float(ring_index) / 3.0, 1.0)
		draw_arc(end_position, area_radius * ring_ratio, 0.0, TAU, 44, Color(effect_color, alpha * (1.0 - ring_ratio) * 0.78), 1.5 + intensity, true)
	_draw_sparks(alpha * 0.55, progress, area_radius * 0.72)

func _draw_slash(alpha: float, progress: float) -> void:
	var reach := area_radius * clampf(progress * 2.2, 0.0, 1.0)
	for angle in [-0.68, 0.68]:
		var direction := Vector2.from_angle(angle)
		var perpendicular := direction.orthogonal()
		var center := end_position + perpendicular * (progress - 0.5) * area_radius * 0.18
		draw_line(center - direction * reach, center + direction * reach, Color(effect_color, alpha * 0.28), 9.0 * intensity, true)
		draw_line(center - direction * reach, center + direction * reach, Color(effect_color.lightened(0.48), alpha), 2.0 + intensity * 2.2, true)
	draw_arc(end_position, area_radius * (0.45 + progress * 0.55), -1.05, 1.05, 22, Color(effect_color, alpha * 0.75), 2.0, true)

func _draw_sigil(alpha: float, progress: float) -> void:
	var rotation_offset := progress * TAU * 0.75
	var points := PackedVector2Array()
	for index in 6:
		points.append(end_position + Vector2.from_angle(rotation_offset + TAU * index / 6.0) * area_radius)
	points.append(points[0])
	draw_polyline(points, Color(effect_color, alpha * 0.88), 2.0 + intensity, true)
	draw_arc(end_position, area_radius * 0.66, -rotation_offset, TAU - rotation_offset, 42, Color(effect_color.lightened(0.35), alpha * 0.7), 1.5, true)
	for index in 3:
		var node_position := end_position + Vector2.from_angle(-rotation_offset + TAU * index / 3.0) * area_radius * 0.66
		draw_circle(node_position, 3.0 + intensity * 2.0, Color(effect_color, alpha))

func _draw_shockwave(alpha: float, progress: float) -> void:
	for ring_index in 3:
		var ring_progress := clampf(progress * 1.45 - ring_index * 0.16, 0.0, 1.0)
		if ring_progress <= 0.0:
			continue
		var radius := area_radius * ring_progress
		draw_arc(end_position, radius, -0.92, 0.92, 30, Color(effect_color, alpha * (1.0 - ring_progress * 0.4)), 2.0 + intensity * 2.4, true)
	for index in 5:
		var angle := lerpf(-0.72, 0.72, float(index) / 4.0)
		var direction := Vector2.from_angle(angle)
		draw_line(end_position + direction * area_radius * 0.25, end_position + direction * area_radius * (0.55 + progress * 0.4), Color(effect_color, alpha * 0.62), 1.5, true)

func _draw_orbit(alpha: float, progress: float) -> void:
	var orbit_rotation := progress * TAU * 2.4
	draw_arc(end_position, area_radius, 0.0, TAU, 64, Color(effect_color, alpha * 0.34), 1.5, true)
	for index in 4:
		var angle := orbit_rotation + TAU * index / 4.0
		var blade_center := end_position + Vector2.from_angle(angle) * area_radius
		draw_circle(blade_center, 9.0 + intensity * 4.0, Color(0.03, 0.07, 0.08, alpha * 0.9))
		draw_arc(blade_center, 9.0 + intensity * 4.0, angle, angle + PI * 1.55, 14, Color(effect_color.lightened(0.35), alpha), 3.0, true)
		for tooth_index in 6:
			var tooth_direction := Vector2.from_angle(angle + TAU * tooth_index / 6.0)
			draw_line(blade_center + tooth_direction * 8.0, blade_center + tooth_direction * 14.0, Color(effect_color, alpha), 2.0, true)

func _draw_chain(alpha: float, progress: float) -> void:
	if path_points.size() < 2:
		return
	for index in range(1, path_points.size()):
		var from := path_points[index - 1]
		var to := path_points[index]
		var direction := from.direction_to(to)
		var perpendicular := direction.orthogonal()
		var points := PackedVector2Array([from])
		for segment_index in range(1, 6):
			var ratio := float(segment_index) / 6.0
			var jitter := sin(float(segment_index) * 5.7 + progress * TAU * 3.0) * (5.0 + intensity * 4.0)
			points.append(from.lerp(to, ratio) + perpendicular * jitter)
		points.append(to)
		draw_polyline(points, Color(effect_color, alpha * 0.26), 7.0, true)
		draw_polyline(points, Color(effect_color.lightened(0.42), alpha), 2.0 + intensity, true)
		var pulse := from.lerp(to, fmod(progress * 2.0 + index * 0.18, 1.0))
		draw_circle(pulse, 4.0 + intensity * 3.0, Color(effect_color.lightened(0.55), alpha))

func _draw_cursor_iron(alpha: float, progress: float) -> void:
	var ring_radius := area_radius * (0.28 + progress * 0.72)
	draw_arc(end_position, ring_radius, 0.0, TAU, 48, Color(effect_color.lightened(0.35), alpha), 4.0 + intensity * 2.0, true)
	draw_arc(end_position, ring_radius * 0.72, 0.0, TAU, 40, Color(effect_color, alpha * 0.7), 2.0, true)
	for index in 4:
		var direction := Vector2.from_angle(index * PI * 0.5)
		var start := end_position + direction * area_radius * 0.16
		var finish := end_position + direction * ring_radius
		draw_line(start, finish, Color(effect_color.lightened(0.55), alpha), 5.0, true)

func _draw_cursor_silver(alpha: float, progress: float) -> void:
	var reticle_radius := area_radius * lerpf(1.0, 0.32, progress)
	var rotation := progress * TAU * 1.8
	for index in 3:
		var start := rotation + index * TAU / 3.0
		draw_arc(end_position, reticle_radius, start, start + 0.82, 12, Color(effect_color.lightened(0.55), alpha), 2.4 + intensity, true)
		var direction := Vector2.from_angle(start + 0.41)
		draw_line(end_position + direction * reticle_radius * 0.62, end_position + direction * reticle_radius * 1.14, Color(effect_color, alpha * 0.9), 1.6, true)
	draw_circle(end_position, 3.0 + (1.0 - progress) * 5.0, Color(Color.WHITE, alpha))

func _draw_cursor_gold(alpha: float, progress: float) -> void:
	var rotation := progress * TAU * 1.3
	for index in 4:
		var direction := Vector2.from_angle(rotation + index * PI * 0.5)
		var tangent := direction.orthogonal()
		var center := end_position + direction * area_radius * (0.2 + progress * 0.56)
		draw_rect(Rect2(center - Vector2.ONE * 4.0, Vector2.ONE * 8.0), Color(effect_color.lightened(0.42), alpha), true)
		draw_line(center - tangent * 13.0, center + tangent * 13.0, Color(effect_color, alpha * 0.72), 1.8, true)
	for ring_index in 3:
		var ring_radius := area_radius * fmod(progress + ring_index / 3.0, 1.0)
		draw_arc(end_position, ring_radius, rotation, rotation + PI * 1.45, 34, Color(effect_color, alpha * (1.0 - ring_radius / area_radius)), 2.0, true)

func _draw_cursor_platinum(alpha: float, progress: float) -> void:
	var compression := area_radius * lerpf(0.92, 0.22, progress)
	for index in 4:
		var direction := Vector2.from_angle(index * PI * 0.5 + PI * 0.25)
		var start := end_position + direction * compression
		var finish := end_position + direction * (compression + area_radius * 0.3)
		draw_line(start, finish, Color(effect_color.lightened(0.62), alpha), 6.0 + intensity * 2.0, true)
	draw_arc(end_position, area_radius * (0.3 + progress * 0.7), 0.0, TAU, 52, Color(effect_color, alpha * 0.82), 4.0, true)
	draw_circle(end_position, area_radius * 0.12 * alpha, Color(Color.WHITE, alpha * 0.78))

func _draw_sparks(alpha: float, progress: float, distance: float) -> void:
	for index in spark_directions.size():
		var direction := spark_directions[index]
		var stagger := 0.72 + float(index % 3) * 0.11
		var spark_end := end_position + direction * distance * progress * stagger
		var spark_start := spark_end - direction * (5.0 + intensity * 10.0) * alpha
		draw_line(spark_start, spark_end, Color(effect_color.lightened(0.28), alpha * stagger), 1.2 + intensity * 1.4, true)

func _prepare_sparks(count: int) -> void:
	spark_directions.clear()
	var phase := rng.randf_range(0.0, TAU)
	for index in count:
		var angle := phase + TAU * float(index) / float(maxi(count, 1)) + rng.randf_range(-0.11, 0.11)
		spark_directions.append(Vector2.from_angle(angle))
