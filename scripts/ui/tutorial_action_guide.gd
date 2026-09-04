class_name TutorialActionGuide
extends Control

const GUIDE_COLOR := Color("f4cc63")
const GUIDE_FILL := Color(0.96, 0.8, 0.32, 0.1)
const GUIDE_SHADOW := Color(0.08, 0.04, 0.12, 0.72)

var control_targets: Array[Control] = []
var world_target: Node2D
var world_target_radius: float = 64.0
var action_label: String = ""
var elapsed: float = 0.0
var callout: PanelContainer
var callout_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_build_callout()
	hide()

func focus_world(target: Node2D, radius: float, label: String) -> void:
	control_targets.clear()
	world_target = target
	world_target_radius = maxf(radius, 32.0)
	_set_label(label)
	_show_guide()

func focus_controls(targets: Array[Control], label: String) -> void:
	control_targets.clear()
	for target in targets:
		if is_instance_valid(target):
			control_targets.append(target)
	world_target = null
	_set_label(label)
	_show_guide()

func clear() -> void:
	control_targets.clear()
	world_target = null
	action_label = ""
	elapsed = 0.0
	hide()
	if callout != null:
		callout.hide()
	queue_redraw()

func _show_guide() -> void:
	elapsed = 0.0
	show()
	if callout != null:
		callout.show()
	queue_redraw()

func _set_label(label: String) -> void:
	action_label = label
	if callout_label != null:
		callout_label.text = "▶ 행동 · %s" % label

func _process(delta: float) -> void:
	if not visible:
		return
	elapsed += maxf(delta, 0.0)
	_update_callout_position()
	queue_redraw()

func _draw() -> void:
	var target_rects := _target_rects()
	if target_rects.is_empty():
		if callout != null:
			callout.hide()
		return
	if callout != null:
		callout.show()
	var pulse := 0.5 if UiMotion.is_reduced() else (sin(elapsed * 5.2) + 1.0) * 0.5
	if is_instance_valid(world_target):
		_draw_world_focus(target_rects[0], pulse)
	else:
		for target_rect in target_rects:
			_draw_control_focus(target_rect, pulse)

func _target_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if is_instance_valid(world_target) and world_target.is_inside_tree():
		var center := world_target.get_global_transform_with_canvas().origin
		result.append(Rect2(center - Vector2.ONE * world_target_radius, Vector2.ONE * world_target_radius * 2.0))
		return result
	for target in control_targets:
		if is_instance_valid(target) and target.is_inside_tree() and target.is_visible_in_tree():
			result.append(target.get_global_rect())
	return result

func _draw_world_focus(target_rect: Rect2, pulse: float) -> void:
	var center := target_rect.get_center()
	var radius := target_rect.size.x * 0.5 + 7.0 + pulse * 7.0
	draw_circle(center, radius + 7.0, Color(GUIDE_SHADOW, 0.18))
	draw_circle(center, radius, Color(GUIDE_FILL, 0.06 + pulse * 0.05))
	draw_arc(center, radius, 0.0, TAU, 64, Color(GUIDE_COLOR, 0.72 + pulse * 0.26), 3.0 + pulse * 1.5, true)
	draw_arc(center, radius + 9.0, -PI * 0.25, PI * 0.25, 18, Color(GUIDE_COLOR, 0.52 + pulse * 0.3), 2.0, true)
	_draw_target_chevron(target_rect, pulse)

func _draw_control_focus(target_rect: Rect2, pulse: float) -> void:
	var expanded := target_rect.grow(7.0 + pulse * 5.0)
	draw_rect(expanded.grow(4.0), Color(GUIDE_SHADOW, 0.28), false, 7.0)
	draw_rect(expanded, Color(GUIDE_FILL, 0.08 + pulse * 0.04), true)
	draw_rect(expanded, Color(GUIDE_COLOR, 0.7 + pulse * 0.28), false, 2.5 + pulse * 1.5)
	var bracket_length := minf(24.0, minf(expanded.size.x, expanded.size.y) * 0.3)
	_draw_bracket(expanded.position, Vector2.RIGHT, Vector2.DOWN, bracket_length, pulse)
	_draw_bracket(Vector2(expanded.end.x, expanded.position.y), Vector2.LEFT, Vector2.DOWN, bracket_length, pulse)
	_draw_bracket(expanded.end, Vector2.LEFT, Vector2.UP, bracket_length, pulse)
	_draw_bracket(Vector2(expanded.position.x, expanded.end.y), Vector2.RIGHT, Vector2.UP, bracket_length, pulse)
	_draw_target_chevron(expanded, pulse)

func _draw_bracket(origin: Vector2, horizontal: Vector2, vertical: Vector2, length: float, pulse: float) -> void:
	var color := Color(GUIDE_COLOR, 0.82 + pulse * 0.18)
	draw_line(origin, origin + horizontal * length, color, 4.0, true)
	draw_line(origin, origin + vertical * length, color, 4.0, true)

func _draw_target_chevron(target_rect: Rect2, pulse: float) -> void:
	var center_x := target_rect.get_center().x
	var above := target_rect.position.y >= 34.0
	var tip_y := target_rect.position.y - 4.0 if above else target_rect.end.y + 4.0
	var direction := 1.0 if above else -1.0
	var height := 12.0 + pulse * 4.0
	var points := PackedVector2Array([
		Vector2(center_x, tip_y),
		Vector2(center_x - 10.0, tip_y - height * direction),
		Vector2(center_x + 10.0, tip_y - height * direction),
	])
	draw_colored_polygon(points, Color(GUIDE_COLOR, 0.9))

func _build_callout() -> void:
	callout = PanelContainer.new()
	callout.name = "ActionCallout"
	callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	callout.z_index = 1
	callout.add_theme_stylebox_override(
		"panel",
		UiStyleFactory.panel(Color("20162e", 0.96), GUIDE_COLOR, UiTokens.RADIUS_SMALL, 2, 10.0)
	)
	add_child(callout)
	callout_label = Label.new()
	callout_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	callout_label.add_theme_font_size_override("font_size", 16)
	callout_label.add_theme_color_override("font_color", Color("fff0b3"))
	callout.add_child(callout_label)

func _update_callout_position() -> void:
	if callout == null:
		return
	var target_rects := _target_rects()
	if target_rects.is_empty():
		callout.hide()
		return
	callout.show()
	callout.reset_size()
	var callout_size := callout.get_combined_minimum_size()
	callout.size = callout_size
	var target_rect := target_rects[0]
	var next_position := Vector2(target_rect.get_center().x - callout_size.x * 0.5, target_rect.position.y - callout_size.y - 28.0)
	if next_position.y < 10.0:
		next_position.y = target_rect.end.y + 28.0
	next_position.x = clampf(next_position.x, 10.0, maxf(size.x - callout_size.x - 10.0, 10.0))
	next_position.y = clampf(next_position.y, 10.0, maxf(size.y - callout_size.y - 10.0, 10.0))
	callout.position = next_position
