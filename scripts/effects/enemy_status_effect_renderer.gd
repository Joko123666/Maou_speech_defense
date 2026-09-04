class_name EnemyStatusEffectRenderer
extends RefCounted

## 적 본체 위에 직접 그리는 경량 상태 시각 언어다.
## 하나의 아틀라스로 상태 정체성을 통일하고, 방향·파동은 절차형 선으로 보강한다.

const SUPPORTED_STATUS_IDS: Array[StringName] = [
	&"poison",
	&"bleed",
	&"shock",
	&"burn",
	&"slow",
	&"fear",
	&"charm",
	&"stun",
	&"freeze",
	&"mark",
	&"sentence",
	&"pierce_mark",
	&"frost_stack",
	&"haste",
	&"fortify",
]
const COMMON_AILMENT_IDS: Array[StringName] = [&"poison", &"bleed", &"shock", &"burn"]
const TRANSIENT_EFFECT_IDS: Array[StringName] = [&"knockback"]
const BACKPLATE_COLOR := Color(0.025, 0.04, 0.065, 0.78)
const LIGHT_INK := Color(0.96, 0.98, 1.0, 0.94)
const STATUS_ICON_ATLAS: Texture2D = preload("res://assets/graphics/effects/status_effect_icon_atlas_v019.png")
const ICON_GRID_SIZE := Vector2i(4, 4)
const ICON_CELLS := {
	&"poison": Vector2i(0, 0),
	&"bleed": Vector2i(1, 0),
	&"shock": Vector2i(2, 0),
	&"burn": Vector2i(3, 0),
	&"slow": Vector2i(0, 1),
	&"fear": Vector2i(1, 1),
	&"charm": Vector2i(2, 1),
	&"stun": Vector2i(3, 1),
	&"freeze": Vector2i(0, 2),
	&"mark": Vector2i(1, 2),
	&"sentence": Vector2i(2, 2),
	&"pierce_mark": Vector2i(3, 2),
	&"frost_stack": Vector2i(0, 3),
	&"haste": Vector2i(1, 3),
	&"fortify": Vector2i(2, 3),
	&"knockback": Vector2i(3, 3),
}

static func supports(status_id: StringName) -> bool:
	return status_id in SUPPORTED_STATUS_IDS or status_id in TRANSIENT_EFFECT_IDS

static func icon_cell_for(status_id: StringName) -> Vector2i:
	return ICON_CELLS.get(status_id, Vector2i(-1, -1))

