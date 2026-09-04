class_name UiUxM2ChoiceCardContractTest
extends RefCounted

const FLAT_EFFECT_ICON_ATLAS_PATH := "res://assets/graphics/ui/flat_effect_icon_atlas_v019.png"
const REQUIRED_FLAT_ICON_KEYS: Array[StringName] = [
	&"damage", &"speed", &"area", &"health", &"control",
	&"tower", &"core", &"cursor", &"formation", &"global",
	&"poison", &"burn", &"bleed", &"shock", &"mark",
	&"experience", &"warning", &"return", &"overheat", &"guidance", &"mark_amp",
]

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	var atlas_image := Image.load_from_file(ProjectSettings.globalize_path(FLAT_EFFECT_ICON_ATLAS_PATH))
	_expect(not atlas_image.is_empty() and atlas_image.get_width() == atlas_image.get_height() and atlas_image.get_width() >= 1024 and atlas_image.get_format() == Image.FORMAT_RGBA8, "flat infographic icons must use one high-resolution square RGBA atlas", failures)
	var transparent_corners := atlas_image.get_pixel(0, 0).a <= 0.01 and atlas_image.get_pixel(atlas_image.get_width() - 1, 0).a <= 0.01 and atlas_image.get_pixel(0, atlas_image.get_height() - 1).a <= 0.01 and atlas_image.get_pixel(atlas_image.get_width() - 1, atlas_image.get_height() - 1).a <= 0.01
	_expect(transparent_corners, "flat infographic icon atlas must retain transparent corner gutters", failures)
	_expect(FlatEffectIcon.ATLAS_GRID_SIZE == Vector2i(5, 5), "flat infographic icon atlas must retain the fixed 5x5 cell contract", failures)
	var occupied_cells: Dictionary = {}
	for icon_key in REQUIRED_FLAT_ICON_KEYS:
		var cell: Vector2i = FlatEffectIcon.ATLAS_CELLS.get(icon_key, Vector2i(-1, -1))
		_expect(cell.x >= 0 and cell.y >= 0 and cell.x < 5 and cell.y < 5, "flat infographic icon '%s' must map to an atlas cell" % icon_key, failures)
		occupied_cells[cell] = true
	_expect(occupied_cells.size() == REQUIRED_FLAT_ICON_KEYS.size(), "every active flat infographic semantic must use a distinct atlas cell", failures)
	var panel := (load("res://scenes/ui/level_up_panel.tscn") as PackedScene).instantiate() as LevelUpPanel
	root.add_child(panel)
	var artifact_catalog := load(ArtifactEffectResolver.CATALOG_PATH) as ArtifactCatalogData
	var artifact_choice := ArtifactOfferService.build_choice(artifact_catalog.find_artifact(&"blood_prism"))
	var choices: Array[UpgradeData] = [
		artifact_choice,
		UpgradeData.new().configure(&"status_upgrade", "화상 Lv.4 특화", "공격 기반 지속 피해를 강화합니다.\n수치 변화 · 피해 ×1.20 → ×1.35", &"burn"),
		UpgradeData.new().configure(&"tower_type_level", "고블린 창병 전체 Lv.3", "같은 종류의 모든 병력을 강화합니다.\n수치 변화 · 위력 ×1.10 → ×1.18", &"rapid"),
	]
	panel.show_choices(choices, 16, 2, 3)
	_expect(panel.buttons.all(func(button: UiChoiceCard) -> bool: return button.disabled and button.selection_label.text == "잠김"), "M2 cards must retain the reveal-time input lock", failures)
	panel.complete_card_reveal()
	_expect(panel.buttons.all(func(button: UiChoiceCard) -> bool: return not button.disabled and button.focus_mode == Control.FOCUS_ALL), "M2 cards must unlock as keyboard/touch focus targets after reveal", failures)
	for index in panel.buttons.size():
		var card := panel.buttons[index]
		var presentation := panel._category_presentation(choices[index].category)
		var badge := String(presentation.badge).trim_prefix("[").trim_suffix("]")
		_expect(card.eyebrow_label.text == badge and not card.eyebrow_label.text.begins_with("%d" % (index + 1)), "M2 card headers must expose category without repeating the 1/2/3 choice index", failures)
		_expect(card.title_label.text == choices[index].display_name and not card.effect_label.text.is_empty(), "M2 cards must separate title and core effect", failures)
		_expect(card.tags_container.get_child_count() > 0 and card.selection_label.text == "[%d] 선택" % (index + 1), "M2 cards must expose semantic tags and one full-card selection affordance", failures)
		_expect(card.header_panel.custom_minimum_size.y == 132.0 and card.icon_frame.custom_minimum_size == Vector2(52.0, 52.0) and card.effect_label.custom_minimum_size.y == 44.0 and card.description_label.custom_minimum_size.y == 32.0, "level-up cards must share fixed priority header, centered icon, compact change, and application geometry", failures)
		_expect(card.eyebrow_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and card.title_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and card.description_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and card.effect_label.text.begins_with("[center]"), "all card copy and the icon-title stack must follow one centered reading axis", failures)
		_expect(card.get_node_or_null("ContentMargin/Layout/EffectCaption") == null and card.get_node_or_null("ContentMargin/Layout/VisualCaption") == null and card.get_node_or_null("ContentMargin/Layout/DescriptionCaption") == null and card.change_panel != null and card.description_panel != null, "content groups must use surfaces and spacing instead of repeated text subheadings", failures)
		var header_style := card.header_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
		var selection_style := card.selection_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
		_expect(header_style != null and selection_style != null and header_style.bg_color == selection_style.bg_color and UiTokens.contrast_ratio(UiTokens.SURFACE_PARCHMENT, header_style.bg_color) >= 4.5, "the dark title block and opposite bottom selection block must share a strong, readable card frame", failures)
		_expect(card.detail_rail.custom_minimum_size.y == 48.0 and card.selection_panel.custom_minimum_size.y == 52.0 and card.selection_panel.get_index() > card.detail_rail.get_index(), "the compact details rail must sit directly above the full-width bottom selection affordance", failures)
		_expect(card.find_children("*", "Button", true, false).is_empty(), "M2 ChoiceCard content must not contain nested interactive buttons", failures)
	_expect(panel.buttons[0].effect_label.text.contains("위력 증가") and panel.buttons[0].effect_label.text.contains("범위 감소") and not panel.buttons[0].effect_label.text.contains("35") and not panel.buttons[0].effect_label.text.contains("20"), "artifact cards must summarize only benefit and trade-off directions outside details", failures)
	_expect(panel.buttons[0].description_label.text.contains("이득과 손해"), "artifact cards must disclose their trade-off without repeating exact values", failures)
	_expect(panel.buttons[2].icon_rect.visible and panel.buttons[2].icon_rect.texture != null, "tower cards must use the registered defender icon in the primary visual layer", failures)
	_expect(panel.buttons[0].fallback_icon.visible and panel.buttons[1].fallback_icon.visible and panel.detail_buttons.all(func(button: Button) -> bool: return button.visible and button.anchor_left == 0.5 and button.anchor_right == 0.5 and button.anchor_top == 1.0 and button.anchor_bottom == 1.0 and button.offset_bottom == -68.0), "cards without character art must retain a fixed flat infographic header icon and every compact details action must align above the bottom selection affordance", failures)
	_expect(panel.buttons[1].effect_label.text.contains("화상 피해·지속 강화") and not panel.buttons[1].effect_label.text.contains("1.20") and not panel.buttons[1].tooltip_text.contains("1.20"), "status card surfaces and tooltips must omit exact transition values while naming the actual changed role", failures)
	var artifact_body_impacts := panel._choice_body_impacts(choices[0])
	var status_body_impacts := panel._choice_body_impacts(choices[1])
	_expect(artifact_body_impacts.size() == 1 and StringName(artifact_body_impacts[0].icon) != panel._choice_header_icon_key(choices[0]), "artifact bodies must omit the impact icon already promoted into the title header", failures)
	_expect(status_body_impacts.size() == 1 and String(status_body_impacts[0].label) != "화상" and StringName(status_body_impacts[0].icon) != panel._choice_header_icon_key(choices[1]), "status bodies must omit both the header icon and the status icon already named by the title", failures)
	for choice_index in choices.size():
		var preview_slots := panel.formation_previews[choice_index].get_children()
		var filtered_impacts := panel._choice_body_impacts(choices[choice_index])
		_expect(preview_slots.size() == filtered_impacts.size(), "body preview slots must exactly follow the de-duplicated impact list", failures)
		var seen_preview_keys: Dictionary = {}
		for preview_slot_value in preview_slots:
			var preview_slot := preview_slot_value as Control
			var preview_key := StringName(preview_slot.get_meta(&"impact_icon_key", &""))
			_expect(preview_key != &"" and not seen_preview_keys.has(preview_key), "body preview icons must not repeat a semantic icon key", failures)
			seen_preview_keys[preview_key] = true
	_expect(panel.reroll_button.visible and panel.reroll_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN, "normal choice screens must retain a touch-sized reroll action", failures)
	panel._show_choice_details(1)
	_expect(panel.details_open and panel.details_summary.text.contains("피해 ×1.20 → ×1.35") and panel.details_shape_preview.get_child_count() == panel._choice_impacts(choices[1]).size(), "details must preserve the complete original description and full impact icon set", failures)
	panel._close_formation_details()

	var formation_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"new_formation", "표준 사격진", "2칸 기본 편대를 설치합니다.", &"balanced"),
		UpgradeData.new().configure(&"new_formation", "중앙 유도형", "3칸 유도 편대를 설치합니다.", &"guidance"),
		UpgradeData.new().configure(&"new_formation", "집중 포격형", "3칸 포격 편대를 설치합니다.", &"barrage"),
	]
	panel.show_subchoices(formation_choices, "병력 세트", 4, true)
	panel.complete_card_reveal()
	_expect(panel.detail_buttons.all(func(button: Button) -> bool: return button.visible and button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN), "formation cards must retain separate touch-sized detail actions", failures)
	for index in panel.buttons.size():
		_expect(panel.detail_buttons[index].get_parent() == panel.buttons[index].get_parent() and panel.detail_buttons[index].get_parent() != panel.buttons[index], "formation detail actions must be siblings rather than nested card buttons", failures)
		_expect(not panel.formation_previews[index].find_children("*", "GridContainer", true, false).is_empty(), "formation cards must render their mini-board in the shared visual host", failures)
	panel._show_formation_details(0)
	_expect(panel.details_open and panel.details_summary.text.contains("기초 편성점수"), "M2 migration must preserve the existing formation detail overlay", failures)
	panel._close_formation_details()

	var dense_description := "Lv.4 수치 · 위력 1  /  속도 2  /  범위 3  /  관통 4  /  연쇄 5  /  지속 6  /  치명 7  /  공명 8"
	var dense_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"status_upgrade", "밀도 특화 A", dense_description, &"burn"),
		UpgradeData.new().configure(&"status_upgrade", "밀도 특화 B", dense_description, &"burn"),
		UpgradeData.new().configure(&"status_upgrade", "밀도 특화 C", dense_description, &"burn"),
	]
	panel.show_choices(dense_choices, 24, 1, 2)
	panel.complete_card_reveal()
	_expect(panel.detail_buttons[0].visible and panel.detail_buttons[0].get_parent() == panel.buttons[0].get_parent(), "dense stat cards must expose a sibling detail action", failures)
	_expect(panel.buttons[0].effect_label.text.contains("화상 피해·지속 강화") and not panel.buttons[0].effect_label.text.contains("위력 1") and not panel.buttons[0].tooltip_text.contains("공명 8"), "dense stat cards must collapse raw values into one qualitative change summary outside details", failures)
	panel._show_choice_details(0)
	_expect(panel.details_open and panel.details_summary.text.contains("공명 8"), "dense stat details must preserve the complete original values", failures)
	panel.hide_panel()
	panel.queue_free()

	var resolution_panel := (load("res://scenes/ui/artifact_resolution_panel.tscn") as PackedScene).instantiate() as ArtifactResolutionPanel
	root.add_child(resolution_panel)
	var equipped: Array[ArtifactData] = []
	for artifact in artifact_catalog.artifacts.slice(0, 6):
		equipped.append(artifact)
	resolution_panel.show_resolution(artifact_catalog.artifacts[6], equipped)
	_expect(resolution_panel.slot_buttons.all(func(button: Button) -> bool: return button.visible and button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and button.text.contains("보유 중") and button.text.contains("교체")), "the six-slot artifact resolver must use the same touch-sized comparison grammar", failures)
	_expect(resolution_panel.discard_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and resolution_panel.discard_button.focus_mode == Control.FOCUS_ALL, "artifact discard must remain an explicit touch and keyboard action", failures)
	resolution_panel.queue_free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
