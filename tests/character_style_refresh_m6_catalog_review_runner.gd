extends Control

const OUTPUTS := [
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_defenders.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_candidates.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_retainers.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_guards.png",
]
const DEFENDER_IDS := [&"rapid", &"area", &"pierce", &"slow", &"knockback", &"execute", &"mark", &"chain", &"rubber_golem"]
const CANDIDATE_IDS := [&"partason", &"jiane", &"kasuha", &"irelai", &"judaginda"]
const RETAINER_IDS := [&"kanda", &"given", &"jeomujeom", &"jugdied", &"death_vanguard"]
const GUARD_IDS := [&"emerald_guardian", &"sapphire_lance", &"amethyst_nova", &"jade_roulette", &"obsidian_verdict", &"obsidian_inquisitor"]

var review_catalog: GameAssetCatalogData

func _ready() -> void:
	review_catalog = CharacterStyleRefreshM6ReviewCatalog.build()
	var user_args := OS.get_cmdline_user_args()
	var page_index := 3 if user_args.has("--page-guards") else (2 if user_args.has("--page-retainers") else (1 if user_args.has("--page-candidates") else 0))
	_build_page(page_index)
	if user_args.has("--capture-and-quit"):
		_capture_and_quit.call_deferred(OUTPUTS[page_index])

func _build_page(page_index: int) -> void:
	var background := ColorRect.new()
	background.color = Color("111725")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 6)
	margin.add_child(page)
	var titles := ["NORMAL DEFENDER PAIRS", "CANDIDATE PORTRAIT · ALLY → · INTRUSION ←", "RETAINER PORTRAIT · ALLY → · INTRUSION ←", "UNIQUE GUARD SILHOUETTES"]
	page.add_child(_label("v0.19 CHARACTER CATALOG M6 / %s" % titles[page_index], Color("f0d58a"), 21))
	page.add_child(_label("Review-catalog textures are the 512px runtime imports built from approved 1254px transparent masters.", Color("aeb8cf"), 12))
	if review_catalog == null:
		page.add_child(_label("REVIEW CATALOG FAILED TO LOAD", Color("ff6b6b"), 20))
		return
	match page_index:
		0:
			page.add_child(_defender_grid())
		1:
			page.add_child(_character_columns(CANDIDATE_IDS, &"candidates", &"candidate_sd", &"candidate_intrusion_sd"))
		2:
			page.add_child(_character_columns(RETAINER_IDS, &"retainers", &"retainer_sd", &"retainer_intrusion_sd"))
		3:
			page.add_child(_guard_columns())

func _defender_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 8)
	for content_id in DEFENDER_IDS:
		var panel := _panel(Vector2(405, 176))
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override(&"separation", 10)
		panel.add_child(row)
		row.add_child(_asset_stack(String(content_id).to_upper(), _texture(&"defenders", content_id), 116, Color("f7f2e7")))
		row.add_child(_asset_stack("FACE", _texture(&"defender_icons", content_id), 82, Color("72d6bd")))
		row.add_child(_asset_stack("48PX", _texture(&"defenders", content_id), 48, Color("aeb8cf")))
		grid.add_child(panel)
	return grid

func _character_columns(ids: Array, portrait_category: StringName, ally_category: StringName, intrusion_category: StringName) -> Control:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 8)
	for content_id in ids:
		var panel := _panel(Vector2(240, 0))
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override(&"separation", 3)
		panel.add_child(stack)
		stack.add_child(_label(String(content_id).replace("_", " ").to_upper(), Color("f7f2e7"), 14))
		stack.add_child(_texture_rect(_texture(portrait_category, content_id), 178))
		var pair := HBoxContainer.new()
		pair.alignment = BoxContainer.ALIGNMENT_CENTER
		pair.add_theme_constant_override(&"separation", 8)
		pair.add_child(_asset_stack("ALLY →", _texture(ally_category, content_id), 96, Color("72d6bd")))
		pair.add_child(_asset_stack("ENEMY ←", _texture(intrusion_category, content_id), 96, Color("f0d58a")))
		stack.add_child(pair)
		var small := HBoxContainer.new()
		small.alignment = BoxContainer.ALIGNMENT_CENTER
		small.add_theme_constant_override(&"separation", 20)
		small.add_child(_asset_stack("48PX ALLY", _texture(ally_category, content_id), 48, Color("8f9ab2")))
		small.add_child(_asset_stack("48PX ENEMY", _texture(intrusion_category, content_id), 48, Color("8f9ab2")))
		stack.add_child(small)
		columns.add_child(panel)
	return columns

func _guard_columns() -> Control:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 7)
	for content_id in GUARD_IDS:
		var panel := _panel(Vector2(195, 0))
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override(&"separation", 5)
		panel.add_child(stack)
		stack.add_child(_label(String(content_id).replace("_", " ").to_upper(), Color("f7f2e7"), 12))
		stack.add_child(_texture_rect(_texture(&"towers", content_id), 168))
		stack.add_child(_label("PLAYER-FACING →", Color("72d6bd"), 10))
		var sizes := HBoxContainer.new()
		sizes.alignment = BoxContainer.ALIGNMENT_CENTER
		sizes.add_theme_constant_override(&"separation", 12)
		sizes.add_child(_asset_stack("96PX", _texture(&"towers", content_id), 96, Color("aeb8cf")))
		sizes.add_child(_asset_stack("48PX", _texture(&"towers", content_id), 48, Color("aeb8cf")))
		stack.add_child(sizes)
		columns.add_child(panel)
	return columns

func _panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2435")
	style.border_color = Color("394762")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(7)
	panel.add_theme_stylebox_override(&"panel", style)
	return panel

func _asset_stack(title: String, texture: Texture2D, size: int, color: Color) -> Control:
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_label(title, color, 9))
	stack.add_child(_texture_rect(texture, size))
	return stack

func _texture_rect(texture: Texture2D, target_size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(target_size, target_size)
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect

func _texture(category: StringName, content_id: StringName) -> Texture2D:
	return review_catalog.content_texture_override(category, content_id) if review_catalog != null else null

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
		print("CHARACTER M6 CATALOG REVIEW CAPTURE PASS: %s" % output_path)
	else:
		push_error("character M6 catalog review capture failed with error %d" % error)
	get_tree().quit(error)
