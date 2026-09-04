class_name UiUxM5MetaPagesContractTest
extends RefCounted

const MAIN_HUB_BACKGROUND := "res://assets/graphics/backgrounds/demon_election_campaign_hq_v019.png"
const STAGED_MAIN_HUB_BACKGROUND := "res://assets/graphics/style_refresh_v019/backgrounds/demon_election_campaign_hq_v019.png"

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_test_main_hub_background(failures)
	var save_backup := SaveManager._build_save_data()
	var bypass_backup := MetaProgressionService.testing_content_lock_bypass
	MetaProgressionService.set_testing_content_lock_bypass(false)
	SaveManager.tutorial_completed = true
	SaveManager.legacy_full_unlock = false
	SaveManager.unlocked_ids.assign(["emerald", "iron"])
	SaveManager.unlocked_feature_ids.assign(SaveManager.STARTER_FEATURE_IDS + ["shop_system", "achievement_system", "codex_system"])
	SaveManager.cleared_stage_ids.erase("standard_20m")

	var save_before_navigation := SaveManager._build_save_data()
	var menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	_expect(menu.splash_visible and menu.splash_page.visible and not menu.main_safe_area.visible, "M5 title entry must begin on the dedicated splash without exposing hub controls", failures)
	_expect(menu.enter_hub_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and menu.background.texture == ConceptService.texture(&"title_background"), "M5 title entry must expose a touch-sized action over the concept title background", failures)
	_expect(menu.build_version_label.visible and menu.build_version_label.text == "v0.04 · DEV" and menu.build_version_label.get_theme_font_size(&"font_size") <= 12 and menu.build_version_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the title corner must show a small non-interactive build identifier", failures)
	menu._enter_main_hub()
	_expect(not menu.splash_visible and not menu.splash_page.visible and menu.main_safe_area.visible and menu.current_page == menu.MenuPage.TITLE, "M5 title entry must transition into the campaign hub without adding a sixth menu page", failures)
	_expect(not menu.build_version_label.visible, "the build identifier must remain limited to the dedicated title screen", failures)
	_expect(menu.background.texture == ConceptService.texture(&"main_hub_background") and not menu.hub_candidate_name.text.is_empty(), "M5 campaign hub must use its dedicated background and expose the current candidate summary", failures)
	_expect(menu.get_node_or_null("SafeArea/Shell/Header") == null and menu.get_node_or_null("SafeArea/Shell/Footer") == null and menu.find_child("SplashEyebrow", true, false) == null, "M5 title and hub must omit duplicate committee, record, key-hint, and version chrome", failures)
	_expect(menu.find_child("MenuLabel", true, false) == null, "M5 hub actions must communicate their role through control styling without a redundant section label", failures)
	_expect(menu.hub_title.text == "유세 본부" and menu.hub_description.max_lines_visible <= 2 and not menu.title_status.visible, "M5 hub must present one compact action-oriented introduction and hide empty status copy", failures)
	var hub_surface := menu.hub_hero.get_theme_stylebox(&"panel") as StyleBoxFlat
	_expect(hub_surface != null and hub_surface.bg_color.a < 0.9 and menu.background_overlay.color.a <= 0.2, "M5 hub surfaces and overlay must preserve the architectural background as part of the interface", failures)
	var hub_actions: Array[Button] = [
		menu.get_node("%GameMenuButton") as Button,
		menu.get_node("%ShopMenuButton") as Button,
		menu.get_node("%AchievementMenuButton") as Button,
		menu.get_node("%CodexMenuButton") as Button,
	]
	_expect(hub_actions.all(func(button: Button) -> bool: return not button.text.contains("\n") and not button.text.begins_with("0") and not button.tooltip_text.is_empty()), "M5 hub actions must use concise single-line labels while retaining explanations as tooltips", failures)
	var hub_hero := menu.hub_hero as PanelContainer
	var hub_navigation := menu.hub_navigation as VBoxContainer
	var primary_action_style := hub_actions.front().get_theme_stylebox(&"normal") as StyleBoxFlat
	var secondary_action_style := hub_actions[1].get_theme_stylebox(&"normal") as StyleBoxFlat
	_expect(primary_action_style != null and secondary_action_style != null and primary_action_style.border_width_left > primary_action_style.border_width_right and not primary_action_style.bg_color.is_equal_approx(secondary_action_style.bg_color), "M5 action pane must use leading interaction rails and a style-only primary action hierarchy", failures)
	_expect(hub_surface.border_color.a < secondary_action_style.border_color.a and hub_hero.mouse_filter == Control.MOUSE_FILTER_IGNORE, "M5 information pane must remain a quieter continuous non-interactive surface than the action pane", failures)
	_expect(hub_hero.size_flags_horizontal == Control.SIZE_EXPAND_FILL and hub_navigation.size_flags_horizontal == Control.SIZE_EXPAND_FILL and is_equal_approx(hub_hero.size_flags_stretch_ratio, hub_navigation.size_flags_stretch_ratio) and is_equal_approx(hub_hero.custom_minimum_size.x, hub_navigation.custom_minimum_size.x), "M5 hub columns must use the same horizontal expansion, stretch ratio, and minimum width", failures)
	_expect(menu.main_safe_area.get_theme_constant(&"margin_left") == menu.main_safe_area.get_theme_constant(&"margin_right") and hub_actions.all(func(button: Button) -> bool: return button.size_flags_vertical == Control.SIZE_EXPAND_FILL), "M5 hub must keep equal outer margins and distribute all action rows to the candidate card bottom edge", failures)
	_expect(menu.hub_candidate_meta.text.contains(ConceptService.term(&"currency")) and not menu.hub_candidate_meta.text.contains("승인도"), "M5 hub identity must retain only the retainer, support, and spendable currency summary", failures)

	_expect(menu.page_shells.size() == 5, "M5 title, setup, shop, achievements, and codex must mount the common PageShell", failures)
	for page in menu.page_shells:
		var shell := menu.page_shells[page] as UiPageShell
		_expect(shell != null and shell.surface_panel != null, "M5 every menu page must own a configured PageShell surface", failures)
		if page != menu.MenuPage.TITLE:
			_expect(shell.back_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and shell.back_button.focus_mode == Control.FOCUS_ALL, "M5 page back actions must share the 48px keyboard/touch contract", failures)

	var candidate_buttons: Array = menu.candidate_choice_buttons.values()
	var retainer_buttons: Array = menu.retainer_choice_buttons.values()
	_expect(not candidate_buttons.is_empty() and not retainer_buttons.is_empty() and candidate_buttons.all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN) and retainer_buttons.all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN), "M5 candidate and retainer choice cards must remain touch-sized", failures)
	var locked_candidate := candidate_buttons.filter(func(button: Button) -> bool: return button.disabled)
	_expect(not locked_candidate.is_empty() and String((locked_candidate.front() as Button).get_meta(&"lock_reason", "")).contains("표준 유세 최초 승리") and menu.candidate_step_label.text.contains("표준 유세 최초 승리"), "M5 locked identity cards must expose a visible, non-color unlock reason", failures)

	menu._configure_challenge_selector()
	_expect(menu.challenge_description.visible and menu.challenge_description.text.contains("도전 단계 잠김") and menu.challenge_description.autowrap_mode != TextServer.AUTOWRAP_OFF, "M5 locked Challenge state must show an untruncated reason", failures)

	var shop_buttons: Array = menu.shop_product_list.get_children().filter(func(child: Node) -> bool: return child is Button)
	_expect(shop_buttons.size() == 5 and shop_buttons.all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and (button.text.contains("구매") or button.text.contains("자금"))), "M5 shop cards must retain purchase state text and common touch sizing", failures)
	_expect(menu.achievement_browser.filter_buttons.values().all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN), "M5 achievement tabs must use the common touch/focus style", failures)
	_expect(menu.achievement_browser.scroll_container.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and menu.achievement_browser.scroll_container.scroll_deadzone >= 12, "achievement browsing must expose an explicit touch-drag vertical scroll contract", failures)
	_expect(_mouse_filters_do_not_block_scroll(menu.achievement_browser.achievement_list), "passive achievement cards must not stop pointer events before their ScrollContainer", failures)
	_expect(menu.codex_category_buttons.values().all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN), "M5 codex tabs must use the common touch/focus style", failures)
	_expect(menu.codex_browser.entry_buttons.values().all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and button.autowrap_mode != TextServer.AUTOWRAP_OFF), "M5 codex list cards must keep state text readable without color-only meaning", failures)

	menu.achievement_browser.scroll_positions[&"all"] = 31
	menu.achievement_browser.remember_view_state()
	menu.codex_browser.selected_keys[menu.codex_browser.current_category] = menu.codex_browser.selected_key
	menu.codex_browser.scroll_positions[menu.codex_browser.current_category] = 27
	menu.codex_browser.restore_view_state()
	_expect(menu.achievement_browser.scroll_positions.has(&"all") and menu.codex_browser.selected_keys.has(menu.codex_browser.current_category), "M5 long-list pages must retain per-filter/category view state", failures)

	var shop_origin := menu.get_node("%ShopMenuButton") as Button
	menu._open_meta_page(menu.MenuPage.SHOP, shop_origin)
	var shop_shell := menu.page_shells[menu.MenuPage.SHOP] as UiPageShell
	_expect(not menu.title_page.visible and shop_shell.header_container.visible and menu.background_overlay.color.a >= 0.45, "M5 subpages must reserve the full safe area for their own PageShell header and strengthen background contrast", failures)
	menu._return_to_title()
	_expect(menu.current_page == menu.MenuPage.TITLE and menu.title_return_focus == shop_origin and menu.title_page.visible and menu.background_overlay.color.a <= 0.2, "M5 back navigation must restore the integrated hub and focus intent to the title action that opened the page", failures)
	var pointer_event := InputEventScreenTouch.new()
	pointer_event.pressed = true
	menu._input(pointer_event)
	_expect(not menu.directional_focus_active, "touch input must suppress persistent keyboard focus styling", failures)
	var keyboard_event := InputEventKey.new()
	keyboard_event.pressed = true
	keyboard_event.keycode = KEY_TAB
	menu._input(keyboard_event)
	_expect(menu.directional_focus_active, "keyboard input must re-enable accessible focus restoration", failures)
	_expect(SaveManager._build_save_data() == save_before_navigation, "M5 page navigation must not mutate unlock, purchase, discovery, Challenge, or save results", failures)

	menu.queue_free()
	SaveManager._apply_save_data(save_backup)
	MetaProgressionService.set_testing_content_lock_bypass(bypass_backup)
	return failures