static func active_visual_ids(statuses: Dictionary, common_ailments: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for status_id in SUPPORTED_STATUS_IDS:
		if statuses.has(status_id) or common_ailments.has(status_id):
			result.append(status_id)
	return result

static func visual_family_for(status_id: StringName) -> StringName:
	match status_id:
		&"poison": return &"bubble_cluster"
		&"bleed": return &"blood_drop"
		&"shock": return &"lightning_bolt"
		&"burn": return &"split_flame"
		&"slow": return &"drag_ripples"
		&"fear": return &"shivering_eye"
		&"charm": return &"heart_sigil"
		&"stun": return &"yellow_impact_star"
		&"freeze": return &"six_spoke_snowflake"
		&"mark": return &"corner_reticle"
		&"sentence": return &"judgment_diamonds"
		&"pierce_mark": return &"split_armor"
		&"frost_stack": return &"ice_notches"
		&"haste": return &"double_chevron"
		&"fortify": return &"shield_brackets"
		&"knockback": return &"directional_compression"
	return &""

static func color_for(status_id: StringName) -> Color:
	match status_id:
		&"poison": return Color("86d85b")
		&"bleed": return Color("c9364f")
		&"shock": return Color("f4dc63")
		&"burn": return Color("ff8547")
		&"slow": return Color("5ca9f4")
		&"fear": return Color("735b9f")
		&"charm": return Color("f06cbd")
		&"stun": return Color("ffd85a")
		&"freeze", &"frost_stack": return Color("91e9ff")
		&"mark": return Color("d781ff")
		&"sentence": return Color("e8455f")
		&"pierce_mark": return Color("f2d18a")
		&"haste": return Color("65d89a")
		&"fortify": return Color("86a9dc")
		&"knockback": return Color("ffe2a0")
	return Color.WHITE

static func draw_persistent(
		canvas: CanvasItem,
		radius: float,
		statuses: Dictionary,
		common_ailments: Dictionary,
		visual_flashes: Dictionary,
		phase: float
	) -> void:
	if statuses.has(&"slow"):
		_draw_slow(canvas, radius, _flash(visual_flashes, &"slow"))
	if statuses.has(&"fortify"):
		_draw_fortify(canvas, radius, _flash(visual_flashes, &"fortify"))
	if statuses.has(&"haste"):
		_draw_haste(canvas, radius, _flash(visual_flashes, &"haste"))
	if statuses.has(&"mark"):
		_draw_mark(canvas, radius, _flash(visual_flashes, &"mark"), phase)
	if statuses.has(&"pierce_mark"):
		_draw_pierce_mark(canvas, radius, _flash(visual_flashes, &"pierce_mark"))
	if statuses.has(&"frost_stack"):
		_draw_frost_stack(canvas, radius, int(statuses[&"frost_stack"].get("power", 1)), _flash(visual_flashes, &"frost_stack"))
	if statuses.has(&"sentence"):
		_draw_sentence(canvas, radius, int(statuses[&"sentence"].get("power", 1)), _flash(visual_flashes, &"sentence"))

	var control_ids: Array[StringName] = []
	for control_id in [&"stun", &"freeze", &"fear", &"charm"]:
		if statuses.has(control_id):
			control_ids.append(control_id)
	for index in control_ids.size():
		var x_offset := (float(index) - float(control_ids.size() - 1) * 0.5) * 18.0
		_draw_control_glyph(canvas, control_ids[index], Vector2(x_offset, -radius - 24.0), radius, _flash(visual_flashes, control_ids[index]))

	var ailment_ids: Array[StringName] = []
	for ailment_id in COMMON_AILMENT_IDS:
		if statuses.has(ailment_id) or common_ailments.has(ailment_id):
			ailment_ids.append(ailment_id)
	var spacing := minf(15.0, maxf(radius * 0.58, 11.0))
	for index in ailment_ids.size():
		var ailment_id := ailment_ids[index]
		var center := Vector2((float(index) - float(ailment_ids.size() - 1) * 0.5) * spacing, radius + 12.0)
		_draw_ailment_glyph(
			canvas,
			ailment_id,
			center,
			_stack_count(ailment_id, common_ailments),
			_flash(visual_flashes, ailment_id)
		)

static func draw_knockback(canvas: CanvasItem, radius: float, direction: Vector2, flash: float, displacement: float) -> void:
	if flash <= 0.0:
		return
	var forward := direction.normalized()
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	var tangent := forward.orthogonal()
	var color := color_for(&"knockback")
	var reach := clampf(12.0 + displacement * 0.22, 15.0, 34.0)
	for streak_index in 3:
		var lateral := (float(streak_index) - 1.0) * radius * 0.46
		var finish := -forward * (radius * 0.76) + tangent * lateral
		var start := finish - forward * reach * (0.72 + streak_index * 0.12)
		canvas.draw_line(start, finish, Color(color, flash * (0.64 - streak_index * 0.1)), 1.5 + flash, true)
	var compression_center := forward * (radius + 5.0)
	var half_height := radius * 0.52
	canvas.draw_polyline(PackedVector2Array([
		compression_center - tangent * half_height - forward * 5.0,
		compression_center + forward * 2.5,
		compression_center + tangent * half_height - forward * 5.0,
	]), Color(color, flash * 0.86), 2.0 + flash, true)
	_draw_status_icon(canvas, &"knockback", compression_center + forward * 7.0, 12.0 + flash * 2.0, flash)

static func _draw_ailment_glyph(canvas: CanvasItem, status_id: StringName, center: Vector2, stacks: int, flash: float) -> void:
	var scale := 1.0 + flash * 0.16
	var size := 6.0 * scale
	var color := color_for(status_id)
	canvas.draw_circle(center, size + 2.0, Color(BACKPLATE_COLOR, 0.72 + flash * 0.12))
	canvas.draw_arc(center, size + 2.0, 0.0, TAU, 16, Color(color, 0.68 + flash * 0.3), 1.2, true)
	_draw_status_icon(canvas, status_id, center, 11.5 * scale, 0.96)
	_draw_stack_pips(canvas, center, mini(maxi(stacks, 1), 3), color)

static func _draw_stack_pips(canvas: CanvasItem, center: Vector2, stack_count: int, color: Color) -> void:
	if stack_count <= 1:
		return
	for index in stack_count:
		var x := (float(index) - float(stack_count - 1) * 0.5) * 3.2
		canvas.draw_circle(center + Vector2(x, 8.4), 1.15, Color(color.lightened(0.2), 0.92))

static func _draw_slow(canvas: CanvasItem, radius: float, flash: float) -> void:
	var color := color_for(&"slow")
	var scale := 1.0 + flash * 0.12
	for ripple_index in 2:
		var ripple_radius := (radius + 4.0 + ripple_index * 4.0) * scale
		canvas.draw_arc(Vector2(0.0, radius * 0.36), ripple_radius, 0.18, PI - 0.18, 18, Color(color, 0.62 - ripple_index * 0.16 + flash * 0.18), 1.8, true)
	for side: float in [-1.0, 1.0]:
		var center := Vector2(side * (radius * 0.56), radius * 0.78)
		canvas.draw_line(center - Vector2(4.0 * side, 0.0), center + Vector2(2.0 * side, 3.0), Color(color.lightened(0.35), 0.82), 1.6, true)
	_draw_status_icon(canvas, &"slow", Vector2(-radius - 8.0, radius * 0.70), 13.0 + flash * 1.5, 0.88)

static func _draw_fortify(canvas: CanvasItem, radius: float, flash: float) -> void:
	var color := color_for(&"fortify")
	var outer := radius + 8.0 + flash * 2.0
	canvas.draw_arc(Vector2.ZERO, outer, -2.65, -0.72, 20, Color(color, 0.78), 2.6, true)
	canvas.draw_arc(Vector2.ZERO, outer, 0.72, 2.65, 20, Color(color, 0.78), 2.6, true)
	for side: float in [-1.0, 1.0]:
		var x: float = side * (radius + 7.0)
		canvas.draw_line(Vector2(x, -4.0), Vector2(x, 7.0), Color(color.lightened(0.32), 0.86), 1.6, true)
	_draw_status_icon(canvas, &"fortify", Vector2(0.0, radius + 9.0), 12.0 + flash * 1.5, 0.82)

static func _draw_haste(canvas: CanvasItem, radius: float, flash: float) -> void:
	var color := color_for(&"haste")
	var center := Vector2(radius + 9.0 + flash * 1.5, -4.0)
	canvas.draw_circle(center, 8.0, Color(BACKPLATE_COLOR, 0.66))
	canvas.draw_arc(center, 8.0, 0.0, TAU, 16, Color(color, 0.72 + flash * 0.22), 1.3, true)
	_draw_status_icon(canvas, &"haste", center, 14.0 + flash * 2.0, 0.94)

static func _draw_mark(canvas: CanvasItem, radius: float, flash: float, phase: float) -> void:
	var color := color_for(&"mark")
	var extent := radius + 10.0 + sin(phase * 2.4) * 1.2 + flash * 2.0
	var arm := clampf(radius * 0.34, 6.0, 10.0)
	for direction in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
		var corner := Vector2(direction.x * extent, direction.y * extent)
		canvas.draw_line(corner, corner - Vector2(direction.x * arm, 0.0), Color(color, 0.76 + flash * 0.22), 2.0, true)
		canvas.draw_line(corner, corner - Vector2(0.0, direction.y * arm), Color(color, 0.76 + flash * 0.22), 2.0, true)
	_draw_status_icon(canvas, &"mark", Vector2(radius + 8.0, -radius * 0.72), 12.0 + flash * 1.5, 0.86)

static func _draw_pierce_mark(canvas: CanvasItem, radius: float, flash: float) -> void:
	var center := Vector2(-radius - 7.0, 0.0)
	canvas.draw_circle(center, 8.0, Color(BACKPLATE_COLOR, 0.68))
	_draw_status_icon(canvas, &"pierce_mark", center, 14.0 + flash * 2.0, 0.94)

static func _draw_frost_stack(canvas: CanvasItem, radius: float, stacks: int, flash: float) -> void:
	var color := color_for(&"frost_stack")
	var count := mini(maxi(stacks, 1), 3)
	for index in count:
		var center := Vector2(radius + 7.0, (float(index) - float(count - 1) * 0.5) * 7.0 + 8.0)
		canvas.draw_circle(center, 4.2 + flash, Color(BACKPLATE_COLOR, 0.68))
		_draw_status_icon(canvas, &"frost_stack", center, 7.5 + flash, 0.90)

static func _draw_sentence(canvas: CanvasItem, radius: float, stacks: int, flash: float) -> void:
	var color := color_for(&"sentence")
	var count := mini(maxi(stacks, 1), 3)
	for index in count:
		var center := Vector2(-radius - 9.0, (float(index) - float(count - 1) * 0.5) * 9.0 - 8.0)
		canvas.draw_circle(center, 5.0 + flash, Color(BACKPLATE_COLOR, 0.72))
		_draw_status_icon(canvas, &"sentence", center, 9.0 + flash * 1.5, 0.94)

static func _draw_control_glyph(canvas: CanvasItem, status_id: StringName, center: Vector2, radius: float, flash: float) -> void:
	var color := color_for(status_id)
	var size := clampf(radius * 0.28, 5.5, 8.0) * (1.0 + flash * 0.18)
	canvas.draw_circle(center, size + 3.0, Color(BACKPLATE_COLOR, 0.82))
	canvas.draw_arc(center, size + 3.0, 0.0, TAU, 18, Color(color, 0.72 + flash * 0.22), 1.2, true)
	_draw_status_icon(canvas, status_id, center, size * 1.75, 0.98)

static func _draw_status_icon(canvas: CanvasItem, status_id: StringName, center: Vector2, size: float, opacity: float) -> void:
	var cell := icon_cell_for(status_id)
	if cell.x < 0 or cell.y < 0 or STATUS_ICON_ATLAS == null:
		return
	var source_size := STATUS_ICON_ATLAS.get_size() / Vector2(ICON_GRID_SIZE)
	var source_rect := Rect2(Vector2(cell) * source_size, source_size)
	var destination_rect := Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size)
	canvas.draw_texture_rect_region(STATUS_ICON_ATLAS, destination_rect, source_rect, Color(1.0, 1.0, 1.0, clampf(opacity, 0.0, 1.0)))

static func _stack_count(status_id: StringName, common_ailments: Dictionary) -> int:
	if not common_ailments.has(status_id):
		return 1
	var data: Dictionary = common_ailments[status_id]
	match status_id:
		&"burn": return (data.get("stacks", []) as Array).size()
		&"bleed":
			var total := 0
			for source in (data.get("sources", {}) as Dictionary).values():
				total += (source.get("stacks", []) as Array).size()
			return total
	return int(data.get("stacks", 1))

static func _flash(visual_flashes: Dictionary, status_id: StringName) -> float:
	return clampf(float(visual_flashes.get(status_id, 0.0)), 0.0, 1.0)
