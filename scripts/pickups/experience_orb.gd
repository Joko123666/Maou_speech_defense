class_name ExperienceOrb
extends Node2D

var value: float = 1.0
var source_values: Dictionary = {}
var source_channel: StringName = &"base"
var spawn_origin := Vector2.ZERO
var spawn_sequence := 0
var age: float = 0.0
var merge_check: float = 0.0
var attracting: bool = false
var attraction_target := Vector2.ZERO
var attraction_velocity := Vector2.ZERO
var attraction_strength: float = 0.0
var trail_points: Array[Vector2] = []
var launch_velocity := Vector2.ZERO
var launch_remaining: float = 0.0
var launch_bounds := Rect2()

func setup(spawn_position: Vector2, experience_value: float, initial_velocity: Vector2 = Vector2.ZERO, launch_duration: float = 0.0, movement_bounds: Rect2 = Rect2(), source_channel: StringName = &"base", stable_spawn_sequence: int = 0) -> void:
	position = spawn_position
	spawn_origin = spawn_position
	value = experience_value
	self.source_channel = source_channel
	spawn_sequence = stable_spawn_sequence
	source_values = {String(source_channel): maxf(experience_value, 0.0)}
	launch_velocity = initial_velocity
	launch_remaining = maxf(launch_duration, 0.0)
	launch_bounds = movement_bounds
	add_to_group(&"experience_orbs")
	queue_redraw()

func attract_and_collect(target: Vector2, radius: float, _delta: float) -> bool:
	if launch_remaining > 0.0:
		return false
	var distance := global_position.distance_to(target)
	if not attracting and distance > radius:
		return false
	attracting = true
	attraction_target = target
	attraction_strength = maxf(attraction_strength, 0.35)
	return distance <= 12.0

func _physics_process(delta: float) -> void:
	age += delta
	merge_check += delta
	if launch_remaining > 0.0:
		_update_launch(delta)
	elif attracting:
		_update_attraction(delta)
	elif age >= 5.0 and merge_check >= 1.0:
		merge_check -= 1.0
		_try_merge()
	queue_redraw()

func _update_launch(delta: float) -> void:
	launch_remaining = maxf(launch_remaining - delta, 0.0)
	global_position += launch_velocity * delta
	launch_velocity *= exp(-2.4 * delta)
	if launch_bounds.has_area():
		var clamped_position := Vector2(
			clampf(global_position.x, launch_bounds.position.x, launch_bounds.end.x),
			clampf(global_position.y, launch_bounds.position.y, launch_bounds.end.y)
		)
		if not is_equal_approx(clamped_position.x, global_position.x):
			launch_velocity.x *= -0.42
		if not is_equal_approx(clamped_position.y, global_position.y):
			launch_velocity.y *= -0.42
		global_position = clamped_position
	trail_points.push_front(global_position)
	if trail_points.size() > 7:
		trail_points.resize(7)

func _update_attraction(delta: float) -> void:
	var to_target := attraction_target - global_position
	var distance := to_target.length()
	if distance <= 0.01:
		return
	attraction_strength = minf(attraction_strength + delta * 2.8, 1.0)
	var direction := to_target / distance
	var curve_direction := direction.orthogonal() * sin(age * 11.0 + spawn_sequence % 17) * minf(distance / 180.0, 1.0) * 0.16
	var desired_direction := (direction + curve_direction).normalized()
	var desired_speed := clampf(190.0 + distance * 5.5, 190.0, 980.0) * lerpf(0.55, 1.0, attraction_strength)
	var response := 1.0 - exp(-10.0 * delta)
	attraction_velocity = attraction_velocity.lerp(desired_direction * desired_speed, response)
	var travel := attraction_velocity.length() * delta
	if travel >= distance:
		global_position = attraction_target
	else:
		global_position += attraction_velocity * delta
	trail_points.push_front(global_position)
	if trail_points.size() > 7:
		trail_points.resize(7)

func _try_merge() -> void:
	for node in get_tree().get_nodes_in_group(&"experience_orbs"):
		var other := node as ExperienceOrb
		if other == null or other == self or other.spawn_sequence < spawn_sequence or (other.spawn_sequence == spawn_sequence and other.get_instance_id() < get_instance_id()):
			continue
		if other.source_channel != source_channel:
			continue
		if global_position.distance_to(other.global_position) <= 34.0:
			value += other.value
			if other.spawn_origin.x < spawn_origin.x or (is_equal_approx(other.spawn_origin.x, spawn_origin.x) and other.spawn_origin.y < spawn_origin.y):
				spawn_origin = other.spawn_origin
			for channel in other.source_values:
				source_values[channel] = float(source_values.get(channel, 0.0)) + float(other.source_values[channel])
			other.queue_free()
			queue_redraw()
			return

func _draw() -> void:
	var radius := 7.0 + minf(value * 0.12, 8.0)
	var pulse := 0.8 + sin(Time.get_ticks_msec() * 0.01 + get_instance_id() % 10) * 0.15
	if (attracting or launch_remaining > 0.0) and trail_points.size() >= 2:
		for index in range(1, trail_points.size()):
			var from := trail_points[index - 1] - global_position
			var to := trail_points[index] - global_position
			var trail_alpha := (1.0 - float(index) / float(trail_points.size())) * 0.42
			draw_line(from, to, Color(0.43, 1.0, 0.7, trail_alpha), maxf(1.0, radius * (1.0 - float(index) / float(trail_points.size())) * 0.7), true)
		if attracting:
			var target_direction := global_position.direction_to(attraction_target)
			draw_line(Vector2.ZERO, target_direction * (radius + 8.0), Color(0.7, 1.0, 0.82, 0.48), 1.5, true)
	draw_circle(Vector2.ZERO, radius + 4.0, Color(0.3, 0.95, 0.65, 0.18))
	var suction_scale := 0.82 + attraction_strength * 0.18 if attracting else 1.0
	draw_circle(Vector2.ZERO, radius * pulse * suction_scale, Color("6df0a5"))
	if attracting:
		draw_arc(Vector2.ZERO, radius + 6.0, age * 5.0, age * 5.0 + PI * 1.35, 18, Color(0.72, 1.0, 0.84, 0.72), 1.8, true)
