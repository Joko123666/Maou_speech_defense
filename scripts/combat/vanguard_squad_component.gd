class_name VanguardSquadComponent
extends Node2D

const MEMBER_TOKEN_PATH := "res://assets/graphics/effects/death_vanguard_member_token_v019.png"
const MEMBER_TOKEN: Texture2D = preload("res://assets/graphics/effects/death_vanguard_member_token_v019.png")
const MEMBER_TOKEN_SIZE := Vector2(22.0, 22.0)

signal member_spent(current: int, maximum: int)
signal reinforcement_arrived(current: int, maximum: int)
signal sacrifice_triggered(members: int)

var source_cursor: TargetCursor
var profile: VanguardStackProfileData
var maximum_members: int = 0
var minimum_members: int = 1
var current_members: int = 0
var damage_per_member: float = 0.0
var execution_health_ratio: float = 0.0
var reinforcement_seconds: float = 0.0
var reinforcement_remaining: float = 0.0
var accent_color := Color("e35762")
var member_spent_pulse: float = 0.0
var reinforcement_pulse: float = 0.0
var loss_penalty: float = 1.0
var sacrifice_interval: float = 0.0
var sacrifice_remaining: float = 0.0
var reaper_circle_enabled: bool = false

func setup(cursor: TargetCursor, data: VanguardStackProfileData, color: Color, modifiers: Dictionary = {}) -> void:
	source_cursor = cursor
	profile = data
	accent_color = color
	z_index = 11
	apply_modifiers(modifiers, true)
	queue_redraw()

func apply_modifiers(modifiers: Dictionary, initialize: bool = false) -> void:
	if profile == null:
		return
	var previous_maximum := maximum_members
	maximum_members = maxi(profile.maximum_members + int(modifiers.get("vanguard_member_bonus", 0)), 1)
	minimum_members = clampi(profile.minimum_members, 1, maximum_members)
	damage_per_member = profile.damage_per_member * float(modifiers.get("vanguard_member_damage", 1.0))
	loss_penalty = clampf(float(modifiers.get("vanguard_loss_penalty", 1.0)), 0.0, 1.0)
	sacrifice_interval = maxf(float(modifiers.get("vanguard_sacrifice_interval", 0.0)), 0.0)
	if sacrifice_interval > 0.0 and sacrifice_remaining <= 0.0:
		sacrifice_remaining = sacrifice_interval
	reaper_circle_enabled = bool(modifiers.get("vanguard_reaper_circle", false))
	execution_health_ratio = clampf(profile.execution_health_ratio + float(modifiers.get("vanguard_execute_bonus", 0.0)), 0.0, 0.95)
	var reinforcement_speed := maxf(float(modifiers.get("reinforcement_speed", 1.0)), 0.01)
	var previous_reinforcement_seconds := reinforcement_seconds
	reinforcement_seconds = profile.reinforcement_seconds / reinforcement_speed
	if initialize or previous_maximum <= 0:
		current_members = maximum_members
	else:
		current_members = clampi(current_members + maximum_members - previous_maximum, minimum_members, maximum_members)
	if reinforcement_remaining > 0.0 and previous_reinforcement_seconds > 0.0:
		reinforcement_remaining = reinforcement_seconds * clampf(reinforcement_remaining / previous_reinforcement_seconds, 0.0, 1.0)
	queue_redraw()

func get_damage_multiplier() -> float:
	var full_strength := float(maximum_members) * damage_per_member
	var loss_ratio := float(maximum_members - current_members) / float(maxi(maximum_members, 1))
	return maxf(full_strength * (1.0 - loss_ratio * loss_penalty), 0.0)

func consume_for_reaper() -> int:
	if not reaper_circle_enabled or current_members <= 0:
		return 0
	var snapshot := current_members
	current_members = 0
	reinforcement_remaining = reinforcement_seconds
	member_spent.emit(current_members, maximum_members)
	queue_redraw()
	return snapshot

