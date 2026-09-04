extends Control

const OUTPUTS := [
	"res://tests/visual_reviews/official_intrusion_boss_m1_candidates.png",
	"res://tests/visual_reviews/official_intrusion_boss_m1_retainers.png",
	"res://tests/visual_reviews/official_intrusion_boss_m1_monochrome.png",
	"res://tests/visual_reviews/official_intrusion_boss_m1_density.png",
]
const CANDIDATES := [
	{"id": "partason", "label": "PARTASON", "cue": "HORN · SWORD + SHIELD", "path": "res://assets/graphics/candidate_intrusion_sd/partason.png", "color": "c9a75d"},
	{"id": "jiane", "label": "JIANE", "cue": "HORN · BARBED HEART", "path": "res://assets/graphics/candidate_intrusion_sd/jiane.png", "color": "d83a91"},
	{"id": "kasuha", "label": "KASUHA", "cue": "TENTACLE EYE · ORB", "path": "res://assets/graphics/candidate_intrusion_sd/kasuha.png", "color": "50b84a"},
	{"id": "irelai", "label": "IRELAI", "cue": "THREE SKULLS · DEATH WAVE", "path": "res://assets/graphics/candidate_intrusion_sd/irelai.png", "color": "80d9f5"},
	{"id": "judaginda", "label": "JUDAGINDA", "cue": "SCYTHE · BLOOD ARC", "path": "res://assets/graphics/candidate_intrusion_sd/judaginda.png", "color": "d4444a"},
]
const RETAINERS := [
	{"id": "kanda", "label": "KANDA", "cue": "ONE GREAT-SWORD", "path": "res://assets/graphics/retainer_intrusion_sd/kanda.png", "color": "c9a75d"},
	{"id": "given", "label": "GIVEN", "cue": "RABBIT EARS · WHIP", "path": "res://assets/graphics/retainer_intrusion_sd/given.png", "color": "d83a91"},
	{"id": "jeomujeom", "label": "JEOMUJEOM", "cue": "FIVE EYES · TWO HANDS", "path": "res://assets/graphics/retainer_intrusion_sd/jeomujeom.png", "color": "50b84a"},
	{"id": "jugdied", "label": "JUGDIED", "cue": "ONE RIDER + HORSE", "path": "res://assets/graphics/retainer_intrusion_sd/jugdied.png", "color": "80d9f5"},
	{"id": "death_vanguard", "label": "DEATH VANGUARD", "cue": "ONE RIDER + THREE ATTACKERS", "path": "res://assets/graphics/retainer_intrusion_sd/death_vanguard.png", "color": "d4444a"},
]

func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var page_index := 3 if user_args.has("--page-d") else (2 if user_args.has("--page-c") else (1 if user_args.has("--page-b") else 0))
	match page_index:
		0: _build_candidate_page()
		1: _build_retainer_page()
		2: _build_monochrome_page()
		3: _build_density_page()
	if user_args.has("--capture-and-quit"):
		_capture_and_quit.call_deferred(OUTPUTS[page_index])

func _build_candidate_page() -> void:
	var page := _base_page(
		"OFFICIAL INTRUSION M1 · ACTIVE CANDIDATE FINAL BOSSES",
		"Five active candidate_intrusion_sd assets · actual final-boss body size 224px · 64px monochrome identity check"
	)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 8)
	page.add_child(columns)
	for entry_value in CANDIDATES:
		var entry := entry_value as Dictionary
		var panel := _panel(Color(String(entry.color)), 224.0)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override(&"separation", 4)
		panel.add_child(stack)
		stack.add_child(_label(String(entry.label), Color("f7f2e7"), 15))
		stack.add_child(_label(String(entry.cue), Color("72d6bd"), 9))
		stack.add_child(_texture_box(String(entry.path), 224))
		stack.add_child(_label("FINAL BODY · 224px", Color("f0d58a"), 9))
		stack.add_child(_texture_box(String(entry.path), 64, true))
		stack.add_child(_label("MONO · 64px", Color("aeb8cf"), 9))
		columns.add_child(panel)

