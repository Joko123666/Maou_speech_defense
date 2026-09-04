extends Control

const REVIEW_OUTPUT := "res://tests/visual_reviews/character_style_refresh_m3_defenders.png"
const ENTRIES := [
	{
		"label": "MANA CONDUCTION TOWER / chain",
		"id": "chain",
		"identity": "CYAN CORE · TWIN CONDUCTORS · RELAY BASE",
	},
	{
		"label": "RUBBER GOLEM / rubber_golem",
		"id": "rubber_golem",
		"identity": "ELASTIC SEGMENTS · TENSION CORDS · PUSH FISTS",
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
	margin.add_theme_constant_override(&"margin_left", 22)
	margin.add_theme_constant_override(&"margin_top", 15)
	margin.add_theme_constant_override(&"margin_right", 22)
	margin.add_theme_constant_override(&"margin_bottom", 15)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 7)
	margin.add_child(page)
	var title := _label("v0.19 MISSING DEFENDERS M3-A — CURRENT · STAGED PAIRS · 96/64/48 PX", Color("f0d58a"))
	title.add_theme_font_size_override(&"font_size", 21)
	page.add_child(title)
	var note := _label("Identity and mobile-readability review only. Refreshed assets remain isolated from the active catalog.", Color("aeb8cf"))
	note.add_theme_font_size_override(&"font_size", 13)
	page.add_child(note)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 12)
	page.add_child(columns)
	for entry_value in ENTRIES:
		columns.add_child(_build_defender_column(entry_value as Dictionary))

func _build_defender_column(entry: Dictionary) -> Control:
	var content_id := String(entry.get("id", ""))
	var current_full_body := "res://assets/graphics/defenders/%s.png" % content_id
	var current_icon := "res://assets/graphics/defender_icons/%s.png" % content_id
	var staged_full_body := "res://assets/graphics/style_refresh_v019/defenders/%s.png" % content_id
	var staged_icon := "res://assets/graphics/style_refresh_v019/defender_icons/%s.png" % content_id

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(606, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override(&"panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 3)
	panel.add_child(stack)
	var heading := _label(String(entry.get("label", "DEFENDER")), Color("f7f2e7"))
	heading.add_theme_font_size_override(&"font_size", 15)
	stack.add_child(heading)
	var identity := _label(String(entry.get("identity", "")), Color("72d6bd"))
	identity.add_theme_font_size_override(&"font_size", 10)
	stack.add_child(identity)

	stack.add_child(_label("CURRENT FULL BODY / ICON", Color("8f9ab2")))
	stack.add_child(_build_pair_row(current_full_body, current_icon, Vector2(150, 150)))
	stack.add_child(_label("STAGED FULL BODY / ICON", Color("f0d58a")))
	stack.add_child(_build_pair_row(staged_full_body, staged_icon, Vector2(190, 190)))
	stack.add_child(_label("STAGED PAIR READABILITY", Color("72d6bd")))
	stack.add_child(_build_size_row(staged_full_body, staged_icon))
	return panel

func _build_pair_row(left_path: String, right_path: String, sample_size: Vector2) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 22)
	row.add_child(_texture_box(left_path, sample_size))
	row.add_child(_texture_box(right_path, sample_size))
	return row

func _build_size_row(full_body_path: String, icon_path: String) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	for target_size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override(&"separation", 3)
		pair.add_child(_texture_box(full_body_path, Vector2(target_size, target_size)))
		pair.add_child(_texture_box(icon_path, Vector2(target_size, target_size)))
		sample.add_child(pair)
		var size_label := _label("%dpx BODY / ICON" % target_size, Color("aeb8cf"))
		size_label.add_theme_font_size_override(&"font_size", 9)
		sample.add_child(size_label)
		row.add_child(sample)
	return row

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
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(REVIEW_OUTPUT))
	if error == OK:
		print("CHARACTER M3 DEFENDER REVIEW CAPTURE PASS: %s" % REVIEW_OUTPUT)
	else:
		push_error("character M3 defender review capture failed with error %d" % error)
	get_tree().quit(error)
