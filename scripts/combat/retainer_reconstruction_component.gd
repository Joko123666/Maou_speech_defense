class_name RetainerReconstructionComponent
extends Node2D

signal reconstruction_started(duration: float)
signal reconstruction_completed

enum ActionState { READY, RECONSTRUCTING }

var source_cursor: TargetCursor
var profile: ComboAttackProfileData
var action_state: ActionState = ActionState.READY
var reconstruction_seconds: float = 0.0
var reconstruction_remaining: float = 0.0
var reconstruction_disabled: bool = false
var accent_color := Color("e6dcff")

func setup(cursor: TargetCursor, data: ComboAttackProfileData, color: Color, modifiers: Dictionary = {}) -> void:
	source_cursor = cursor
	profile = data
	accent_color = color
	z_index = 11
	apply_modifiers(modifiers)
	queue_redraw()

func apply_modifiers(modifiers: Dictionary) -> void:
	if profile == null:
		return
	var speed := maxf(float(modifiers.get("reconstruction_speed", 1.0)), 0.01)
	reconstruction_disabled = bool(modifiers.get("persistent_contract", false))
	var old_total := reconstruction_seconds
	reconstruction_seconds = profile.reconstruction_seconds * maxf(float(modifiers.get("reconstruction_duration", 1.0)), 0.01) / speed
	if reconstruction_disabled and action_state == ActionState.RECONSTRUCTING:
		action_state = ActionState.READY
		reconstruction_remaining = 0.0
	if action_state == ActionState.RECONSTRUCTING and old_total > 0.0:
		reconstruction_remaining = reconstruction_seconds * clampf(reconstruction_remaining / old_total, 0.0, 1.0)
	queue_redraw()

func can_attack() -> bool:
	return action_state == ActionState.READY

func allows_movement() -> bool:
	return true

func allows_collection() -> bool:
	return true

func begin_reconstruction() -> bool:
	if profile == null or not can_attack() or reconstruction_disabled:
		return false
	action_state = ActionState.RECONSTRUCTING
	reconstruction_remaining = reconstruction_seconds
	if source_cursor != null and is_instance_valid(source_cursor):
		source_cursor.set_presentation_state(&"reconstructing", 0.0)
	reconstruction_started.emit(reconstruction_seconds)
	queue_redraw()
	return true

func get_reconstruction_ratio() -> float:
	if action_state == ActionState.READY or reconstruction_seconds <= 0.0:
		return 1.0
	return 1.0 - reconstruction_remaining / reconstruction_seconds

func _physics_process(delta: float) -> void:
	if source_cursor != null and is_instance_valid(source_cursor):
		global_position = source_cursor.global_position
	if action_state != ActionState.RECONSTRUCTING:
		return
	reconstruction_remaining = maxf(reconstruction_remaining - maxf(delta, 0.0), 0.0)
	if source_cursor != null and is_instance_valid(source_cursor):
		source_cursor.set_presentation_state(&"reconstructing", get_reconstruction_ratio())
	if is_zero_approx(reconstruction_remaining):
		action_state = ActionState.READY
		if source_cursor != null and is_instance_valid(source_cursor):
			source_cursor.set_presentation_state(&"ready", 1.0)
		reconstruction_completed.emit()
	queue_redraw()

func _draw() -> void:
	if action_state != ActionState.RECONSTRUCTING:
		return
	var ratio := clampf(get_reconstruction_ratio(), 0.0, 1.0)
	draw_circle(Vector2.ZERO, 31.0, Color("141c25", 0.72))
	draw_arc(Vector2.ZERO, 38.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, Color(accent_color, 0.95), 4.0, true)
	var orbit_radius := (1.0 - ratio) * 18.0
	for index in 4:
		var angle := ratio * TAU * 1.4 + index * TAU / 4.0
		var offset := Vector2.from_angle(angle) * orbit_radius + Vector2(-9.0 + float(index % 2) * 18.0, -5.0 + float(index / 2) * 10.0) * ratio
		var bone_direction := Vector2.from_angle(angle + ratio * PI * 0.5)
		draw_line(offset - bone_direction * 7.0, offset + bone_direction * 7.0, Color("efe7d0", 0.9), 4.0, true)
		draw_circle(offset - bone_direction * 8.0, 3.2, Color("efe7d0", 0.9))
		draw_circle(offset + bone_direction * 8.0, 3.2, Color("efe7d0", 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(-29.0, 53.0), "재구성 %.1f" % reconstruction_remaining, HORIZONTAL_ALIGNMENT_CENTER, 58.0, 10, Color("f3edff"))