static func _mouse_filters_do_not_block_scroll(control: Control) -> bool:
	for child in control.get_children():
		if child is Control:
			var child_control := child as Control
			if child_control.mouse_filter == Control.MOUSE_FILTER_STOP or not _mouse_filters_do_not_block_scroll(child_control):
				return false
	return true

static func _test_main_hub_background(failures: Array[String]) -> void:
	_expect(ResourceLoader.exists(MAIN_HUB_BACKGROUND), "minimal-detail main hub background is missing", failures)
	_expect(FileAccess.file_exists(STAGED_MAIN_HUB_BACKGROUND), "minimal-detail main hub staging master is missing", failures)
	var texture := load(MAIN_HUB_BACKGROUND) as Texture2D
	var image := texture.get_image() if texture != null else Image.new()
	_expect(not image.is_empty(), "minimal-detail main hub background cannot be decoded", failures)
	if not image.is_empty():
		_expect(image.get_size() == Vector2i(1280, 720), "minimal-detail main hub background must be exactly 1280x720", failures)
	_expect(FileAccess.get_file_as_bytes(MAIN_HUB_BACKGROUND) == FileAccess.get_file_as_bytes(STAGED_MAIN_HUB_BACKGROUND), "active main hub background must match its approved minimal-detail staging master", failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
