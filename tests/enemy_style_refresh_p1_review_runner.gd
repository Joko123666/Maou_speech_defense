extends Control

const OUTPUT_PATH := "res://tests/visual_reviews/enemy_style_refresh_p1.png"
const ASSET_IDS := [
	&"goblin_raider",
	&"skeleton_raider",
	&"orc_shield",
	&"partason_standard_shield",
]

func _ready() -> void:
	_build_review()
	if OS.get_cmdline_user_args().has("--capture-and-quit"):
		_capture_and_quit.call_deferred()

func _build_review() -> void:
	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 8)
	margin.add_child(page)
	page.add_child(_label("v0.19 ENEMY STYLE REFRESH / P1", Color("f0d58a"), 22))
	page.add_child(_label("1254px RGBA masters · left-facing roles · Forward Mobile checks at 240 / 96 / 64 / 48px", Color("aeb8cf"), 12))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 10)
	page.add_child(columns)
	for content_id in ASSET_IDS:
		columns.add_child(_asset_column(content_id))

func _asset_column(content_id: StringName) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(292, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override(&"panel", style)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override(&"separation", 6)
	panel.add_child(stack)
	stack.add_child(_label(String(content_id).replace("_", " ").to_upper(), Color("f7f2e7"), 13))
	stack.add_child(_texture_rect(_texture(content_id), 240))
	stack.add_child(_label("ENEMY-FACING ←", Color("f0d58a"), 10))

	var sizes := HBoxContainer.new()
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override(&"separation", 12)
	for size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		sample.add_child(_label("%dPX" % size, Color("8f9ab2"), 9))
		sample.add_child(_texture_rect(_texture(content_id), size))
		sizes.add_child(sample)
	stack.add_child(sizes)
	return panel

func _texture(content_id: StringName) -> Texture2D:
	return load("res://assets/graphics/style_refresh_v019/enemy_p1/%s.png" % content_id) as Texture2D

func _texture_rect(texture: Texture2D, target_size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(target_size, target_size)
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect

func _label(value: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label

func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var error := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error == OK:
		print("ENEMY P1 STYLE REVIEW CAPTURE PASS: %s" % OUTPUT_PATH)
	else:
		push_error("enemy P1 style review capture failed with error %d" % error)
	get_tree().quit(error)
