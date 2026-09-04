extends Control

const OUTPUTS := [
	"res://tests/visual_reviews/official_intrusion_boss_m2_guard_pairs.png",
	"res://tests/visual_reviews/official_intrusion_boss_m2_guard_sizes.png",
]
const GUARDS := [
	{"faction": "PARTASON", "guard": "EMERALD GUARDIAN", "cue": "SHIELD-FIRST LEFT CHARGE", "source": "res://assets/graphics/towers/emerald_guardian.png", "target": "res://assets/graphics/guard_intrusion_sd/partason_faction.png", "color": "c9a75d"},
	{"faction": "JIANE", "guard": "SAPPHIRE LANCE", "cue": "HEART GLAIVE LEFT THRUST", "source": "res://assets/graphics/towers/sapphire_lance.png", "target": "res://assets/graphics/guard_intrusion_sd/jiane_faction.png", "color": "d83a91"},
	{"faction": "KASUHA", "guard": "AMETHYST NOVA", "cue": "THREE EYES · SPIRAL PULSE", "source": "res://assets/graphics/towers/amethyst_nova.png", "target": "res://assets/graphics/guard_intrusion_sd/kasuha_faction.png", "color": "50b84a"},
	{"faction": "IRELAI", "guard": "JADE ROULETTE", "cue": "BONE HALBERD · TWO FLAMES", "source": "res://assets/graphics/towers/jade_roulette.png", "target": "res://assets/graphics/guard_intrusion_sd/irelai_faction.png", "color": "80d9f5"},
	{"faction": "JUDAGINDA", "guard": "OBSIDIAN VERDICT", "cue": "HEAVY SCYTHE LEFT CLEAVE", "source": "res://assets/graphics/towers/obsidian_verdict.png", "target": "res://assets/graphics/guard_intrusion_sd/judaginda_faction.png", "color": "d4444a"},
]

func _ready() -> void:
	var page_index := 1 if OS.get_cmdline_user_args().has("--page-b") else 0
	if page_index == 0:
		_build_identity_pairs()
	else:
		_build_size_gate()
	if OS.get_cmdline_user_args().has("--capture-and-quit"):
		_capture_and_quit.call_deferred(OUTPUTS[page_index])

func _build_identity_pairs() -> void:
	var page := _base_page(
		"OFFICIAL INTRUSION M2 · ACTIVE GUARD IDENTITY PAIRS",
		"Player guard identity → dedicated left-facing hostile commander · five factions · active catalog paths"
	)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 8)
	page.add_child(columns)
	for entry_value in GUARDS:
		var entry := entry_value as Dictionary
		var panel := _panel(Color(String(entry.color)))
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override(&"separation", 4)
		panel.add_child(stack)
		stack.add_child(_label(String(entry.faction), Color("f7f2e7"), 14))
		stack.add_child(_label(String(entry.guard), Color("aeb8cf"), 9))
		stack.add_child(_texture_box(String(entry.source), 116))
		stack.add_child(_label("ALLY · RIGHT", Color("8f9ab2"), 8))
		stack.add_child(_texture_box(String(entry.target), 210))
		stack.add_child(_label("GUARD BOSS · LEFT", Color("f0d58a"), 9))
		stack.add_child(_label(String(entry.cue), Color("72d6bd"), 8))
		columns.add_child(panel)

func _build_size_gate() -> void:
	var page := _base_page(
		"OFFICIAL INTRUSION M2 · GUARD SIZE READABILITY",
		"1254px RGBA · 7% safe margin · 512px import cap · boss stress 220px + UI silhouettes 96 / 64 / 48px"
	)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 8)
	page.add_child(columns)
	for entry_value in GUARDS:
		var entry := entry_value as Dictionary
		var panel := _panel(Color(String(entry.color)))
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override(&"separation", 5)
		panel.add_child(stack)
		stack.add_child(_label(String(entry.faction), Color("f7f2e7"), 14))
		stack.add_child(_label(String(entry.cue), Color("72d6bd"), 8))
		stack.add_child(_texture_box(String(entry.target), 220))
		stack.add_child(_label("BOSS BODY · 220px", Color("f0d58a"), 8))
		var sizes := HBoxContainer.new()
		sizes.alignment = BoxContainer.ALIGNMENT_CENTER
		sizes.add_theme_constant_override(&"separation", 6)
		for target_size in [96, 64, 48]:
			var sample := VBoxContainer.new()
			sample.alignment = BoxContainer.ALIGNMENT_CENTER
			sample.add_child(_label("%d" % target_size, Color("8f9ab2"), 8))
			sample.add_child(_texture_box(String(entry.target), target_size))
			sizes.add_child(sample)
		stack.add_child(sizes)
		columns.add_child(panel)

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
	page.add_theme_constant_override(&"separation", 5)
	margin.add_child(page)
	page.add_child(_label(title, Color("f0d58a"), 20))
	page.add_child(_label(subtitle, Color("aeb8cf"), 11))
	return page

func _panel(accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 235
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color(accent, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override(&"panel", style)
	return panel

func _texture_box(path: String, target_size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(target_size, target_size)
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
	var error := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("OFFICIAL INTRUSION M2 GUARD REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("official intrusion M2 guard review capture failed with error %d" % error)
	get_tree().quit(error)
