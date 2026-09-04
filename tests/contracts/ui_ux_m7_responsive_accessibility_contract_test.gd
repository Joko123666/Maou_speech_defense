class_name UiUxM7ResponsiveAccessibilityContractTest
extends RefCounted

const SUPPORTED_LANDSCAPE_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(1920, 1080),
]
const DEFENSIVE_COMPACT_PROBE_SIZE := Vector2i(960, 540)

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_test_safe_area_and_responsive_shells(root, failures)
	_test_hud_safe_area(root, failures)
	_test_focus_and_spoken_labels(root, failures)
	_test_contrast(failures)
	_test_reduced_motion(root, failures)
	_test_ui_update_boundaries(failures)
	return failures

static func _test_safe_area_and_responsive_shells(root: Node, failures: Array[String]) -> void:
	var page := (load("res://scenes/ui/components/page_shell.tscn") as PackedScene).instantiate() as UiPageShell
	root.add_child(page)
	page.apply_safe_area(Vector2i(1280, 720), Rect2i(32, 24, 1216, 672))
	_expect(page.get_theme_constant(&"margin_left") == 32 and page.get_theme_constant(&"margin_bottom") == 24, "M7 PageShell must apply a mocked safe inset on the minimum supported 1280x720 landscape viewport", failures)
	page.queue_free()

	var modal := (load("res://scenes/ui/components/modal_shell.tscn") as PackedScene).instantiate() as UiModalShell
	root.add_child(modal)
	modal.set_panel_minimum_size(Vector2(1160.0, 650.0))
	for viewport_size in SUPPORTED_LANDSCAPE_SIZES:
		var safe_rect := Rect2i(Vector2i(32, 24), viewport_size - Vector2i(64, 48)) if viewport_size == Vector2i(1280, 720) else Rect2i(Vector2i.ZERO, viewport_size)
		modal.apply_safe_area(viewport_size, safe_rect)
		var margins := UiSafeAreaLayout.resolve_margins(viewport_size, safe_rect)
		var available := UiSafeAreaLayout.available_size(viewport_size, margins)
		_expect(modal.panel.custom_minimum_size.x <= available.x and modal.panel.custom_minimum_size.y <= available.y, "M7 ModalShell must clamp its preferred size inside %dx%d safe bounds" % [viewport_size.x, viewport_size.y], failures)
	modal.apply_safe_area(DEFENSIVE_COMPACT_PROBE_SIZE, Rect2i(32, 24, 896, 492))
	_expect(modal.panel.custom_minimum_size.x <= 896.0 and modal.panel.custom_minimum_size.y <= 492.0, "M7 ModalShell must degrade safely in the unsupported 960x540 defensive probe", failures)
	modal.queue_free()

static func _test_hud_safe_area(root: Node, failures: Array[String]) -> void:
	var hud := (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate() as GameHUD
	root.add_child(hud)
	hud.apply_safe_area(Vector2i(960, 540), Rect2i(32, 24, 896, 492))
	_expect(hud.compact_layout and hud.top_bar.offset_left == 32.0 and hud.event_frame.offset_right == -32.0, "M7 HUD must enter defensive compact mode and keep top/event controls inside mocked safe insets at 960x540", failures)
	_expect([hud.skill_button, hud.speed_button, hud.range_button, hud.pause_button, hud.bottom_info_toggle].all(func(control: Control) -> bool: return control.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN), "M7 HUD primary actions must retain 48px touch height in compact mode", failures)
	hud.apply_safe_area(Vector2i(1920, 1080), Rect2i(Vector2i.ZERO, Vector2i(1920, 1080)))
	_expect(not hud.compact_layout and hud.run_context_panel.custom_minimum_size.x == 286.0, "M7 HUD must restore its full information layout at 1920x1080", failures)
	hud.queue_free()

static func _test_focus_and_spoken_labels(root: Node, failures: Array[String]) -> void:
	var menu := (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	menu.persist_options = false
	root.add_child(menu)
	menu.show_menu()
	var main_controls := UiFocusFlow.link_cycle(menu.modal_shell)
	_expect(main_controls.size() >= 3 and main_controls.all(func(control: Control) -> bool: return not UiFocusFlow.spoken_label(control).is_empty()), "M7 pause actions must expose readable labels to keyboard/gamepad and assistive descriptions", failures)
	for control in main_controls:
		_expect(not control.focus_next.is_empty() and not control.focus_previous.is_empty(), "M7 visible modal controls must have an explicit cyclic focus route", failures)
	menu.show_options()
	var option_controls := UiFocusFlow.focusable_controls(menu.modal_shell)
	_expect(option_controls.size() >= 5 and option_controls.all(func(control: Control) -> bool: return not UiFocusFlow.spoken_label(control).is_empty()), "M7 sound, shake, flash, reduced-motion, and back controls must all have spoken labels", failures)
	menu.hide_menu()
	menu.queue_free()

static func _test_contrast(failures: Array[String]) -> void:
	_expect(UiTokens.contrast_ratio(UiTokens.INK_ROYAL, UiTokens.SURFACE_PARCHMENT) >= 4.5, "M7 parchment body text must meet the 4.5:1 contrast target", failures)
	_expect(UiTokens.contrast_ratio(UiTokens.ACCENT_GOLD_TEXT, UiTokens.SURFACE_PARCHMENT) >= 4.5, "M7 gold semantic text on parchment must meet the 4.5:1 contrast target", failures)
	_expect(UiTokens.contrast_ratio(UiTokens.FOCUS_RING, UiTokens.INK_DEEP) >= 3.0, "M7 focus boundaries must meet the 3:1 non-text contrast target", failures)

static func _test_reduced_motion(root: Node, failures: Array[String]) -> void:
	var previous := GameSession.reduced_motion_enabled
	var menu := (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	menu.persist_options = false
	root.add_child(menu)
	menu.show_menu()
	menu.show_options()
	menu.reduced_motion_toggle.set_pressed_no_signal(false)
	menu.reduced_motion_toggle.button_pressed = true
	_expect(GameSession.reduced_motion_enabled and UiMotion.is_reduced(), "M7 reduced-motion option must apply immediately without waiting for a restart", failures)
	menu.reduced_motion_toggle.button_pressed = false
	GameSession.reduced_motion_enabled = previous
	_expect(SaveManager._build_save_data().has("reduced_motion_enabled"), "M7 reduced-motion preference must be represented in persistent save data", failures)
	menu.hide_menu()
	menu.queue_free()

static func _test_ui_update_boundaries(failures: Array[String]) -> void:
	var presentation_sources := "\n".join([
		FileAccess.get_file_as_string("res://scripts/ui/components/page_shell.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/components/modal_shell.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/hud.gd"),
	])
	_expect(not presentation_sources.contains("func _process(") and not presentation_sources.contains("func _physics_process("), "M7 Page/Modal/HUD presentation shells must remain event-driven instead of rebuilding UI every frame", failures)
	_expect(FileAccess.get_file_as_string("res://scripts/ui/level_up_panel.gd").contains("UiMotion.is_reduced()") and FileAccess.get_file_as_string("res://scripts/ui/hud.gd").contains("UiMotion.should_animate()"), "M7 choice-card and HUD/result animation paths must honor reduced motion", failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
