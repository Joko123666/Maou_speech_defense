extends Control

const REVIEW_OUTPUT_A := "res://tests/visual_reviews/character_style_refresh_m3_guards_a.png"
const REVIEW_OUTPUT_B := "res://tests/visual_reviews/character_style_refresh_m3_guards_b.png"
const PAGES := [
	{
		"id": "A",
		"entries": [
			{
				"label": "JIANE FANATICAL FOLLOWER",
				"cue": "HEART GLAIVE · SHORT-RANGE FRENZY",
				"current": "res://assets/graphics/towers/jiane_fanatic_follower.png",
				"staged": "res://assets/graphics/style_refresh_v019/towers/sapphire_lance.png",
			},
			{
				"label": "KASUHA ABYSS DEVOTEE",
				"cue": "TENTACLE EYE · REAR AREA PULSE",
				"current": "res://assets/graphics/towers/kasuha_abyss_believer.png",
				"staged": "res://assets/graphics/style_refresh_v019/towers/amethyst_nova.png",
			},
			{
				"label": "IRELAI RESURRECTED GUARD",
				"cue": "SKULL AURA · COLLAPSE AND REVIVE",
				"current": "res://assets/graphics/towers/irelai_resurrected_guard.png",
				"staged": "res://assets/graphics/style_refresh_v019/towers/jade_roulette.png",
			},
		],
	},
	{
		"id": "B",
		"entries": [
			{
				"label": "PARTASON ROYAL GUARD ANCHOR",
				"cue": "SWORD + SHIELD · APPROVED GUARD TIER",
				"current": "res://assets/graphics/towers/partason_royal_guard.png",
				"staged": "res://assets/graphics/style_refresh_v019/towers/emerald_guardian.png",
			},
			{
				"label": "JUDAGINDA RANGED INQUISITOR",
				"cue": "RITUAL STAFF · REAR JUDGMENT BOLT",
				"current": "res://assets/graphics/towers/obsidian_inquisitor.png",
				"staged": "res://assets/graphics/style_refresh_v019/towers/obsidian_inquisitor.png",
			},
			{
				"label": "JUDAGINDA MELEE VERDICT",
				"cue": "HEAVY SCYTHE · FRONT EXECUTION",
				"current": "res://assets/graphics/towers/obsidian_verdict.png",
				"staged": "res://assets/graphics/style_refresh_v019/towers/obsidian_verdict.png",
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
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_top", 14)
	margin.add_theme_constant_override(&"margin_right", 18)
	margin.add_theme_constant_override(&"margin_bottom", 14)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 6)
	margin.add_child(page)
	page.add_child(_label("v0.19 GUARD SET M3-D / PAGE %s — CURRENT · STAGED · 96/64/48 PX" % String(page_data.get("id", "")), Color("f0d58a"), 21))
	page.add_child(_label("Role, faction-token, and mobile-readability review only. Staged assets are not referenced by the active catalog.", Color("aeb8cf"), 13))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 10)
	page.add_child(columns)
	for entry_value in page_data.get("entries", []) as Array:
		columns.add_child(_build_guard_panel(entry_value as Dictionary))

func _build_guard_panel(entry: Dictionary) -> Control:
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
	stack.add_child(_label(String(entry.get("label", "GUARD")), Color("f7f2e7"), 14))
	stack.add_child(_label(String(entry.get("cue", "ROLE CUE")), Color("72d6bd"), 10))

	var pair := HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override(&"separation", 10)
	pair.add_child(_asset_column("CURRENT", String(entry.get("current", "")), 158))
	pair.add_child(_asset_column("STAGED", String(entry.get("staged", "")), 158))
	stack.add_child(pair)

	stack.add_child(_label("STAGED MOBILE READABILITY", Color("f0d58a"), 10))
	stack.add_child(_size_row(String(entry.get("staged", ""))))
	return panel

func _asset_column(title: String, path: String, target_size: int) -> Control:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 2)
	column.add_child(_label(title, Color("8f9ab2") if title == "CURRENT" else Color("f0d58a"), 9))
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
		print("CHARACTER M3 GUARD REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("character M3 guard review capture failed with error %d" % error)
	get_tree().quit(error)
