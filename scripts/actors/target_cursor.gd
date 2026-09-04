class_name TargetCursor
extends Node2D

const MAX_ATTACKS_PER_FRAME := 8

signal attack_requested(target_position: Vector2, cursor_data: CursorData)
signal collection_requested(target_position: Vector2, radius: float)
signal position_changed(target_position: Vector2)

var data: CursorData
var battlefield: Battlefield
var current_sector: int = 0
var attack_accumulator: float = 0.0
var collection_accumulator: float = 0.0
var active: bool = false
var dragging: bool = false
var stat_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var area_multiplier: float = 1.0
var control_multiplier: float = 1.0
var movement_speed_multiplier: float = 1.0
var transient_speed_multiplier: float = 1.0
var transient_speed_remaining: float = 0.0
var stationary_seconds: float = 0.0
var attack_flash: float = 0.0
var move_flash: float = 0.0
var movement_input_enabled: bool = true
var movement_command_interceptor: Callable
var destination_position: Vector2
var presentation_state: StringName = &"ready"
var presentation_state_progress: float = 1.0
var combat_character_texture: Texture2D
var presentation_color: Color = Color("59d1ff")

func setup(target_battlefield: Battlefield, cursor_data: CursorData) -> void:
	battlefield = target_battlefield
	data = cursor_data
	var rect := battlefield.get_battle_rect()
	position = rect.get_center()
	destination_position = position
	current_sector = battlefield.world_to_lane(position)
	attack_accumulator = data.attack_interval
	presentation_state = &"ready"
	presentation_state_progress = 1.0
	combat_character_texture = null
	presentation_color = data.color
	var campaign := ConceptService.get_election_campaign()
	if campaign != null:
		var retainer := campaign.retainer_for_cursor(data.id)
		if retainer != null:
			combat_character_texture = ConceptService.optional_content_texture(&"retainer_sd", retainer.id)
			var candidate := campaign.candidate(retainer.preferred_candidate_id)
			var faction := campaign.faction(candidate.faction_id) if candidate != null else null
			if faction != null:
				presentation_color = faction.primary_color
				var runtime_data := cursor_data.duplicate(false) as CursorData
				if runtime_data != null:
					runtime_data.color = presentation_color
					data = runtime_data
	active = true
	set_physics_process(true)
	set_process_unhandled_input(true)
	queue_redraw()

func apply_upgrade(multiplier: float, speed_multiplier: float = 1.0, radius_multiplier: float = 1.0, knockback_multiplier: float = 1.0, movement_multiplier: float = 1.0) -> void:
	stat_multiplier = multiplier
	attack_speed_multiplier = speed_multiplier
	area_multiplier = radius_multiplier
	control_multiplier = knockback_multiplier
	movement_speed_multiplier = movement_multiplier
	queue_redraw()

func get_effective_attack_radius() -> float:
	return data.attack_radius * area_multiplier if data != null else 0.0

func get_effective_collection_radius() -> float:
	return data.collection_radius * area_multiplier if data != null else 0.0

func get_effective_knockback() -> float:
	return data.knockback * control_multiplier if data != null else 0.0

func get_effective_movement_speed() -> float:
	return data.movement_speed * movement_speed_multiplier if data != null else 0.0

func is_moving() -> bool:
	return position.distance_to(destination_position) > 1.0

func get_remaining_movement_distance() -> float:
	return position.distance_to(destination_position)

func boost_attack_speed(multiplier: float, duration: float) -> void:
	transient_speed_multiplier = maxf(transient_speed_multiplier, multiplier)
	transient_speed_remaining = maxf(transient_speed_remaining, duration)

func get_effective_attack_speed_multiplier() -> float:
	return CombatModifierResolver.resolve_attack_speed([
		attack_speed_multiplier,
		transient_speed_multiplier,
	])

func get_stationary_ratio(seconds_to_full: float = 3.0) -> float:
	return clampf(stationary_seconds / maxf(seconds_to_full, 0.01), 0.0, 1.0)

func stop() -> void:
	active = false
	dragging = false
	destination_position = position
	set_physics_process(false)
	set_process_unhandled_input(false)

func set_movement_input_enabled(enabled: bool) -> void:
	movement_input_enabled = enabled
	if not enabled:
		dragging = false
		destination_position = position

func set_movement_command_interceptor(callback: Callable) -> void:
	movement_command_interceptor = callback