func _build_retainer_page() -> void:
	var page := _base_page(
		"OFFICIAL INTRUSION M1 · ACTIVE RETAINER BOSSES",
		"Five active retainer_intrusion_sd assets · exact Tier 1/2/3 body envelopes · no per-tier bitmap variants"
	)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 8)
	page.add_child(columns)
	for entry_value in RETAINERS:
		var entry := entry_value as Dictionary
		var panel := _panel(Color(String(entry.color)), 210.0)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override(&"separation", 1)
		panel.add_child(stack)
		stack.add_child(_label(String(entry.label), Color("f7f2e7"), 14))
		stack.add_child(_label(String(entry.cue), Color("72d6bd"), 8))
		for target_size in [158, 190, 210]:
			stack.add_child(_texture_box(String(entry.path), target_size))
			stack.add_child(_label("TIER %d · %dpx" % [[158, 190, 210].find(target_size) + 1, target_size], Color("aeb8cf"), 8))
		columns.add_child(panel)

func _build_monochrome_page() -> void:
	var page := _base_page(
		"OFFICIAL INTRUSION M1 · COLOR-INDEPENDENT SILHOUETTES",
		"Active pixels converted to neutral luminance · 128px · identity must survive without faction hue or UI emblem"
	)
	page.add_child(_monochrome_row("CANDIDATE · FINAL", CANDIDATES))
	page.add_child(_monochrome_row("RETAINER · MID-BOSS", RETAINERS))

func _monochrome_row(title: String, entries: Array) -> Control:
	var group := VBoxContainer.new()
	group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	group.add_theme_constant_override(&"separation", 4)
	group.add_child(_label(title, Color("f0d58a"), 12))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override(&"separation", 8)
	group.add_child(row)
	for entry_value in entries:
		var entry := entry_value as Dictionary
		var panel := _panel(Color("758097"), 224.0)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override(&"separation", 3)
		panel.add_child(stack)
		stack.add_child(_texture_box(String(entry.path), 128, true))
		stack.add_child(_label(String(entry.label), Color("f7f2e7"), 11))
		stack.add_child(_label(String(entry.cue), Color("aeb8cf"), 8))
		row.add_child(panel)
	return group

