extends Control

const REVIEW_OUTPUT_A := "res://tests/visual_reviews/character_style_refresh_defender_icons_a.png"
const REVIEW_OUTPUT_B := "res://tests/visual_reviews/character_style_refresh_defender_icons_b.png"
const PAGES := [
	{
		"id": "A",
		"entries": [
			{"label": "RAPID / char_001", "id": "rapid"},
			{"label": "PIERCE / char_002", "id": "pierce"},
			{"label": "AREA / char_003", "id": "area"},
			{"label": "EXECUTE / char_004", "id": "execute"},
		],
	},
	{
		"id": "B",
		"entries": [
			{"label": "KNOCKBACK / char_005", "id": "knockback"},
			{"label": "MARK / char_006", "id": "mark"},
			{"label": "SLOW / char_010", "id": "slow"},
		],
	},
]

var _page_root: Control

func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var page_index := 1 if user_args.has("--page-b") else 0
	_build_review_catalog(PAGES[page_index] as Dictionary)
	if user_args.has("--capture-and-quit"):
		var output_path := REVIEW_OUTPUT_B if page_index == 1 else REVIEW_OUTPUT_A
		_capture_and_quit.call_deferred(output_path)

func _build_review_catalog(page_data: Dictionary) -> void:
	_page_root = Control.new()
	_page_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page_root)

	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_root.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 20)
	margin.add_theme_constant_override(&"margin_top", 16)
	margin.add_theme_constant_override(&"margin_right", 20)
	margin.add_theme_constant_override(&"margin_bottom", 16)
	_page_root.add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 8)
	margin.add_child(page)
	var title := Label.new()
	title.text = "v0.19 DEFENDER ICON M2-B / PAGE %s — CURRENT · FULL-BODY · STAGED · 96/64/48 PX" % String(page_data.get("id", ""))
	title.add_theme_font_size_override(&"font_size", 22)
	title.add_theme_color_override(&"font_color", Color("f0d58a"))
	page.add_child(title)
	var note := Label.new()
	note.text = "Identity-pair review only. Staged full-body and icon assets are not referenced by the active catalog."
	note.add_theme_font_size_override(&"font_size", 13)
	note.add_theme_color_override(&"font_color", Color("aeb8cf"))
	page.add_child(note)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 10)
	page.add_child(columns)
	for entry_value in page_data.get("entries", []) as Array:
		columns.add_child(_build_defender_column(entry_value as Dictionary))

func _build_defender_column(entry: Dictionary) -> Control:
	var content_id := String(entry.get("id", ""))
	var current_icon_path := "res://assets/graphics/defender_icons/%s.png" % content_id
	var full_body_path := "res://assets/graphics/style_refresh_v019/defenders/%s.png" % content_id
	var staged_icon_path := "res://assets/graphics/style_refresh_v019/defender_icons/%s.png" % content_id
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(286, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 9
	style.content_margin_top = 9
	style.content_margin_right = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override(&"panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 5)
	panel.add_child(stack)
	var heading := _label(String(entry.get("label", "DEFENDER")), Color("f7f2e7"))
	heading.add_theme_font_size_override(&"font_size", 14)
	stack.add_child(heading)

	var identity_pair := HBoxContainer.new()
	identity_pair.alignment = BoxContainer.ALIGNMENT_CENTER
	identity_pair.add_theme_constant_override(&"separation", 5)
	stack.add_child(identity_pair)
	identity_pair.add_child(_build_identity_sample("CURRENT", current_icon_path, Color("8f9ab2")))
	identity_pair.add_child(_build_identity_sample("FULL BODY", full_body_path, Color("72d6bd")))
	identity_pair.add_child(_build_identity_sample("STAGED", staged_icon_path, Color("f0d58a")))

	stack.add_child(_label("STAGED ICON READABILITY", Color("72d6bd")))
	var sizes := HBoxContainer.new()
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override(&"separation", 8)
	stack.add_child(sizes)
	for target_size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		sample.add_child(_texture_box(staged_icon_path, Vector2(target_size, target_size)))
		var size_label := _label("%dpx" % target_size, Color("aeb8cf"))
		size_label.add_theme_font_size_override(&"font_size", 10)
		sample.add_child(size_label)
		sizes.add_child(sample)
	return panel

func _build_identity_sample(caption: String, path: String, color: Color) -> Control:
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := _label(caption, color)
	label.add_theme_font_size_override(&"font_size", 9)
	stack.add_child(label)
	stack.add_child(_texture_box(path, Vector2(82, 142)))
	return stack

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

func _capture_and_quit(output_path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("CHARACTER DEFENDER ICON REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("character defender icon review capture failed with error %d" % error)
	get_tree().quit(error)
