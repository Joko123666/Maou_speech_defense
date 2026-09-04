extends Control

const REVIEW_OUTPUT := "res://tests/visual_reviews/character_style_refresh_m3_kanda.png"
const CURRENT_PORTRAIT := "res://assets/graphics/retainers/kanda.png"
const CURRENT_SD := "res://assets/graphics/combat_sd/retainers/kanda.png"
const STAGED_PORTRAIT := "res://assets/graphics/style_refresh_v019/retainers/kanda.png"
const STAGED_SD := "res://assets/graphics/style_refresh_v019/retainer_sd/kanda.png"

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
	margin.add_theme_constant_override(&"margin_left", 24)
	margin.add_theme_constant_override(&"margin_top", 15)
	margin.add_theme_constant_override(&"margin_right", 24)
	margin.add_theme_constant_override(&"margin_bottom", 15)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 7)
	margin.add_child(page)
	var title := _label("v0.19 KANDA M3-B — PORTRAIT · COMBAT SD · 96/64/48 PX", Color("f0d58a"), 21)
	page.add_child(title)
	page.add_child(_label("Identity-pair review only. The staged pair is not referenced by the active catalog.", Color("aeb8cf"), 13))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 12)
	page.add_child(columns)
	columns.add_child(_build_pair_panel("CURRENT", CURRENT_PORTRAIT, CURRENT_SD, Color("8f9ab2")))
	columns.add_child(_build_pair_panel("STAGED / APPROVAL CANDIDATE", STAGED_PORTRAIT, STAGED_SD, Color("f0d58a")))

	var readability := _review_panel(Vector2(0, 138))
	page.add_child(readability)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 3)
	readability.add_child(stack)
	stack.add_child(_label("STAGED PAIR READABILITY — HORNS · LEFT SCAR · IRON ARMOR · ONE GREATSWORD", Color("72d6bd"), 11))
	var sizes := HBoxContainer.new()
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override(&"separation", 26)
	stack.add_child(sizes)
	for target_size in [96, 64, 48]:
		var sample := VBoxContainer.new()
		sample.alignment = BoxContainer.ALIGNMENT_CENTER
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override(&"separation", 5)
		pair.add_child(_texture_box(STAGED_PORTRAIT, Vector2(target_size, target_size)))
		pair.add_child(_texture_box(STAGED_SD, Vector2(target_size, target_size)))
		sample.add_child(pair)
		sample.add_child(_label("%dpx PORTRAIT / SD" % target_size, Color("aeb8cf"), 9))
		sizes.add_child(sample)

func _build_pair_panel(caption: String, portrait_path: String, sd_path: String, accent: Color) -> Control:
	var panel := _review_panel(Vector2(610, 0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 4)
	panel.add_child(stack)
	stack.add_child(_label(caption, accent, 14))
	var pair := HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override(&"separation", 18)
	stack.add_child(pair)
	pair.add_child(_asset_sample("PORTRAIT", portrait_path))
	pair.add_child(_asset_sample("COMBAT SD", sd_path))
	return panel

func _asset_sample(caption: String, path: String) -> Control:
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(_label(caption, Color("aeb8cf"), 10))
	stack.add_child(_texture_box(path, Vector2(270, 360)))
	return stack

func _review_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
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
	return panel

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

func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(REVIEW_OUTPUT))
	if error == OK:
		print("CHARACTER M3 KANDA REVIEW CAPTURE PASS: %s" % REVIEW_OUTPUT)
	else:
		push_error("character M3 Kanda review capture failed with error %d" % error)
	get_tree().quit(error)
