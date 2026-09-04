extends Control

const REVIEW_OUTPUT_A := "res://tests/visual_reviews/character_style_refresh_m3_candidates_a.png"
const REVIEW_OUTPUT_B := "res://tests/visual_reviews/character_style_refresh_m3_candidates_b.png"
const PAGES := [
	{
		"id": "A",
		"entries": [
			{
				"label": "PARTASON VIII",
				"cue": "SWORD + SHIELD · ORTHODOX FRONT LINE",
				"current_portrait": "res://assets/graphics/candidates/partason.png",
				"current_sd": "res://assets/graphics/combat_sd/candidates/partason.png",
				"staged_portrait": "res://assets/graphics/style_refresh_v019/candidates/partason.png",
				"staged_sd": "res://assets/graphics/style_refresh_v019/candidate_sd/partason.png",
			},
			{
				"label": "JIANE YAHANIYA",
				"cue": "HEART CHARM WAVE · MAGENTA CONTROL",
				"current_portrait": "res://assets/graphics/candidates/jiane.png",
				"current_sd": "res://assets/graphics/combat_sd/candidates/jiane.png",
				"staged_portrait": "res://assets/graphics/style_refresh_v019/candidates/jiane.png",
				"staged_sd": "res://assets/graphics/style_refresh_v019/candidate_sd/jiane.png",
			},
		],
	},
	{
		"id": "B",
		"entries": [
			{
				"label": "KASUHA RZZAR",
				"cue": "TENTACLE EYE · TELEGRAPHED AREA BURST",
				"current_portrait": "res://assets/graphics/candidates/kasuha.png",
				"current_sd": "res://assets/graphics/combat_sd/candidates/kasuha.png",
				"staged_portrait": "res://assets/graphics/style_refresh_v019/candidates/kasuha.png",
				"staged_sd": "res://assets/graphics/style_refresh_v019/candidate_sd/kasuha.png",
			},
			{
				"label": "IRELAI GEOJUSEODO",
				"cue": "SKULL AURA · SLOW DEATH WAVE",
				"current_portrait": "res://assets/graphics/candidates/irelai.png",
				"current_sd": "res://assets/graphics/combat_sd/candidates/irelai.png",
				"staged_portrait": "res://assets/graphics/style_refresh_v019/candidates/irelai.png",
				"staged_sd": "res://assets/graphics/style_refresh_v019/candidate_sd/irelai.png",
			},
		],
	},
]

func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var page_index := 1 if user_args.has("--page-b") else 0
	_build_review(PAGES[page_index] as Dictionary)
	if user_args.has("--capture-and-quit"):
		_capture_and_quit.call_deferred(REVIEW_OUTPUT_B if page_index == 1 else REVIEW_OUTPUT_A)

func _build_review(page_data: Dictionary) -> void:
	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 20)
	margin.add_theme_constant_override(&"margin_top", 14)
	margin.add_theme_constant_override(&"margin_right", 20)
	margin.add_theme_constant_override(&"margin_bottom", 14)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 6)
	margin.add_child(page)
	page.add_child(_label("v0.19 CANDIDATE PAIRS M3-C / PAGE %s — CURRENT · STAGED · 96/64/48 PX" % String(page_data.get("id", "")), Color("f0d58a"), 21))
	page.add_child(_label("Identity and mobile-readability review only. The staged assets are not referenced by the active catalog.", Color("aeb8cf"), 13))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 12)
	page.add_child(columns)
	for entry_value in page_data.get("entries", []) as Array:
		columns.add_child(_build_candidate_panel(entry_value as Dictionary))

func _build_candidate_panel(entry: Dictionary) -> Control:
	var panel := _review_panel()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 3)
	panel.add_child(stack)
	stack.add_child(_label(String(entry.get("label", "CANDIDATE")), Color("f7f2e7"), 15))
	stack.add_child(_label(String(entry.get("cue", "ROLE CUE")), Color("72d6bd"), 10))
	stack.add_child(_label("CURRENT PORTRAIT / SD", Color("8f9ab2"), 10))
	stack.add_child(_pair_row(String(entry.get("current_portrait", "")), String(entry.get("current_sd", "")), Vector2(140, 126)))
	stack.add_child(_label("STAGED PORTRAIT / SD", Color("f0d58a"), 10))
	stack.add_child(_pair_row(String(entry.get("staged_portrait", "")), String(entry.get("staged_sd", "")), Vector2(180, 202)))
	stack.add_child(_label("STAGED PAIR READABILITY", Color("72d6bd"), 10))
	stack.add_child(_size_row(String(entry.get("staged_portrait", "")), String(entry.get("staged_sd", ""))))
	return panel

func _review_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(610, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 7
	style.content_margin_right = 8
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override(&"panel", style)
	return panel

func _pair_row(left_path: String, right_path: String, image_size: Vector2) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 10)
	row.add_child(_texture_box(left_path, image_size))
	row.add_child(_texture_box(right_path, image_size))
	return row

func _size_row(portrait_path: String, sd_path: String) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	for target_size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override(&"separation", 4)
		pair.add_child(_texture_box(portrait_path, Vector2(target_size, target_size)))
		pair.add_child(_texture_box(sd_path, Vector2(target_size, target_size)))
		sample.add_child(pair)
		sample.add_child(_label("%dpx" % target_size, Color("aeb8cf"), 9))
		row.add_child(sample)
	return row

func _texture_box(path: String, minimum_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = minimum_size
	rect.texture = load(path) as Texture2D
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

func _capture_and_quit(output_path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("CHARACTER M3 CANDIDATE REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("character M3 candidate review capture failed with error %d" % error)
	get_tree().quit(error)