func refresh_layout() -> void:
	if battlefield == null:
		return
	position = battlefield.clamp_to_battlefield(position)
	destination_position = battlefield.clamp_to_battlefield(destination_position)
	current_sector = battlefield.world_to_lane(position)
	position_changed.emit(global_position)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active or data == null:
		return
	var moved := _advance_toward_destination(delta)
	attack_accumulator += delta
	collection_accumulator += delta
	stationary_seconds = 0.0 if moved else stationary_seconds + delta
	if transient_speed_remaining > 0.0:
		transient_speed_remaining = maxf(transient_speed_remaining - delta, 0.0)
		if is_zero_approx(transient_speed_remaining):
			transient_speed_multiplier = 1.0
	attack_flash = maxf(attack_flash - delta * 3.8, 0.0)
	move_flash = maxf(move_flash - delta * 5.0, 0.0)
	var effective_interval := data.attack_interval / get_effective_attack_speed_multiplier()
	var attacks_this_frame := 0
	while attack_accumulator >= effective_interval and attacks_this_frame < MAX_ATTACKS_PER_FRAME:
		attack_accumulator -= effective_interval
		attack_flash = 1.0
		attack_requested.emit(global_position, data)
		attacks_this_frame += 1
	if attacks_this_frame >= MAX_ATTACKS_PER_FRAME:
		attack_accumulator = minf(attack_accumulator, effective_interval)
	if collection_accumulator >= 0.1:
		collection_accumulator -= 0.1
		collection_requested.emit(global_position, get_effective_collection_radius())
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active or battlefield == null or not movement_input_enabled:
		return
	if event is InputEventScreenTouch:
		dragging = event.pressed
		if event.pressed:
			_move_to(_screen_to_world(event.position))
	elif event is InputEventScreenDrag:
		_move_to(_screen_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if event.pressed:
			_move_to(_screen_to_world(event.position))
	elif event is InputEventMouseMotion and dragging:
		_move_to(_screen_to_world(event.position))

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func _move_to(world_position: Vector2) -> void:
	set_destination(world_position)

func set_destination(world_position: Vector2) -> void:
	var clamped_position := battlefield.clamp_to_battlefield(world_position)
	if movement_command_interceptor.is_valid() and bool(movement_command_interceptor.call(clamped_position)):
		return
	if position.distance_to(clamped_position) > 1.0:
		stationary_seconds = 0.0
	destination_position = clamped_position
	move_flash = 1.0
	queue_redraw()

func set_presentation_state(state: StringName, progress: float = 1.0) -> void:
	presentation_state = state
	presentation_state_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()

func warp_to(world_position: Vector2) -> void:
	position = battlefield.clamp_to_battlefield(world_position)
	destination_position = position
	current_sector = battlefield.world_to_lane(position)
	stationary_seconds = 0.0
	move_flash = 1.0
	position_changed.emit(global_position)
	queue_redraw()

func _advance_toward_destination(delta: float) -> bool:
	var remaining := position.distance_to(destination_position)
	if remaining <= 1.0:
		if remaining > 0.0:
			position = destination_position
		return false
	var step := get_effective_movement_speed() * maxf(delta, 0.0)
	if step <= 0.0:
		return false
	position = position.move_toward(destination_position, step)
	current_sector = battlefield.world_to_lane(position)
	move_flash = 1.0
	position_changed.emit(global_position)
	return true

func _draw() -> void:
	var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.008)
	var base_color := presentation_color if data != null else Color("59d1ff")
	var cursor_color := Color(base_color, pulse)
	var effect_radius := get_effective_attack_radius() if data != null else 72.0
	var radius := clampf(effect_radius * 0.38, 28.0, 54.0)
	_draw_destination_command(base_color, radius, pulse)
	var effective_interval := data.attack_interval / get_effective_attack_speed_multiplier() if data != null else 1.0
	var cooldown_ratio := clampf(attack_accumulator / maxf(effective_interval, 0.01), 0.0, 1.0) if data != null else 1.0
	draw_circle(Vector2.ZERO, effect_radius, Color(base_color, 0.035 + move_flash * 0.025))
	draw_arc(Vector2.ZERO, effect_radius, 0.0, TAU, 64, Color(base_color, 0.32 + move_flash * 0.28), 1.5 + move_flash)
	for marker_index in 4:
		var marker_direction := Vector2.from_angle(marker_index * PI * 0.5)
		draw_line(marker_direction * (effect_radius - 8.0), marker_direction * (effect_radius + 3.0), Color(base_color, 0.55), 2.0)
	draw_circle(Vector2.ZERO, radius + 5.0 + attack_flash * 18.0, Color(base_color, 0.12 + attack_flash * 0.18))
	if data != null and data.texture != null:
		var movement_direction := destination_position - position
		var moving_amount := 1.0 if movement_direction.length_squared() > 1.0 else 0.0
		var pose := RetainerMotionProfile.pose(data.id, moving_amount, movement_direction, attack_flash, presentation_state, presentation_state_progress, Time.get_ticks_msec() * 0.0022)
		var art_size := Vector2.ONE * radius * 2.25
		var art_tint := Color.WHITE.lerp(base_color.lightened(0.35), attack_flash * 0.2)
		art_tint.a = float(pose.alpha)
		draw_set_transform(pose.offset, float(pose.rotation), pose.scale)
		if combat_character_texture != null:
			var character_size := Vector2.ONE * radius * 2.55
			draw_texture_rect(combat_character_texture, Rect2(-character_size * 0.5, character_size), false, art_tint)
		else:
			draw_texture_rect(data.texture, Rect2(-art_size * 0.5, art_size), false, art_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(Vector2.ZERO, radius * 0.72, Color(base_color, 0.72))
	_draw_identity_accents(radius, base_color, pulse)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, cursor_color, 2.2)
	draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 48, Color(0.08, 0.14, 0.18, 0.9), 6.0)
	if cooldown_ratio > 0.01:
		draw_arc(Vector2.ZERO, radius + 10.0, -PI * 0.5, -PI * 0.5 + TAU * cooldown_ratio, 48, Color(base_color, 0.95), 6.0)
	if attack_flash > 0.0:
		var flash_radius := radius + (1.0 - attack_flash) * 44.0
		draw_arc(Vector2.ZERO, flash_radius, 0.0, TAU, 40, Color(base_color, attack_flash), 4.0)
		for angle_index in 8:
			var angle := TAU * angle_index / 8.0
			var direction := Vector2.from_angle(angle)
			draw_line(direction * (radius + 6.0), direction * (radius + 20.0 + attack_flash * 18.0), Color(base_color, attack_flash), 3.0)
	draw_line(Vector2(-radius - 11.0, 0.0), Vector2(-radius + 6.0, 0.0), cursor_color, 3.0)
	draw_line(Vector2(radius - 6.0, 0.0), Vector2(radius + 11.0, 0.0), cursor_color, 3.0)

