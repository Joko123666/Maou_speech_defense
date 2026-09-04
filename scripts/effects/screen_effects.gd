class_name ScreenEffects
extends Node

@onready var camera: Camera2D = $Camera2D
@onready var flash_rect: ColorRect = $FlashLayer/FlashRect

var shake_strength: float = 0.0
var shake_remaining: float = 0.0
var shake_duration: float = 0.0
var flash_remaining: float = 0.0
var flash_duration: float = 0.0
var flash_peak_alpha: float = 0.0
var flash_color: Color = Color.WHITE
var shake_request_count: int = 0
var flash_request_count: int = 0
var shake_enabled: bool = true
var flash_enabled: bool = true
var reduced_motion_enabled: bool = false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	shake_enabled = GameSession.screen_shake_enabled
	flash_enabled = GameSession.screen_flash_enabled
	reduced_motion_enabled = GameSession.reduced_motion_enabled
	rng.randomize()
	camera.enabled = true
	_sync_camera_center()
	flash_rect.color = Color.TRANSPARENT
	get_viewport().size_changed.connect(_sync_camera_center)

func shake(strength: float = 0.25, duration: float = 0.16) -> void:
	if not shake_enabled or reduced_motion_enabled:
		return
	var safe_strength := clampf(strength, 0.0, 1.0)
	shake_strength = minf(maxf(shake_strength, safe_strength) + safe_strength * 0.22, 1.0)
	shake_duration = maxf(shake_duration, maxf(duration, 0.01))
	shake_remaining = maxf(shake_remaining, duration)
	shake_request_count += 1

func flash(color: Color, alpha: float = 0.12, duration: float = 0.12) -> void:
	if not flash_enabled:
		return
	var safe_duration := maxf(duration, 0.01)
	flash_color = color
	flash_peak_alpha = maxf(flash_peak_alpha, clampf(alpha, 0.0, 0.5))
	if flash_remaining > 0.0:
		flash_duration = maxf(maxf(flash_duration, flash_remaining), safe_duration)
	else:
		flash_duration = safe_duration
	flash_remaining = maxf(flash_remaining, safe_duration)
	flash_request_count += 1

func reset_effects() -> void:
	shake_strength = 0.0
	shake_remaining = 0.0
	shake_duration = 0.0
	flash_remaining = 0.0
	flash_duration = 0.0
	flash_peak_alpha = 0.0
	camera.offset = Vector2.ZERO
	camera.rotation = 0.0
	flash_rect.color = Color.TRANSPARENT

func set_shake_enabled(enabled: bool) -> void:
	shake_enabled = enabled
	if not enabled:
		shake_strength = 0.0
		shake_remaining = 0.0
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0

func set_flash_enabled(enabled: bool) -> void:
	flash_enabled = enabled
	if not enabled:
		flash_remaining = 0.0
		flash_peak_alpha = 0.0
		flash_rect.color = Color.TRANSPARENT

func set_reduced_motion_enabled(enabled: bool) -> void:
	reduced_motion_enabled = enabled
	if enabled:
		shake_strength = 0.0
		shake_remaining = 0.0
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0

func _process(delta: float) -> void:
	_update_shake(delta)
	_update_flash(delta)

func _update_shake(delta: float) -> void:
	if shake_remaining <= 0.0:
		camera.offset = camera.offset.lerp(Vector2.ZERO, minf(delta * 28.0, 1.0))
		camera.rotation = lerpf(camera.rotation, 0.0, minf(delta * 28.0, 1.0))
		shake_strength = 0.0
		return
	shake_remaining = maxf(shake_remaining - delta, 0.0)
	var ratio := shake_remaining / maxf(shake_duration, 0.01)
	var amplitude := shake_strength * ratio * ratio
	camera.offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * 13.0 * amplitude
	camera.rotation = rng.randf_range(-1.0, 1.0) * 0.012 * amplitude

func _update_flash(delta: float) -> void:
	if flash_remaining <= 0.0:
		flash_rect.color = Color.TRANSPARENT
		flash_peak_alpha = 0.0
		return
	flash_remaining = maxf(flash_remaining - delta, 0.0)
	var ratio := clampf(flash_remaining / maxf(flash_duration, 0.01), 0.0, 1.0)
	flash_rect.color = Color(flash_color, flash_peak_alpha * ratio * ratio)

func _sync_camera_center() -> void:
	camera.position = get_viewport().get_visible_rect().size * 0.5