func _build_density_page() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = ConceptService.texture(&"battlefield_background")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(background)
	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.035, 0.025, 0.07, 0.28)
	add_child(wash)

	_add_absolute_panel(Rect2(18, 14, 1244, 78), Color("151020e8"), Color("c9a75d"))
	_add_absolute_label(Rect2(40, 22, 1200, 26), "OFFICIAL INTRUSION M1 · FOUR-SLOT BATTLEFIELD DENSITY", Color("f0d58a"), 18)
	_add_absolute_label(Rect2(40, 52, 1200, 22), "T1 158px · T2 190px · T3 210px · FINAL 224px · active hostile art + faction frames", Color("d7dce8"), 11)

	_add_absolute_panel(Rect2(166, 104, 720, 52), Color("151020df"), Color("d83a91"))
	_add_absolute_label(Rect2(184, 111, 684, 20), "BOSS HEALTH · GIVEN · TEMPTATION FRONT", Color("f7f2e7"), 12)
	var health_back := ColorRect.new()
	health_back.position = Vector2(184, 135)
	health_back.size = Vector2(684, 9)
	health_back.color = Color("392840")
	add_child(health_back)
	var health_fill := ColorRect.new()
	health_fill.position = Vector2(184, 135)
	health_fill.size = Vector2(498, 9)
	health_fill.color = Color("d83a91")
	add_child(health_fill)

	_add_absolute_panel(Rect2(916, 104, 346, 82), Color("151020ef"), Color("d4444a"))
	_add_absolute_label(Rect2(932, 113, 314, 20), "FINAL WARNING · 00:30", Color("f0d58a"), 11)
	_add_absolute_label(Rect2(932, 139, 314, 34), "KASUHA · ABYSS FACTION\nY74 OFFICIAL INTRUSION", Color("f07b72"), 12)

	var lineup := [
		{"entry": RETAINERS[0], "time": "02:30", "role": "T1 RETAINER", "size": 158, "center": Vector2(265, 350)},
		{"entry": RETAINERS[1], "time": "05:00", "role": "T2 RETAINER", "size": 190, "center": Vector2(500, 350)},
		{"entry": RETAINERS[3], "time": "07:30", "role": "T3 RETAINER", "size": 210, "center": Vector2(750, 350)},
		{"entry": CANDIDATES[2], "time": "10:00", "role": "FINAL CANDIDATE", "size": 224, "center": Vector2(1030, 350)},
	]
	for value in lineup:
		var slot := value as Dictionary
		var entry := slot.entry as Dictionary
		var target_size := int(slot.size)
		var center := slot.center as Vector2
		var color := Color(String(entry.color))
		_add_absolute_panel(Rect2(center - Vector2(target_size, target_size) * 0.5 - Vector2(5, 5), Vector2(target_size + 10, target_size + 10)), Color(0.02, 0.025, 0.06, 0.62), color)
		var art := _texture_box(String(entry.path), target_size)
		art.position = center - Vector2(target_size, target_size) * 0.5
		art.size = Vector2(target_size, target_size)
		add_child(art)
		_add_absolute_label(Rect2(center.x - 110, 205, 220, 38), "%s · %s" % [slot.time, slot.role], color.lightened(0.24), 11)
		_add_absolute_label(Rect2(center.x - 110, 474, 220, 42), "%s\n%s" % [entry.label, entry.cue], Color("f7f2e7"), 10)

	_add_absolute_panel(Rect2(166, 544, 1096, 78), Color("151020e8"), Color("758097"))
	_add_absolute_label(Rect2(188, 555, 1052, 24), "READABILITY GATE · LEFT-FACING BODY · UNIQUE CHARACTER COUNT · WEAPON / GROUP SILHOUETTE", Color("f0d58a"), 11)
	_add_absolute_label(Rect2(188, 584, 1052, 24), "Fixture is a valid four-rival role mix; presentation identity is independent from mechanic boss_id.", Color("d7dce8"), 10)

func _base_page(title: String, subtitle: String) -> VBoxContainer:
	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_right", 18)
	margin.add_theme_constant_override(&"margin_bottom", 12)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 4)
	margin.add_child(page)
	page.add_child(_label(title, Color("f0d58a"), 20))
	page.add_child(_label(subtitle, Color("aeb8cf"), 11))
	return page

func _panel(accent: Color, minimum_width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minimum_width
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color(accent, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 5
	style.content_margin_top = 5
	style.content_margin_right = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override(&"panel", style)
	return panel

func _texture_box(path: String, target_size: int, monochrome: bool = false) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(target_size, target_size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var source := load(path) as Texture2D
	rect.texture = _monochrome_texture(source, target_size) if monochrome else source
	return rect

func _monochrome_texture(source: Texture2D, target_size: int) -> Texture2D:
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.convert(Image.FORMAT_RGBA8)
	image.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var luminance := pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			image.set_pixel(x, y, Color(luminance, luminance, luminance, pixel.a))
	return ImageTexture.create_from_image(image)

func _add_absolute_panel(rect: Rect2, fill: Color, border: Color) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override(&"panel", style)
	add_child(panel)

func _add_absolute_label(rect: Rect2, value: String, color: Color, font_size: int) -> void:
	var label := _label(value, color, font_size)
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

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
		print("OFFICIAL INTRUSION M1 REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("official intrusion M1 review capture failed with error %d" % error)
	get_tree().quit(error)