func record_execution() -> bool:
	if current_members <= minimum_members:
		return false
	current_members -= 1
	reinforcement_remaining = reinforcement_seconds
	member_spent_pulse = 1.0
	member_spent.emit(current_members, maximum_members)
	queue_redraw()
	return true

func get_reinforcement_ratio() -> float:
	if current_members >= maximum_members or reinforcement_seconds <= 0.0:
		return 1.0
	return 1.0 - reinforcement_remaining / reinforcement_seconds

func _physics_process(delta: float) -> void:
	if source_cursor != null and is_instance_valid(source_cursor):
		global_position = source_cursor.global_position
	member_spent_pulse = maxf(member_spent_pulse - maxf(delta, 0.0) * 3.4, 0.0)
	reinforcement_pulse = maxf(reinforcement_pulse - maxf(delta, 0.0) * 2.8, 0.0)
	if sacrifice_interval > 0.0 and current_members > 0:
		sacrifice_remaining = maxf(sacrifice_remaining - maxf(delta, 0.0), 0.0)
		if is_zero_approx(sacrifice_remaining):
			current_members -= 1
			reinforcement_remaining = reinforcement_seconds
			sacrifice_remaining = sacrifice_interval
			member_spent.emit(current_members, maximum_members)
			sacrifice_triggered.emit(1)
	if current_members >= maximum_members:
		reinforcement_remaining = 0.0
		return
	if reinforcement_remaining <= 0.0:
		reinforcement_remaining = reinforcement_seconds
	reinforcement_remaining = maxf(reinforcement_remaining - maxf(delta, 0.0), 0.0)
	if is_zero_approx(reinforcement_remaining):
		current_members = mini(current_members + 1, maximum_members)
		reinforcement_pulse = 1.0
		reinforcement_arrived.emit(current_members, maximum_members)
		if current_members < maximum_members:
			reinforcement_remaining = reinforcement_seconds
	queue_redraw()

func _draw() -> void:
	if profile == null:
		return
	var spacing := 18.0
	var width := float(maximum_members - 1) * spacing
	var time := Time.get_ticks_msec() * 0.004
	for index in maximum_members:
		var march := sin(time + float(index) * 1.4) * 1.8
		var center := Vector2(float(index) * spacing - width * 0.5, -45.0 + march)
		var filled := index < current_members
		var member_scale := 1.0 + (reinforcement_pulse * 0.30 if index == current_members - 1 else 0.0)
		var ring_color := Color(accent_color, 0.82) if filled else Color(accent_color, 0.18)
		var texture_modulate := Color.WHITE if filled else Color(0.32, 0.34, 0.40, 0.24)
		draw_circle(center, 9.0 * member_scale, Color(0.025, 0.035, 0.055, 0.78 if filled else 0.34))
		draw_arc(center, 9.0 * member_scale, 0.0, TAU, 20, ring_color, 1.4, true)
		var token_size := MEMBER_TOKEN_SIZE * member_scale
		draw_texture_rect(MEMBER_TOKEN, Rect2(center - token_size * 0.5, token_size), false, texture_modulate)
	draw_string(ThemeDB.fallback_font, Vector2(-30.0, -59.0), "부대 %d/%d" % [current_members, maximum_members], HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color("ffd6d8"))
	if current_members < maximum_members:
		var ratio := clampf(get_reinforcement_ratio(), 0.0, 1.0)
		draw_arc(Vector2.ZERO, 37.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 28, Color("ff9b9f"), 3.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(-28.0, 51.0), "충원 %.1f" % reinforcement_remaining, HORIZONTAL_ALIGNMENT_CENTER, 56.0, 10, Color("ffd6d8"))
	if member_spent_pulse > 0.0:
		draw_arc(Vector2.ZERO, 32.0 + (1.0 - member_spent_pulse) * 22.0, -PI * 0.7, PI * 0.7, 28, Color(accent_color, member_spent_pulse * 0.75), 3.0, true)
	if reinforcement_pulse > 0.0:
		draw_arc(Vector2.ZERO, 48.0 - reinforcement_pulse * 18.0, 0.0, TAU, 32, Color("ffd0d3", reinforcement_pulse * 0.8), 3.0, true)
