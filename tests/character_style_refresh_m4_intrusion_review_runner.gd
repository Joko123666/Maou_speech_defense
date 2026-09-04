extends Control

const REVIEW_OUTPUTS := [
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_a.png",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_b.png",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_c.png",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_d.png",
]
const PAGES := [
	{
		"id": "A",
		"entries": [
			{"label": "PARTASON", "cue": "RIGHT ALLY → LEFT HOSTILE SHIELD BASH", "ally": "res://assets/graphics/combat_sd/candidates/partason.png", "intrusion": "res://assets/graphics/candidate_intrusion_sd/partason.png"},
			{"label": "JIANE", "cue": "RIGHT ALLY → LEFT BARBED HEART", "ally": "res://assets/graphics/combat_sd/candidates/jiane.png", "intrusion": "res://assets/graphics/candidate_intrusion_sd/jiane.png"},
			{"label": "KASUHA", "cue": "RIGHT ALLY → LEFT TENTACLE EYE", "ally": "res://assets/graphics/combat_sd/candidates/kasuha.png", "intrusion": "res://assets/graphics/candidate_intrusion_sd/kasuha.png"},
		],
	},
	{
		"id": "B",
		"entries": [
			{"label": "IRELAI", "cue": "RIGHT ALLY → LEFT THREE-SKULL WAVE", "ally": "res://assets/graphics/combat_sd/candidates/irelai.png", "intrusion": "res://assets/graphics/candidate_intrusion_sd/irelai.png"},
			{"label": "JUDAGINDA", "cue": "RIGHT ALLY → LEFT BLOOD-SCYTHE LUNGE", "ally": "res://assets/graphics/combat_sd/candidates/judaginda.png", "intrusion": "res://assets/graphics/candidate_intrusion_sd/judaginda.png"},
		],
	},
	{
		"id": "C",
		"entries": [
			{"label": "KANDA", "cue": "RIGHT ALLY → LEFT GREAT-SWORD CLEAVE", "ally": "res://assets/graphics/combat_sd/retainers/kanda.png", "intrusion": "res://assets/graphics/retainer_intrusion_sd/kanda.png"},
			{"label": "GIVEN", "cue": "RIGHT ALLY → LEFT BARBED WHIP SNAP", "ally": "res://assets/graphics/combat_sd/retainers/given.png", "intrusion": "res://assets/graphics/retainer_intrusion_sd/given.png"},
			{"label": "JEOMUJEOM", "cue": "FIVE EYES · TWO HANDS · LEFT CRUSH", "ally": "res://assets/graphics/combat_sd/retainers/jeomujeom.png", "intrusion": "res://assets/graphics/retainer_intrusion_sd/jeomujeom.png"},
		],
	},
	{
		"id": "D",
		"entries": [
			{"label": "JUGDIED", "cue": "ONE RIDER + HORSE · LEFT CHARGE", "ally": "res://assets/graphics/combat_sd/retainers/jugdied.png", "intrusion": "res://assets/graphics/retainer_intrusion_sd/jugdied.png"},
			{"label": "DEATH VANGUARD", "cue": "FOUR-MEMBER LEFT RUSH FORMATION", "ally": "res://assets/graphics/combat_sd/retainers/death_vanguard.png", "intrusion": "res://assets/graphics/retainer_intrusion_sd/death_vanguard.png"},
		],
	},
]

func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var page_index := 3 if user_args.has("--page-d") else (2 if user_args.has("--page-c") else (1 if user_args.has("--page-b") else 0))
	_build_review(PAGES[page_index] as Dictionary)
	if user_args.has("--capture-and-quit"):
		_capture_and_quit.call_deferred(REVIEW_OUTPUTS[page_index])

func _build_review(page_data: Dictionary) -> void:
	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_top", 14)
	margin.add_theme_constant_override(&"margin_right", 18)
	margin.add_theme_constant_override(&"margin_bottom", 14)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 6)
	margin.add_child(page)
	page.add_child(_label("v0.19 OFFICIAL INTRUSIONS M4 / PAGE %s — ACTIVE ALLY → · ACTIVE ENEMY ← · 96/64/48 PX" % String(page_data.get("id", "")), Color("f0d58a"), 21))
	page.add_child(_label("Direction, hostility, faction effect, and mobile readability. Every sample is loaded from the active catalog path.", Color("aeb8cf"), 13))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 10)
	page.add_child(columns)
	for entry_value in page_data.get("entries", []) as Array:
		columns.add_child(_build_panel(entry_value as Dictionary))

func _build_panel(entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override(&"panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 5)
	panel.add_child(stack)
	stack.add_child(_label(String(entry.get("label", "CHARACTER")), Color("f7f2e7"), 15))
	stack.add_child(_label(String(entry.get("cue", "DIRECTION CUE")), Color("72d6bd"), 10))

	var pair := HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override(&"separation", 10)
	pair.add_child(_asset_column("ALLY →", String(entry.get("ally", "")), 158))
	pair.add_child(_asset_column("INTRUSION ←", String(entry.get("intrusion", "")), 158))
	stack.add_child(pair)
	stack.add_child(_label("INTRUSION MOBILE READABILITY", Color("f0d58a"), 10))
	stack.add_child(_size_row(String(entry.get("intrusion", ""))))
	return panel

func _asset_column(title: String, path: String, target_size: int) -> Control:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 2)
	column.add_child(_label(title, Color("8f9ab2") if title.begins_with("ALLY") else Color("f0d58a"), 9))
	column.add_child(_texture_box(path, Vector2(target_size, target_size)))
	return column

func _size_row(path: String) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	for target_size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		sample.add_child(_texture_box(path, Vector2(target_size, target_size)))
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
		print("CHARACTER M4 INTRUSION REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("character M4 intrusion review capture failed with error %d" % error)
	get_tree().quit(error)
