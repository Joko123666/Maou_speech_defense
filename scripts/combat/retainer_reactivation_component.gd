class_name RetainerReactivationComponent
extends Node2D

signal deactivated
signal reactivated

var source_column: TowerColumn
var row_index: int = -1
var profile: RetainerReactivationProfileData
var accent_color := Color("9ddd55")
var maximum_health: float = 0.0
var current_health: float = 0.0
var passive_health_drain_per_second: float = 0.0
var attack_health_cost: float = 0.0
var reactivation_seconds: float = 0.0
var reactivation_remaining: float = 0.0
var post_reactivation_speed_multiplier: float = 1.0
var post_reactivation_speed_duration: float = 0.0
var post_reactivation_speed_remaining: float = 0.0
var active: bool = true

func setup(column: TowerColumn, row: int, data: RetainerReactivationProfileData, color: Color, modifiers: Dictionary = {}) -> void:
	source_column = column
	row_index = row
	profile = data
	accent_color = color
	z_index = 9
	apply_modifiers(modifiers, true)
	queue_redraw()

func apply_modifiers(modifiers: Dictionary, initialize: bool = false) -> void:
	if profile == null:
		return
	var previous_maximum := maximum_health
	var previous_reactivation_seconds := reactivation_seconds
	maximum_health = profile.maximum_health * float(modifiers.get("retainer_health", 1.0))
	passive_health_drain_per_second = profile.passive_health_drain_per_second * float(modifiers.get("retainer_passive_drain", 1.0))
	attack_health_cost = profile.attack_health_cost * float(modifiers.get("retainer_attack_cost", 1.0))
	var speed_multiplier := maxf(float(modifiers.get("reactivation_speed", 1.0)), 0.01)
	reactivation_seconds = profile.reactivation_seconds / speed_multiplier
	if not initialize and not active and previous_reactivation_seconds > 0.0:
		var remaining_ratio := clampf(reactivation_remaining / previous_reactivation_seconds, 0.0, 1.0)
		reactivation_remaining = reactivation_seconds * remaining_ratio
	post_reactivation_speed_multiplier = maxf(float(modifiers.get("post_reactivation_speed", 1.0)), 1.0)
	post_reactivation_speed_duration = maxf(float(modifiers.get("post_reactivation_speed_duration", 0.0)), 0.0)
	if post_reactivation_speed_remaining > 0.0:
		_set_runtime_speed(post_reactivation_speed_multiplier)
	if initialize or previous_maximum <= 0.0:
		current_health = maximum_health
	else:
		current_health = clampf(current_health * maximum_health / previous_maximum, 0.0, maximum_health)
	queue_redraw()

func can_attack() -> bool:
	return active and current_health > 0.0

func consume_attack() -> bool:
	if not can_attack():
		return false
	current_health = maxf(current_health - attack_health_cost, 0.0)
	if is_zero_approx(current_health):
		_begin_reactivation()
	queue_redraw()
	return true

func force_deactivate() -> void:
	if active:
		current_health = 0.0
		_begin_reactivation()

func get_health_ratio() -> float:
	return current_health / maximum_health if maximum_health > 0.0 else 0.0

func get_reactivation_ratio() -> float:
	return 1.0 - reactivation_remaining / reactivation_seconds if reactivation_seconds > 0.0 else 1.0

func _begin_reactivation() -> void:
	active = false
	reactivation_remaining = reactivation_seconds
	post_reactivation_speed_remaining = 0.0
	_set_runtime_speed(1.0)
	deactivated.emit()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if source_column != null and is_instance_valid(source_column) and row_index >= 0:
		var tower := source_column.get_tower_data(row_index)
		if tower == null or tower.reactivation_profile != profile:
			set_physics_process(false)
			queue_free()
			return
		global_position = source_column.get_attack_origin(row_index)
	if active:
		if post_reactivation_speed_remaining > 0.0:
			post_reactivation_speed_remaining = maxf(post_reactivation_speed_remaining - delta, 0.0)
			if is_zero_approx(post_reactivation_speed_remaining):
				_set_runtime_speed(1.0)
		current_health = maxf(current_health - passive_health_drain_per_second * delta, 0.0)
		if is_zero_approx(current_health):
			_begin_reactivation()
	else:
		reactivation_remaining = maxf(reactivation_remaining - delta, 0.0)
		if is_zero_approx(reactivation_remaining):
			active = true
			current_health = maximum_health
			post_reactivation_speed_remaining = post_reactivation_speed_duration if post_reactivation_speed_multiplier > 1.0 else 0.0
			_set_runtime_speed(post_reactivation_speed_multiplier if post_reactivation_speed_remaining > 0.0 else 1.0)
			reactivated.emit()
	queue_redraw()

func _exit_tree() -> void:
	_set_runtime_speed(1.0)

func _set_runtime_speed(multiplier: float) -> void:
	if source_column != null and is_instance_valid(source_column) and row_index >= 0:
		source_column.set_row_runtime_speed_multiplier(row_index, multiplier)

func _draw() -> void:
	if profile == null:
		return
	var bar_position := Vector2(-25.0, -42.0)
	draw_rect(Rect2(bar_position, Vector2(50.0, 5.0)), Color("1a2428", 0.88), true)
	if active:
		draw_rect(Rect2(bar_position, Vector2(50.0 * get_health_ratio(), 5.0)), Color("8df0ad"), true)
		draw_arc(Vector2.ZERO, 34.0, -PI * 0.5, -PI * 0.5 + TAU * get_health_ratio(), 24, Color(accent_color, 0.72), 2.0, true)
		if post_reactivation_speed_remaining > 0.0:
			var boost_ratio := post_reactivation_speed_remaining / maxf(post_reactivation_speed_duration, 0.01)
			draw_arc(Vector2.ZERO, 39.0, -PI * 0.5, -PI * 0.5 + TAU * boost_ratio, 28, Color("fff39a", 0.9), 2.4, true)
	else:
		var rebuild_ratio := clampf(get_reactivation_ratio(), 0.0, 1.0)
		draw_circle(Vector2.ZERO, 30.0, Color("15232a", 0.72))
		draw_arc(Vector2.ZERO, 34.0, -PI * 0.5, -PI * 0.5 + TAU * rebuild_ratio, 30, Color("a8ffcf"), 3.2, true)
		draw_line(Vector2(-14.0, -8.0), Vector2(14.0, 8.0), Color("d9f5e6", 0.82), 4.0, true)
		draw_line(Vector2(-14.0, 8.0), Vector2(14.0, -8.0), Color("d9f5e6", 0.82), 4.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(-25.0, 49.0), "재가동 %.1f" % reactivation_remaining, HORIZONTAL_ALIGNMENT_CENTER, 50.0, 10, Color("caffdf"))
