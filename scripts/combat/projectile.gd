class_name Projectile
extends Node2D

signal impacted(target: Enemy, impact_position: Vector2, payload: Dictionary)

var direction: Vector2 = Vector2.RIGHT
var projectile_texture: Texture2D
var projectile_tint: Color = Color.WHITE
var payload: Dictionary = {}
var speed: float = 420.0
var display_length: float = 42.0
var remaining_lifetime: float = 4.0
var collision_padding: float = 7.0
var distance_travelled: float = 0.0
var maximum_distance: float = INF
var trail_points: Array[Vector2] = []
var terminal_impact_emitted: bool = false
var remaining_hits: int = 1
var hit_enemy_ids: Dictionary = {}

func setup(
		start_position: Vector2,
		aim_position: Vector2,
		texture: Texture2D,
		travel_speed: float,
		tint: Color,
		length: float,
		impact_payload: Dictionary,
		max_travel_distance: float = INF
	) -> void:
	global_position = start_position
	direction = start_position.direction_to(aim_position)
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	projectile_texture = texture
	speed = travel_speed
	projectile_tint = tint
	display_length = length
	payload = impact_payload
	remaining_hits = maxi(int(payload.get("max_hits", 1)), 1)
	hit_enemy_ids.clear()
	terminal_impact_emitted = false
	maximum_distance = max_travel_distance
	distance_travelled = 0.0
	trail_points = [global_position]
	rotation = direction.angle()
	add_to_group(&"projectiles")
	queue_redraw()

func _physics_process(delta: float) -> void:
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		_emit_terminal_impact()
		queue_free()
		return
	if payload.get("collision_mode", &"path") == &"locked":
		var locked_target := _get_locked_target()
		if locked_target != null and locked_target.active:
			direction = global_position.direction_to(locked_target.global_position)
			if direction.length_squared() > 0.001:
				rotation = direction.angle()
	var start := global_position
	var travel_distance := minf(speed * delta, maximum_distance - distance_travelled)
	if travel_distance <= 0.0:
		_emit_terminal_impact()
		queue_free()
		return
	var finish := start + direction * travel_distance
	var collision := {} if bool(payload.get("impact_at_aim", false)) else _first_collision(start, finish)
	if not collision.is_empty():
		global_position = collision.position
		distance_travelled += start.distance_to(global_position)
		var hit_enemy := collision.enemy as Enemy
		hit_enemy_ids[hit_enemy.get_instance_id()] = true
		impacted.emit(hit_enemy, global_position, payload)
		remaining_hits -= 1
		trail_points.append(global_position)
		if remaining_hits <= 0 or distance_travelled >= maximum_distance:
			queue_free()
		else:
			var pass_distance := maxf(collision_padding * 2.0, 10.0)
			global_position += direction * pass_distance
			distance_travelled += pass_distance
			queue_redraw()
		return
	global_position = finish
	distance_travelled += travel_distance
	if payload.get("behavior", &"") == &"area":
		rotation = direction.angle() + sin(distance_travelled * 0.035) * 0.16
	trail_points.append(global_position)
	while trail_points.size() > 7:
		trail_points.pop_front()
	queue_redraw()
	if distance_travelled >= maximum_distance:
		_emit_terminal_impact()
		queue_free()

func _emit_terminal_impact() -> void:
	if terminal_impact_emitted:
		return
	terminal_impact_emitted = true
	impacted.emit(null, global_position, payload)

func _first_collision(start: Vector2, finish: Vector2) -> Dictionary:
	var segment := finish - start
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.001:
		return {}
	var closest_t := INF
	var closest_enemy: Enemy
	var closest_position := finish
	var candidates: Array[Enemy] = []
	if payload.get("collision_mode", &"path") == &"locked":
		var locked_target := _get_locked_target()
		if locked_target != null and locked_target.active:
			candidates.append(locked_target)
	else:
		var spatial_index := payload.get("spatial_index") as EnemySpatialIndex
		if spatial_index != null:
			candidates = spatial_index.query_segment(start, finish, 80.0)
		else:
			for node in get_tree().get_nodes_in_group(&"enemies"):
				var enemy := node as Enemy
				if enemy != null:
					candidates.append(enemy)
	for enemy in candidates:
		if enemy == null or not enemy.active or hit_enemy_ids.has(enemy.get_instance_id()):
			continue
		var t := clampf((enemy.global_position - start).dot(segment) / segment_length_squared, 0.0, 1.0)
		var point := start + segment * t
		if point.distance_to(enemy.global_position) <= enemy.data.radius + collision_padding and t < closest_t:
			closest_t = t
			closest_enemy = enemy
			closest_position = point
	if closest_enemy == null:
		return {}
	return {"enemy": closest_enemy, "position": closest_position}

func _get_locked_target() -> Enemy:
	var value = payload.get("locked_target", null)
	if not is_instance_valid(value):
		return null
	return value as Enemy

func _draw() -> void:
	if projectile_texture == null:
		return
	for index in range(1, trail_points.size()):
		var alpha := float(index) / float(trail_points.size()) * 0.34
		var from := to_local(trail_points[index - 1])
		var to := to_local(trail_points[index])
		draw_line(from, to, Color(projectile_tint, alpha), maxf(display_length * 0.1 * float(index) / float(trail_points.size()), 1.0), true)
	var aspect := float(projectile_texture.get_height()) / maxf(projectile_texture.get_width(), 1.0)
	var draw_size := Vector2(display_length, display_length * aspect)
	var glow_color := Color(projectile_tint, 0.28)
	draw_circle(Vector2(-display_length * 0.12, 0.0), maxf(draw_size.y * 0.55, 5.0), glow_color)
	draw_line(Vector2(-display_length * 0.55, 0.0), Vector2(-display_length * 0.95, 0.0), Color(projectile_tint, 0.35), maxf(draw_size.y * 0.28, 2.0))
	draw_texture_rect(projectile_texture, Rect2(-draw_size * 0.5, draw_size), false, projectile_tint)
	_draw_behavior_accent(StringName(payload.get("behavior", &"")), draw_size)

func _draw_behavior_accent(behavior: StringName, draw_size: Vector2) -> void:
	match behavior:
		&"rapid", &"unique_single":
			var volley_index := int(payload.get("volley_index", 1))
			var offset := float(volley_index - 1) * 3.0
			draw_line(Vector2(-display_length * 0.8, -5.0 + offset), Vector2(display_length * 0.18, -5.0 + offset), Color(projectile_tint.lightened(0.5), 0.72), 1.3)
			draw_line(Vector2(-display_length * 0.8, 5.0 + offset), Vector2(display_length * 0.18, 5.0 + offset), Color(projectile_tint, 0.52), 1.3)
		&"area":
			draw_arc(Vector2.ZERO, maxf(draw_size.y * 0.62, 10.0), 0.0, TAU, 22, Color(projectile_tint, 0.68), 2.0)
			draw_circle(Vector2(-5.0, draw_size.y * 0.58), draw_size.y * 0.34, Color(0.0, 0.0, 0.0, 0.22))
		&"slow":
			for index in 6:
				var direction := Vector2.from_angle(TAU * index / 6.0)
				draw_line(direction * 3.0, direction * maxf(draw_size.y * 0.7, 10.0), Color(projectile_tint.lightened(0.4), 0.82), 1.4)
		&"knockback":
			for offset in [0.0, 8.0]:
				draw_polyline(PackedVector2Array([Vector2(-15.0 - offset, -9.0), Vector2(-5.0 - offset, 0.0), Vector2(-15.0 - offset, 9.0)]), Color(projectile_tint, 0.78), 2.0)
