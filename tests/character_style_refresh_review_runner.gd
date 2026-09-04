extends Control

const REVIEW_OUTPUT := "res://tests/visual_reviews/character_style_refresh_pilots.png"
const PILOTS := [
	{
		"label": "RAPID / char_001",
		"current": "res://assets/graphics/defenders/rapid.png",
		"pilot": "res://assets/graphics/style_refresh_v019/defenders/rapid.png",
	},
	{
		"label": "KNOCKBACK / char_005",
		"current": "res://assets/graphics/defenders/knockback.png",
		"pilot": "res://assets/graphics/style_refresh_v019/defenders/knockback.png",
	},
	{
		"label": "ROYAL GUARD / char_011",
		"current": "res://assets/graphics/towers/partason_royal_guard.png",
		"pilot": "res://assets/graphics/style_refresh_v019/towers/emerald_guardian.png",
	},
	{
		"label": "GIVEN / char_012",
		"current": "res://assets/graphics/combat_sd/retainers/given.png",
		"pilot": "res://assets/graphics/style_refresh_v019/retainer_sd/given_v2.png",
	},
	{
		"label": "JEOMUJEOM / char_013",
		"current": "res://assets/graphics/combat_sd/retainers/jeomujeom.png",
		"pilot": "res://assets/graphics/style_refresh_v019/retainer_sd/jeomujeom_v2.png",
	},
]

func _ready() -> void:
	_build_review_catalog()
	if OS.get_cmdline_user_args().has("--capture-and-quit"):
		_capture_and_quit.call_deferred()

func _build_review_catalog() -> void:
	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 24)
	margin.add_theme_constant_override(&"margin_top", 18)
	margin.add_theme_constant_override(&"margin_right", 24)
	margin.add_theme_constant_override(&"margin_bottom", 18)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 12)
	margin.add_child(page)
	var title := Label.new()
	title.text = "v0.19 CHARACTER STYLE PILOT — CURRENT / STAGED / 96·64·48 PX"
	title.add_theme_font_size_override(&"font_size", 24)
	title.add_theme_color_override(&"font_color", Color("f0d58a"))
	page.add_child(title)
	var note := Label.new()
	note.text = "Isolated review catalog. Staged pilots are not referenced by the active GameAssetCatalogData."
	note.add_theme_font_size_override(&"font_size", 14)
	note.add_theme_color_override(&"font_color", Color("aeb8cf"))
	page.add_child(note)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 12)
	page.add_child(columns)
	for pilot_value in PILOTS:
		columns.add_child(_build_pilot_column(pilot_value as Dictionary))

func _build_pilot_column(pilot: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(236, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override(&"panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 6)
	panel.add_child(stack)
	var heading := Label.new()
	heading.text = String(pilot.get("label", "PILOT"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override(&"font_size", 14)
	heading.add_theme_color_override(&"font_color", Color("f7f2e7"))
	stack.add_child(heading)
	stack.add_child(_label("CURRENT", Color("8f9ab2")))
	stack.add_child(_texture_box(String(pilot.get("current", "")), Vector2(190, 148)))
	stack.add_child(_label("STAGED PILOT", Color("f0d58a")))
	stack.add_child(_texture_box(String(pilot.get("pilot", "")), Vector2(190, 210)))
	stack.add_child(_label("RUNTIME READABILITY", Color("72d6bd")))

	var sizes := HBoxContainer.new()
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override(&"separation", 6)
	stack.add_child(sizes)
	for target_size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		var image := _texture_box(String(pilot.get("pilot", "")), Vector2(target_size, target_size))
		sample.add_child(image)
		var size_label := _label("%dpx" % target_size, Color("aeb8cf"))
		size_label.add_theme_font_size_override(&"font_size", 10)
		sample.add_child(size_label)
		sizes.add_child(sample)
	return panel

func _texture_box(path: String, minimum_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = minimum_size
	rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect

func _label(value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", 11)
	label.add_theme_color_override(&"font_color", color)
	return label

func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(REVIEW_OUTPUT))
	if error == OK:
		print("CHARACTER STYLE REVIEW CAPTURE PASS: %s" % REVIEW_OUTPUT)
	else:
		push_error("character style review capture failed with error %d" % error)
	get_tree().quit(error)
