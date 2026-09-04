class_name ReaperSummon
extends Node2D

const VISUAL_TEXTURE_PATH := "res://assets/graphics/effects/reaper_summon_v019.png"
const REAPER_TEXTURE: Texture2D = preload("res://assets/graphics/effects/reaper_summon_v019.png")
const DISPLAY_SIZE := Vector2(230.0, 230.0)

var cast_remaining: float = 0.0
var cast_total: float = 0.0
var strike_remaining: float = 0.0
var origin_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var battle_rect: Rect2
var tint: Color = Color("d94bff")
var casting: bool = false

func setup(origin: Vector2, target: Vector2, bounds: Rect2, color: Color, duration: float) -> void:
	origin_position = origin
	target_position = target
	battle_rect = bounds
	tint = color.lightened(0.18)
	cast_total = maxf(duration, 0.05)
	cast_remaining = cast_total
	strike_remaining = 0.0
	casting = true
	global_position = _bounded_manifest_position(target)
	z_index = 11
	queue_redraw()

func strike(target: Vector2) -> void:
	target_position = target
	global_position = _bounded_manifest_position(target)
	casting = false
	cast_remaining = 0.0
	strike_remaining = 0.72
	queue_redraw()

func is_casting() -> bool:
	return casting and cast_remaining > 0.0

func _physics_process(delta: float) -> void:
	if casting:
		cast_remaining = maxf(cast_remaining - delta, 0.0)
		if is_zero_approx(cast_remaining):
			casting = false
			strike_remaining = maxf(strike_remaining, 0.36)
	elif strike_remaining > 0.0:
		strike_remaining = maxf(strike_remaining - delta, 0.0)
		if is_zero_approx(strike_remaining):
			queue_free()
	queue_redraw()

func _bounded_manifest_position(target: Vector2) -> Vector2:
	if battle_rect.size.x <= 0.0 or battle_rect.size.y <= 0.0:
		return target
	return Vector2(
		clampf(target.x, battle_rect.position.x + 74.0, battle_rect.end.x - 74.0),
		clampf(target.y, battle_rect.position.y + 92.0, battle_rect.end.y - 68.0)
	)

func _draw() -> void:
	var phase := Time.get_ticks_msec() * 0.004
	var cast_ratio := cast_remaining / maxf(cast_total, 0.01) if casting else 0.0
	var strike_ratio := strike_remaining / 0.72 if strike_remaining > 0.0 else 0.0
	var float_offset := Vector2(0.0, sin(phase) * 5.0)
	var aura_radius := 52.0 + (1.0 - cast_ratio) * 22.0 + strike_ratio * 34.0
	draw_circle(float_offset + Vector2(0.0, 24.0), aura_radius, Color(tint, 0.10 + strike_ratio * 0.14))
	draw_arc(float_offset + Vector2(0.0, 24.0), aura_radius, phase, phase + PI * 1.55, 40, Color(tint.lightened(0.25), 0.55), 3.0)
	var manifestation_scale := 0.92 + (1.0 - cast_ratio) * 0.08 + strike_ratio * 0.05
	var display_size := DISPLAY_SIZE * manifestation_scale
	var display_alpha := clampf(0.74 + (1.0 - cast_ratio) * 0.24 + strike_ratio * 0.10, 0.0, 1.0)
	draw_texture_rect(
		REAPER_TEXTURE,
		Rect2(float_offset - display_size * 0.5, display_size),
		false,
		Color(1.0, 1.0, 1.0, display_alpha)
	)
	if strike_remaining > 0.0:
		var sweep_radius := 88.0 + (1.0 - strike_ratio) * 160.0
		draw_arc(Vector2.ZERO, sweep_radius, -1.15, 0.62, 42, Color(tint.lightened(0.52), strike_ratio), 12.0, true)
		draw_arc(Vector2.ZERO, sweep_radius + 18.0, -1.05, 0.52, 42, Color(Color.WHITE, strike_ratio * 0.62), 4.0, true)
