class_name UiUxFoundationContractTest
extends RefCounted

const MANIFEST_PATH := "res://data/ui/ui_snapshot_manifest_v1.json"
const THEME_PATH := "res://data/ui/demon_election_ui_theme.tres"
const BUILD_INFO_SCRIPT := preload("res://scripts/game/build_info.gd")

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_expect(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280, "UI baseline viewport width must remain 1280", failures)
	_expect(ProjectSettings.get_setting("display/window/size/viewport_height") == 720, "UI baseline viewport height must remain 720", failures)
	_expect(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items", "UI must retain canvas_items stretch mode", failures)
	_expect(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "UI must retain the fixed 16:9 aspect used by the approved desktop and Android layouts", failures)
	_expect(ProjectSettings.get_setting("display/window/handheld/orientation") == 0, "mobile exports must explicitly lock the 1280x720 game to landscape orientation", failures)
	_expect(ProjectSettings.get_setting("application/config/version") == "0.04", "the visible build stamp and Android version name must share the project version source", failures)
	_expect(BUILD_INFO_SCRIPT.display_text() == "v0.04 · DEV", "editor runs must expose a stable DEV build identifier when no export metadata is present", failures)
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	var export_preset_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	var export_plugin_source := FileAccess.get_file_as_string("res://addons/build_stamp/build_stamp_export_plugin.gd")
	_expect(project_source.contains("res://addons/build_stamp/plugin.cfg") and export_plugin_source.contains("func _export_begin") and export_plugin_source.contains("add_file(METADATA_PATH"), "every GUI and CLI export must inject a unique build metadata file through the enabled export plugin", failures)
	_expect(export_preset_source.contains('version/name="0.04"') and export_preset_source.contains("version/code=4") and export_preset_source.contains("TD_survival_0.04.apk"), "Android artifact name, version name, and monotonic version code must identify the same 0.04 release", failures)
	var asset_catalog_source := FileAccess.get_file_as_string("res://resources/game_asset_catalog_data.gd")
	var runtime_validation_source := asset_catalog_source.get_slice("func get_validation_errors", 1).get_slice("func is_valid", 0)
	_expect(not runtime_validation_source.contains("ProjectSettings.globalize_path") and asset_catalog_source.contains("func get_authoring_validation_errors") and asset_catalog_source.contains("ResourceLoader.exists"), "runtime asset validation must remain packed-resource compatible while physical directory checks stay in an explicit authoring audit", failures)
	var repository_rules := FileAccess.get_file_as_string("res://AGENTS.md")
	var mobile_safety_rules := FileAccess.get_file_as_string("res://docs/MOBILE_RUNTIME_SAFETY_RULES.md")
	_expect(repository_rules.contains("모바일·배포 구조 안전 규칙") and repository_rules.contains("run_mobile_release_quality_gate.ps1") and mobile_safety_rules.contains("## 1. 리소스 경계") and mobile_safety_rules.contains("## 2. 입력 방식 경계") and mobile_safety_rules.contains("## 5. 변경 영향별 필수 검증"), "repository policy must retain the mobile runtime resource, input, and release-gate rules", failures)

	var manifest := _load_manifest(failures)
	if not manifest.is_empty():
		_validate_snapshot_baseline(manifest, failures)
		_validate_battlefield_baseline(root, manifest, failures)

	_expect(UiTokens.TOUCH_TARGET_MIN == 48.0 and UiTokens.PRIMARY_ACTION_HEIGHT == 56.0, "common UI tokens must retain 48px touch targets and 56px primary actions", failures)
	_expect(UiTokens.semantic_color(&"power") == Color("d95353") and UiTokens.semantic_color(&"range") == Color("3f82c8"), "semantic stat-axis colors must resolve through UI tokens", failures)
	var resolved_margins := UiSafeAreaLayout.resolve_margins(Vector2i(1280, 720), Rect2i(40, 25, 1200, 670))
	_expect(resolved_margins == Vector4(40.0, 25.0, 40.0, 25.0), "safe-area margins must preserve device insets above the minimum padding", failures)
	_expect(UiSafeAreaLayout.resolve_margins(Vector2i(1280, 720), Rect2i()).is_equal_approx(UiSafeAreaLayout.DEFAULT_MINIMUM), "an unavailable safe area must fall back to the documented minimum padding", failures)

	var theme := load(THEME_PATH) as Theme
	_expect(theme != null, "the demon-election shared Theme resource must load", failures)
	if theme != null:
		_expect(theme.get_font_size(&"font_size", &"Button") == UiTokens.FONT_BODY and theme.get_stylebox(&"focus", &"Button") != null, "the shared Theme must provide button typography and a visible focus style", failures)

	_validate_components(root, failures)
	return failures

static func _load_manifest(failures: Array[String]) -> Dictionary:
	_expect(FileAccess.file_exists(MANIFEST_PATH), "the UI snapshot baseline manifest must exist", failures)
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_expect(parsed is Dictionary, "the UI snapshot baseline manifest must be valid JSON", failures)
	return parsed as Dictionary if parsed is Dictionary else {}

static func _validate_snapshot_baseline(manifest: Dictionary, failures: Array[String]) -> void:
	var expected_count := int(manifest.get("expected_count", -1))
	var snapshot_ids: Array = manifest.get("snapshots", []) as Array
	_expect(int(manifest.get("schema_version", 0)) == 1, "the UI snapshot baseline must use schema version 1", failures)
	_expect(expected_count == 85 and snapshot_ids.size() == expected_count, "the UI baseline must preserve the 84 approved screens and add the dedicated title entry state", failures)
	var unique_ids := {}
	for snapshot_id_value in snapshot_ids:
		var snapshot_id := String(snapshot_id_value)
		unique_ids[snapshot_id] = true
		_expect(FileAccess.file_exists("res://tests/ui_snapshots/%s.png" % snapshot_id), "baseline snapshot is missing: %s" % snapshot_id, failures)
	_expect(unique_ids.size() == snapshot_ids.size(), "the UI baseline manifest must not contain duplicate snapshot ids", failures)
	var actual_ids: Array[String] = []
	for file_name in DirAccess.get_files_at("res://tests/ui_snapshots"):
		if file_name.ends_with(".png"):
			actual_ids.append(file_name.trim_suffix(".png"))
	actual_ids.sort()
	var expected_ids: Array[String] = []
	for snapshot_id_value in snapshot_ids:
		expected_ids.append(String(snapshot_id_value))
	expected_ids.sort()
	_expect(actual_ids == expected_ids, "the snapshot directory and manifest must contain the same 85 approved ids", failures)
	var reference_tracks := manifest.get("reference_tracks", {}) as Dictionary
	_expect((reference_tracks.get("combat_hud", []) as Array).size() >= 5, "the baseline must identify combat HUD comparison anchors", failures)
	_expect((reference_tracks.get("choice_cards", []) as Array).size() >= 5, "the baseline must identify choice-card comparison anchors", failures)
	_expect((reference_tracks.get("unit_information", []) as Array).size() >= 4, "the baseline must identify unit-information comparison anchors", failures)
	_expect((reference_tracks.get("meta_pages", []) as Array).size() >= 10, "the baseline must identify M5 menu and meta-page comparison anchors", failures)
	_expect((reference_tracks.get("modal_flows", []) as Array).size() >= 8, "the baseline must identify M6 preparation, pause, artifact, and result modal anchors", failures)

static func _validate_battlefield_baseline(root: Node, manifest: Dictionary, failures: Array[String]) -> void:
	var baseline_viewport := SubViewport.new()
	baseline_viewport.size = Vector2i(1280, 720)
	root.add_child(baseline_viewport)
	var battlefield := Battlefield.new()
	baseline_viewport.add_child(battlefield)
	var baseline := manifest.get("battlefield", {}) as Dictionary
	var expected_rect_values := baseline.get("expected_rect_1280x720", []) as Array
	var expected_rect := Rect2(
		float(expected_rect_values[0]),
		float(expected_rect_values[1]),
		float(expected_rect_values[2]),
		float(expected_rect_values[3])
	) if expected_rect_values.size() == 4 else Rect2()
	_expect(battlefield.horizontal_margin == Vector2(150.0, 70.0) and battlefield.vertical_margin == Vector2(105.0, 75.0), "UI work must not change the battlefield margin contract", failures)
	_expect(battlefield.lane_count == 4 and battlefield.column_count == 6, "UI work must preserve the 4x6 battlefield contract", failures)
	_expect(battlefield.get_battle_rect().is_equal_approx(expected_rect), "the 1280x720 battlefield rect must remain Rect2(150, 105, 1060, 540)", failures)
	baseline_viewport.queue_free()

static func _validate_components(root: Node, failures: Array[String]) -> void:
	var page := (load("res://scenes/ui/components/page_shell.tscn") as PackedScene).instantiate() as UiPageShell
	root.add_child(page)
	page.configure("도감", "발견한 항목을 확인합니다.", true)
	page.apply_safe_area(Vector2i(1280, 720), Rect2i(40, 25, 1200, 670))
	_expect(page.title_label.text == "도감" and page.subtitle_label.visible and page.back_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN, "PageShell must expose a touch-sized back action and configurable hierarchy", failures)
	_expect(page.get_theme_constant(&"margin_left") == 40 and page.get_theme_constant(&"margin_top") == 25, "PageShell must apply resolved safe-area margins", failures)
	page.queue_free()

	var modal := (load("res://scenes/ui/components/modal_shell.tscn") as PackedScene).instantiate() as UiModalShell
	root.add_child(modal)
	modal.configure("일시정지", false)
	_expect(modal.title_label.text == "일시정지" and not modal.close_button.visible and modal.close_button.custom_minimum_size == Vector2(48.0, 48.0), "ModalShell must expose title, dismissibility, and a 48px close target", failures)
	_expect(modal.get_body() != null and modal.get_footer() != null, "ModalShell must expose separate body and footer hosts", failures)
	modal.queue_free()

	var tag := (load("res://scenes/ui/components/tag_chip.tscn") as PackedScene).instantiate() as UiTagChip
	root.add_child(tag)
	tag.configure("위력", UiTokens.AXIS_POWER)
	_expect(tag.text_label.text == "위력" and tag.custom_minimum_size.y == UiTokens.TAG_HEIGHT and tag.mouse_filter == Control.MOUSE_FILTER_IGNORE, "TagChip must be compact, semantic, and non-blocking", failures)
	tag.queue_free()

	var icon_chip := (load("res://scenes/ui/components/icon_chip.tscn") as PackedScene).instantiate() as UiIconChip
	root.add_child(icon_chip)
	icon_chip.configure("아티팩트", null, UiTokens.ACCENT_GOLD, true)
	_expect(UiTokens.is_touch_target(icon_chip.custom_minimum_size) and icon_chip.focus_mode == Control.FOCUS_ALL and icon_chip.text_label.text == "아티팩트", "IconChip must expose a semantic label, selected state, and touch-sized focus target", failures)
	icon_chip.queue_free()

	var stat_row := (load("res://scenes/ui/components/stat_row.tscn") as PackedScene).instantiate() as UiStatRow
	root.add_child(stat_row)
	stat_row.configure("위력", "120", "+20", UiTokens.AXIS_POWER)
	_expect(stat_row.name_label.text == "위력" and stat_row.value_label.text == "120" and stat_row.change_label.visible, "StatRow must separate label, current value, and change value", failures)
	stat_row.queue_free()

	var card := (load("res://scenes/ui/components/choice_card.tscn") as PackedScene).instantiate() as UiChoiceCard
	root.add_child(card)
	card.configure({
		"eyebrow": "특성",
		"title": "왕실 화력",
		"effect": "[center]위력 100 → 120[/center]",
		"tags": ["위력", "병력"],
		"description": "일반 수비병력의 공격력이 증가합니다.",
		"accent": UiTokens.AXIS_POWER,
	})
	card.set_selected_state(true)
	_expect(card.custom_minimum_size.y >= 390.0 and card.focus_mode == Control.FOCUS_ALL, "ChoiceCard must remain a single focusable full-card action", failures)
	_expect(card.title_label.text == "왕실 화력" and card.title_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and card.tags_container.get_child_count() == 2 and card.header_panel.custom_minimum_size.y == 132.0 and card.detail_rail.custom_minimum_size.y == 48.0 and card.selection_panel.custom_minimum_size.y == 52.0 and card.selection_label.text == "선택됨", "ChoiceCard must expose the centered priority-header, change-surface, tag, application-surface, detail, and opposite selection hierarchy", failures)
	for child in card.find_children("*", "Control", true, false):
		_expect((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "ChoiceCard descendants must not create nested input targets", failures)
	card.queue_free()

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
