extends Control

const OUTPUT_PATH := "res://tests/visual_reviews/character_style_refresh_m5_faction_tokens.png"

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
		margin.add_theme_constant_override(side, 18)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 8)
	margin.add_child(page)
	page.add_child(_label("v0.19 FACTION TOKEN MIGRATION M5 — EMBLEM · MARKER · PALETTE · UI SURFACES", Color("f0d58a"), 21))
	page.add_child(_label("Color and grayscale markers must stay distinct. Legacy crown/star/abyss/spirit/judgment resolve only as compatibility aliases.", Color("aeb8cf"), 13))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 9)
	page.add_child(columns)
	var campaign := ConceptService.get_election_campaign()
	if campaign == null:
		return
	for faction in campaign.factions:
		columns.add_child(_faction_panel(faction))

func _faction_panel(faction: ElectionFactionData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(236.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = faction.accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10.0
	style.content_margin_top = 10.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override(&"panel", style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 7)
	panel.add_child(stack)
	stack.add_child(_label(faction.display_name, Color("f7f2e7"), 17))
	stack.add_child(_label(faction.marker_display_name().to_upper(), faction.accent_color, 12))
	var emblem := TextureRect.new()
	emblem.custom_minimum_size = Vector2(112.0, 112.0)
	emblem.texture = ConceptService.content_texture(&"emblems", faction.emblem_id)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(emblem)
	var marker_row := HBoxContainer.new()
	marker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	marker_row.add_theme_constant_override(&"separation", 20)
	marker_row.add_child(_marker_sample("COLOR", faction.marker_style, faction.primary_color, faction.secondary_color))
	marker_row.add_child(_marker_sample("GRAY", faction.marker_style, Color("d6d6d6"), Color("777777")))
	stack.add_child(marker_row)
	var swatches := HBoxContainer.new()
	swatches.alignment = BoxContainer.ALIGNMENT_CENTER
	swatches.add_theme_constant_override(&"separation", 6)
	for color in [faction.primary_color, faction.secondary_color, faction.accent_color]:
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(48.0, 18.0)
		swatch.color = color
		swatches.add_child(swatch)
	stack.add_child(swatches)
	stack.add_child(_label("SELECT · PRELUDE · BOSS", Color("aeb8cf"), 10))
	stack.add_child(_label("CODEX · RESULT · GUARD CELL", Color("aeb8cf"), 10))
	stack.add_child(_label("ACTIVE  %s\nLEGACY  %s" % [String(faction.marker_style), _legacy_marker(faction.marker_style)], Color("78869f"), 9))
	return panel

func _marker_sample(title: String, style: StringName, primary: Color, secondary: Color) -> Control:
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	var marker := FactionMarkerIcon.new()
	marker.custom_minimum_size = Vector2(72.0, 72.0)
	marker.configure(style, primary, secondary)
	stack.add_child(marker)
	stack.add_child(_label(title, Color("8f9ab2"), 9))
	return stack

func _legacy_marker(active_style: StringName) -> String:
	for legacy_style in ElectionFactionData.LEGACY_MARKER_ALIASES:
		if ElectionFactionData.LEGACY_MARKER_ALIASES[legacy_style] == active_style:
			return String(legacy_style)
	return "none"

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
		print("CHARACTER M5 FACTION TOKEN REVIEW CAPTURE PASS: %s" % OUTPUT_PATH)
	else:
		push_error("character M5 faction token review capture failed with error %d" % error)
	get_tree().quit(error)
