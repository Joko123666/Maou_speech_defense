class_name FlatEffectIcon
extends Control

const ICON_ATLAS: Texture2D = preload("res://assets/graphics/ui/flat_effect_icon_atlas_v019.png")
const ATLAS_GRID_SIZE := Vector2i(5, 5)
const ATLAS_CELLS := {
	&"damage": Vector2i(0, 0),
	&"speed": Vector2i(1, 0),
	&"area": Vector2i(2, 0),
	&"health": Vector2i(3, 0),
	&"control": Vector2i(4, 0),
	&"tower": Vector2i(0, 1),
	&"core": Vector2i(1, 1),
	&"cursor": Vector2i(2, 1),
	&"formation": Vector2i(3, 1),
	&"global": Vector2i(4, 1),
	&"poison": Vector2i(0, 2),
	&"burn": Vector2i(1, 2),
	&"bleed": Vector2i(2, 2),
	&"shock": Vector2i(3, 2),
	&"mark": Vector2i(4, 2),
	&"experience": Vector2i(0, 3),
	&"warning": Vector2i(1, 3),
	&"return": Vector2i(2, 3),
	&"overheat": Vector2i(3, 3),
	&"guidance": Vector2i(4, 3),
	&"mark_amp": Vector2i(0, 4),
	&"default": Vector2i(1, 4),
	&"skill": Vector2i(2, 4),
	&"cooldown": Vector2i(3, 4),
	&"armor": Vector2i(4, 4),
}

var icon_key: StringName = &"default"
var accent_color: Color = Color("65e0c0")

func configure(key: StringName, color: Color) -> FlatEffectIcon:
	icon_key = key
	accent_color = color
	custom_minimum_size = Vector2(34.0, 34.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46
	draw_circle(center, radius, Color(accent_color, 0.12))
	draw_arc(center, radius, 0.0, TAU, 28, Color(accent_color, 0.58), 1.5, true)
	var cell: Vector2i = ATLAS_CELLS.get(icon_key, ATLAS_CELLS[&"default"])
	var source_cell_size := ICON_ATLAS.get_size() / Vector2(ATLAS_GRID_SIZE)
	var source_rect := Rect2(Vector2(cell) * source_cell_size, source_cell_size)
	var glyph_size := Vector2.ONE * radius * 1.7
	var destination_rect := Rect2(center - glyph_size * 0.5, glyph_size)
	draw_texture_rect_region(ICON_ATLAS, destination_rect, source_rect, accent_color, false, true)
