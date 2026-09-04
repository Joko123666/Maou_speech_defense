class_name FactionMarkerIcon
extends Control

var marker_style: StringName = &""
var primary_color: Color = Color.WHITE
var secondary_color: Color = Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 28.0), maxf(custom_minimum_size.y, 28.0))

func configure(style: StringName, primary: Color, secondary: Color) -> void:
	marker_style = ElectionFactionData.normalized_marker_style(style)
	primary_color = primary
	secondary_color = secondary
	visible = marker_style != &""
	queue_redraw()

func clear() -> void:
	marker_style = &""
	visible = false
	queue_redraw()

func _draw() -> void:
	if marker_style == &"":
		return
	var center := size * 0.5
	var radius := maxf(minf(size.x, size.y) * 0.36, 6.0)
	var dark := Color(0.035, 0.035, 0.05, 0.96)
	match marker_style:
		&"sword_shield":
			var shield := PackedVector2Array([
				center + Vector2(-radius * 0.72, -radius * 0.68),
				center + Vector2(radius * 0.72, -radius * 0.68),
				center + Vector2(radius * 0.56, radius * 0.34),
				center + Vector2(0.0, radius),
				center + Vector2(-radius * 0.56, radius * 0.34),
				center + Vector2(-radius * 0.72, -radius * 0.68),
			])
			draw_polyline(shield, dark, 5.0, true)
			draw_polyline(shield, primary_color, 2.2, true)
			_draw_double_line(center + Vector2(-radius * 0.62, radius * 0.64), center + Vector2(radius * 0.65, -radius * 0.72), dark, secondary_color)
		&"heart":
			var heart := PackedVector2Array([
				center + Vector2(0.0, radius), center + Vector2(-radius * 0.86, radius * 0.08),
				center + Vector2(-radius * 0.72, -radius * 0.62), center + Vector2(-radius * 0.22, -radius * 0.78),
				center, center + Vector2(radius * 0.22, -radius * 0.78),
				center + Vector2(radius * 0.72, -radius * 0.62), center + Vector2(radius * 0.86, radius * 0.08),
				center + Vector2(0.0, radius),
			])
			draw_polyline(heart, dark, 5.0, true)
			draw_polyline(heart, primary_color, 2.2, true)
			draw_line(center + Vector2(-radius * 0.42, radius * 0.18), center + Vector2(radius * 0.42, radius * 0.18), secondary_color, 2.0, true)
		&"tentacle_eye":
			var eye := PackedVector2Array()
			for index in 13:
				var ratio := float(index) / 12.0
				eye.append(center + Vector2(lerpf(-radius, radius, ratio), -sin(ratio * PI) * radius * 0.48))
			for index in 13:
				var ratio := float(index) / 12.0
				eye.append(center + Vector2(lerpf(radius, -radius, ratio), sin(ratio * PI) * radius * 0.48))
			eye.append(eye[0])
			draw_polyline(eye, dark, 5.0, true)
			draw_polyline(eye, primary_color, 2.2, true)
			draw_circle(center, radius * 0.3, secondary_color)
			draw_circle(center, radius * 0.13, dark)
			for offset in [-0.52, 0.0, 0.52]:
				_draw_double_line(center + Vector2(radius * float(offset), radius * 0.5), center + Vector2(radius * float(offset + 0.12), radius), dark, primary_color)
		&"skull_aura":
			draw_arc(center + Vector2(0.0, -radius * 0.12), radius * 0.72, PI, TAU, 18, dark, 5.0, true)
			draw_arc(center + Vector2(0.0, -radius * 0.12), radius * 0.72, PI, TAU, 18, primary_color, 2.2, true)
			draw_circle(center + Vector2(-radius * 0.27, -radius * 0.08), radius * 0.14, secondary_color)
			draw_circle(center + Vector2(radius * 0.27, -radius * 0.08), radius * 0.14, secondary_color)
			for x in [-0.35, 0.0, 0.35]:
				_draw_double_line(center + Vector2(radius * float(x), radius * 0.38), center + Vector2(radius * float(x), radius * 0.82), dark, primary_color)
			for angle in [-2.72, -1.92, -1.22, -0.42]:
				_draw_double_line(center + Vector2.from_angle(float(angle)) * radius * 0.82, center + Vector2.from_angle(float(angle)) * radius * 1.12, dark, secondary_color)
		&"scythe_blood":
			draw_arc(center + Vector2(radius * 0.1, -radius * 0.08), radius * 0.76, -2.7, 0.5, 24, dark, 5.2, true)
			draw_arc(center + Vector2(radius * 0.1, -radius * 0.08), radius * 0.76, -2.7, 0.5, 24, primary_color, 2.3, true)
			_draw_double_line(center + Vector2(radius * 0.55, -radius * 0.72), center + Vector2(-radius * 0.5, radius), dark, secondary_color)
			draw_circle(center + Vector2(radius * 0.58, radius * 0.62), radius * 0.15, dark)
			draw_circle(center + Vector2(radius * 0.58, radius * 0.62), radius * 0.08, primary_color)

func _draw_double_line(from: Vector2, to: Vector2, outline: Color, fill: Color) -> void:
	draw_line(from, to, outline, 5.0, true)
	draw_line(from, to, fill, 2.2, true)