func _draw_destination_command(base_color: Color, radius: float, pulse: float) -> void:
	var destination_local := destination_position - global_position
	var distance := destination_local.length()
	if distance <= 10.0:
		return
	var direction := destination_local / distance
	var dash_start := radius + 15.0
	var dash_end := maxf(distance - 22.0, dash_start)
	var cursor := dash_start
	while cursor < dash_end:
		var segment_end := minf(cursor + 12.0, dash_end)
		draw_line(direction * cursor, direction * segment_end, Color(base_color, 0.24), 2.0, true)
		cursor += 21.0
	draw_circle(destination_local, 17.0 + pulse * 2.0, Color(base_color, 0.08))
	draw_arc(destination_local, 15.0 + pulse * 2.0, 0.0, TAU, 24, Color(base_color, 0.65), 2.0, true)
	for index in 4:
		var marker_direction := Vector2.from_angle(index * PI * 0.5)
		draw_line(destination_local + marker_direction * 12.0, destination_local + marker_direction * 21.0, Color(base_color, 0.72), 2.0, true)

func _draw_identity_accents(radius: float, base_color: Color, pulse: float) -> void:
	if data == null:
		return
	var time := Time.get_ticks_msec() * 0.001
	match data.id:
		&"iron":
			for index in 4:
				var direction := Vector2.from_angle(index * PI * 0.5)
				draw_line(direction * radius * 0.72, direction * radius * (1.0 + attack_flash * 0.34), Color(base_color.lightened(0.45), pulse), 4.0 + attack_flash * 2.0, true)
		&"silver":
			for index in 3:
				var start := time * 2.8 + index * TAU / 3.0
				draw_arc(Vector2.ZERO, radius * 0.7, start, start + 0.72, 10, Color(base_color.lightened(0.5), pulse), 2.2, true)
		&"gold":
			for index in 4:
				var angle := -time * 1.7 + index * PI * 0.5
				var cell_position := Vector2.from_angle(angle) * radius * 0.78
				draw_rect(Rect2(cell_position - Vector2.ONE * 3.0, Vector2.ONE * 6.0), Color(base_color.lightened(0.35), pulse), true)
		&"platinum":
			var charge := get_stationary_ratio()
			for index in 4:
				var direction := Vector2.from_angle(index * PI * 0.5 + PI * 0.25)
				draw_line(direction * radius * (0.92 - charge * 0.18), direction * radius * 1.08, Color(base_color.lightened(0.55), 0.45 + charge * 0.55), 3.0 + charge * 2.0, true)
			draw_arc(Vector2.ZERO, radius * 0.58, -PI * 0.5, -PI * 0.5 + TAU * charge, 32, Color("e6dcff", 0.88), 3.0, true)
		&"vanguard":
			for index in 3:
				var formation_offset := Vector2(-12.0 + index * 12.0, -5.0 + absf(1.0 - index) * 7.0)
				var spear_direction := Vector2(0.72, -0.7).rotated(sin(time * 3.0 + index) * 0.08)
				draw_line(formation_offset - spear_direction * 7.0, formation_offset + spear_direction * (10.0 + attack_flash * 8.0), Color(base_color.lightened(0.45), pulse), 2.4, true)
			draw_arc(Vector2.ZERO, radius * 0.62, PI * 0.1, PI * 0.9, 18, Color("ffd0d3", 0.55 + attack_flash * 0.4), 3.0, true)
