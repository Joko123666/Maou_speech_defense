extends Control

const FALLBACK_STAGE_ID: StringName = &"standard_20m"
const PAGE_SHELL_SCENE := preload("res://scenes/ui/components/page_shell.tscn")
const BUILD_INFO := preload("res://scripts/game/build_info.gd")

enum MenuPage {
	TITLE,
	GAME_SETUP,
	SHOP,
	ACHIEVEMENTS,
	CODEX,
}

@onready var title_page: Control = %TitlePage
@onready var splash_page: MarginContainer = %SplashPage
@onready var main_safe_area: MarginContainer = $SafeArea
@onready var background: TextureRect = $Background
@onready var background_overlay: ColorRect = $Overlay
@onready var enter_hub_button: Button = %EnterHubButton
@onready var build_version_label: Label = %BuildVersionLabel
@onready var hub_hero: PanelContainer = $SafeArea/Shell/Pages/TitlePage/Center/Columns/Hero
@onready var hub_sector: Label = $SafeArea/Shell/Pages/TitlePage/Center/Columns/Hero/Content/Sector
@onready var hub_title: Label = $SafeArea/Shell/Pages/TitlePage/Center/Columns/Hero/Content/Title
@onready var hub_description: Label = $SafeArea/Shell/Pages/TitlePage/Center/Columns/Hero/Content/Description
@onready var hub_navigation: VBoxContainer = $SafeArea/Shell/Pages/TitlePage/Center/Columns/Navigation
@onready var hub_candidate_portrait: TextureRect = %HubCandidatePortrait
@onready var hub_candidate_name: Label = %HubCandidateName
@onready var hub_candidate_meta: Label = %HubCandidateMeta
@onready var game_setup_page: Control = %GameSetupPage
@onready var shop_page: Control = %ShopPage
@onready var achievements_page: Control = %AchievementsPage
@onready var codex_page: Control = %CodexPage
@onready var core_option: OptionButton = %CoreOption
@onready var cursor_option: OptionButton = %CursorOption
@onready var setup_selectors: GridContainer = %Selectors
@onready var campaign_choice_section: VBoxContainer = %CampaignChoiceSection
@onready var candidate_step_label: Label = %CandidateStepLabel
@onready var candidate_choice_scroll: ScrollContainer = %CandidateChoiceScroll
@onready var candidate_choice_list: HBoxContainer = %CandidateChoiceList
@onready var retainer_step_label: Label = %RetainerStepLabel
@onready var retainer_choice_scroll: ScrollContainer = %RetainerChoiceScroll
@onready var retainer_choice_list: HBoxContainer = %RetainerChoiceList
@onready var challenge_label: Label = %ChallengeLabel
@onready var challenge_controls: HBoxContainer = %ChallengeControls
@onready var challenge_slider: HSlider = %ChallengeSlider
@onready var challenge_value_label: Label = %ChallengeValue
@onready var challenge_summary: Label = %ChallengeSummary
@onready var challenge_description: Label = %ChallengeDescription
@onready var description_label: Label = %DescriptionLabel
@onready var campaign_profile_section: VBoxContainer = %CampaignProfileSection
@onready var campaign_rival_preview: Label = %CampaignRivalPreview
@onready var candidate_card: PanelContainer = %CandidateCard
@onready var candidate_portrait: TextureRect = %CandidatePortrait
@onready var candidate_emblem: TextureRect = %CandidateEmblem
@onready var candidate_name: Label = %CandidateName
@onready var candidate_title: Label = %CandidateTitle
@onready var candidate_slogan: Label = %CandidateSlogan
@onready var candidate_stats: Label = %CandidateStats
@onready var decree_option: OptionButton = %DecreeOption
@onready var retainer_card: PanelContainer = %RetainerCard
@onready var retainer_portrait: TextureRect = %RetainerPortrait
@onready var retainer_name: Label = %RetainerName
@onready var retainer_title: Label = %RetainerTitle
@onready var retainer_description: Label = %RetainerDescription
@onready var retainer_stats: Label = %RetainerStats
@onready var record_label: Label = %RecordLabel
@onready var shop_product_list: VBoxContainer = %ShopProductList
@onready var shop_balance: Label = %ShopBalance
@onready var shop_notice: Label = %ShopNotice
@onready var title_status: Label = $SafeArea/Shell/Pages/TitlePage/Center/Columns/Hero/Content/Status
@onready var title_center: CenterContainer = $SafeArea/Shell/Pages/TitlePage/Center
@onready var title_columns: HBoxContainer = $SafeArea/Shell/Pages/TitlePage/Center/Columns
@onready var setup_center: CenterContainer = $SafeArea/Shell/Pages/GameSetupPage/Center
@onready var setup_content: VBoxContainer = $SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content
@onready var setup_page_title: Label = $SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/PageTitle
@onready var setup_page_subtitle: Label = $SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/PageSubtitle
@onready var shop_center: CenterContainer = $SafeArea/Shell/Pages/ShopPage/Center
@onready var shop_content: VBoxContainer = $SafeArea/Shell/Pages/ShopPage/Center/Panel/Content
@onready var shop_page_title: Label = $SafeArea/Shell/Pages/ShopPage/Center/Panel/Content/Title
@onready var shop_page_subtitle: Label = $SafeArea/Shell/Pages/ShopPage/Center/Panel/Content/Subtitle
@onready var achievement_center: CenterContainer = $SafeArea/Shell/Pages/AchievementsPage/Center
@onready var achievement_panel: PanelContainer = $SafeArea/Shell/Pages/AchievementsPage/Center/Panel
@onready var achievement_content: VBoxContainer = $SafeArea/Shell/Pages/AchievementsPage/Center/Panel/Content
@onready var achievement_page_title: Label = $SafeArea/Shell/Pages/AchievementsPage/Center/Panel/Content/PageTitle
@onready var achievement_page_subtitle: Label = $SafeArea/Shell/Pages/AchievementsPage/Center/Panel/Content/PageSubtitle
@onready var achievement_host: VBoxContainer = $SafeArea/Shell/Pages/AchievementsPage/Center/Panel/Content/Placeholder/Message
@onready var codex_center: CenterContainer = $SafeArea/Shell/Pages/CodexPage/Center
@onready var codex_panel: PanelContainer = $SafeArea/Shell/Pages/CodexPage/Center/Panel
@onready var codex_content: VBoxContainer = $SafeArea/Shell/Pages/CodexPage/Center/Panel/Content
@onready var codex_page_title: Label = $SafeArea/Shell/Pages/CodexPage/Center/Panel/Content/PageTitle
@onready var codex_page_subtitle: Label = $SafeArea/Shell/Pages/CodexPage/Center/Panel/Content/PageSubtitle
@onready var codex_categories: HBoxContainer = $SafeArea/Shell/Pages/CodexPage/Center/Panel/Content/Categories
@onready var codex_host: VBoxContainer = $SafeArea/Shell/Pages/CodexPage/Center/Panel/Content/Placeholder/Message

var current_page: MenuPage = MenuPage.TITLE
var checkpoint_recovery_blocked: bool = false
var achievement_browser: AchievementBrowser
var codex_browser: CodexBrowser
var codex_category_buttons: Dictionary = {}
var candidate_choice_buttons: Dictionary = {}
var retainer_choice_buttons: Dictionary = {}
var candidate_choice_group: ButtonGroup
var retainer_choice_group: ButtonGroup
var page_shells: Dictionary = {}
var title_return_focus: Control
var splash_visible: bool = true
var title_background: Texture2D
var hub_background: Texture2D
var concept_overlay_color := Color(0.006, 0.02, 0.032, 1.0)
var directional_focus_active: bool = true

func _ready() -> void:
	directional_focus_active = not DisplayServer.is_touchscreen_available()
	_refresh_build_version()
	_apply_concept_profile()
	_mount_page_shells()
	if get_tree().current_scene == self:
		_recover_pending_checkpoint()
	_setup_meta_browsers()
	_fill_option(core_option, DataRegistry.cores)
	_fill_option(cursor_option, DataRegistry.cursors)
	_select_configured_item(core_option, GameSession.selected_core_id)
	_select_configured_item(cursor_option, GameSession.selected_cursor_id)
	_build_campaign_choice_cards()
	core_option.item_selected.connect(_on_core_option_selected)
	cursor_option.item_selected.connect(_on_cursor_option_selected)
	challenge_slider.value_changed.connect(_on_challenge_changed)
	decree_option.item_selected.connect(_on_decree_selected)
	%ChallengeDecrease.pressed.connect(func() -> void: _set_challenge_level(roundi(challenge_slider.value) - 1))
	%ChallengeIncrease.pressed.connect(func() -> void: _set_challenge_level(roundi(challenge_slider.value) + 1))
	%GameMenuButton.pressed.connect(_open_game_setup)
	enter_hub_button.pressed.connect(_enter_main_hub)
	%ShopMenuButton.pressed.connect(_open_meta_page.bind(MenuPage.SHOP, %ShopMenuButton))
	%AchievementMenuButton.pressed.connect(_open_meta_page.bind(MenuPage.ACHIEVEMENTS, %AchievementMenuButton))
	%CodexMenuButton.pressed.connect(_open_meta_page.bind(MenuPage.CODEX, %CodexMenuButton))
	%GameBackButton.pressed.connect(_return_to_title)
	%ShopBackButton.pressed.connect(_return_to_title)
	%AchievementBackButton.pressed.connect(_return_to_title)
	%CodexBackButton.pressed.connect(_return_to_title)
	%StartButton.pressed.connect(_start_game)
	_configure_challenge_selector()
	_update_description()
	_update_records()
	_refresh_meta_navigation()
	_refresh_shop()
	_refresh_achievements()
	_refresh_codex()
	if not GameSession.meta_notice.is_empty():
		title_status.text = GameSession.meta_notice
		title_status.visible = true
		GameSession.meta_notice = ""
	_apply_concept_failure_state()
	_show_title_splash(false)

func _refresh_build_version() -> void:
	build_version_label.text = BUILD_INFO.display_text()
	print("BUILD IDENTIFIER: %s" % build_version_label.text)

func _mount_page_shells() -> void:
	var title_shell := _mount_page_shell(
		title_page,
		title_center,
		[title_columns],
		"",
		"",
		"",
		"",
		false
	)
	title_shell.set_header_visible(false)
	title_shell.set_surface_style(UiStyleFactory.panel(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0.0))
	title_shell.get_body().alignment = BoxContainer.ALIGNMENT_CENTER
	title_shell.get_body().add_theme_constant_override(&"separation", 0)

	var setup_shell := _mount_page_shell(
		game_setup_page,
		setup_center,
		[
			record_label,
			%StartButton,
		],
		setup_page_title.text,
		setup_page_subtitle.text,
		"GAME / LOADOUT",
		"1 후보 → 2 심복 → 3 도전·칙령",
		true
	)
	setup_shell.get_body().add_theme_constant_override(&"separation", 5)
	var setup_scroll := ScrollContainer.new()
	setup_scroll.name = "SetupScroll"
	setup_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	setup_scroll.scroll_deadzone = 12
	var setup_scroll_content := VBoxContainer.new()
	setup_scroll_content.name = "SetupScrollContent"
	setup_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_scroll_content.add_theme_constant_override(&"separation", 5)
	setup_scroll.add_child(setup_scroll_content)
	setup_shell.get_body().add_child(setup_scroll)
	setup_shell.get_body().move_child(setup_scroll, 0)
	for content in [campaign_choice_section, setup_selectors, challenge_description, description_label, campaign_profile_section]:
		(content as Control).reparent(setup_scroll_content)

	var shop_shell := _mount_page_shell(
		shop_page,
		shop_center,
		[shop_notice, shop_content.get_node("Scroll")],
		shop_page_title.text,
		shop_page_subtitle.text,
		"CAMPAIGN / SHOP",
		shop_balance.text,
		true
	)
	shop_shell.get_body().add_theme_constant_override(&"separation", 8)

	var achievement_placeholder := achievement_content.get_node("Placeholder") as PanelContainer
	var achievement_shell := _mount_page_shell(
		achievements_page,
		achievement_center,
		[achievement_placeholder],
		achievement_page_title.text,
		achievement_page_subtitle.text,
		"RECORDS / ACHIEVEMENTS",
		"보상은 결과 정산 시 자동 지급",
		true
	)
	achievement_placeholder.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED, UiTokens.INK_MUTED, UiTokens.RADIUS_CARD, 1, 14.0))

	var codex_placeholder := codex_content.get_node("Placeholder") as PanelContainer
	var codex_shell := _mount_page_shell(
		codex_page,
		codex_center,
		[codex_categories, codex_placeholder],
		codex_page_title.text,
		codex_page_subtitle.text,
		"ARCHIVE / CODEX",
		"발견 기록은 저장 데이터와 동기화",
		true
	)
	codex_placeholder.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED, UiTokens.INK_MUTED, UiTokens.RADIUS_CARD, 1, 14.0))
	_apply_m5_component_styles()

func _mount_page_shell(
	page: Control,
	legacy_center: Control,
	content_nodes: Array,
	title: String,
	subtitle: String,
	eyebrow: String,
	status: String,
	show_back: bool
) -> UiPageShell:
	var shell := PAGE_SHELL_SCENE.instantiate() as UiPageShell
	shell.name = "PageShell"
	page.add_child(shell)
	shell.configure(title, subtitle, show_back, eyebrow, status)
	if show_back:
		shell.back_button.text = "‹ 유세 본부"
		shell.back_requested.connect(_return_to_title)
		shell.set_surface_style(UiStyleFactory.panel(Color(UiTokens.SURFACE_PARCHMENT, 0.96), UiTokens.INK_ROYAL, UiTokens.RADIUS_MODAL, 2, float(UiTokens.SPACE_4)))
	for content in content_nodes:
		if is_instance_valid(content):
			(content as Control).reparent(shell.get_body())
	legacy_center.visible = false
	page_shells[_page_for_control(page)] = shell
	return shell

func _page_for_control(page: Control) -> int:
	if page == game_setup_page:
		return MenuPage.GAME_SETUP
	if page == shop_page:
		return MenuPage.SHOP
	if page == achievements_page:
		return MenuPage.ACHIEVEMENTS
	if page == codex_page:
		return MenuPage.CODEX
	return MenuPage.TITLE

func _apply_m5_component_styles() -> void:
	UiStyleFactory.apply_hud_button(enter_hub_button, UiTokens.ACCENT_GOLD)
	enter_hub_button.custom_minimum_size.y = 62.0
	var hub_actions: Array[Button] = [%GameMenuButton, %ShopMenuButton, %AchievementMenuButton, %CodexMenuButton]
	for index in hub_actions.size():
		_apply_hub_action_style(hub_actions[index], index == 0)
	UiStyleFactory.apply_button(%StartButton, UiTokens.FACTION_RETAINER)
	%StartButton.custom_minimum_size.y = UiTokens.PRIMARY_ACTION_HEIGHT
	for button in [%ChallengeDecrease, %ChallengeIncrease]:
		UiStyleFactory.apply_button(button as Button, UiTokens.ACCENT_GOLD)
	for option in [core_option, cursor_option, decree_option]:
		(option as Control).custom_minimum_size.y = maxf((option as Control).custom_minimum_size.y, UiTokens.TOUCH_TARGET_MIN)
	candidate_choice_scroll.custom_minimum_size.y = 64.0
	retainer_choice_scroll.custom_minimum_size.y = 64.0
	candidate_step_label.text = "1  마왕 후보 선택  ·  잠긴 후보는 이전 후보로 표준 유세 최초 승리 시 해금"
	retainer_step_label.text = "2  수석 심복 선택  ·  잠긴 심복은 이전 심복으로 표준 유세 최초 승리 시 해금"
	for step_label in [candidate_step_label, retainer_step_label]:
		(step_label as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(step_label as Label).add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	challenge_slider.custom_minimum_size.y = UiTokens.TOUCH_TARGET_MIN
	challenge_label.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	challenge_value_label.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	challenge_summary.add_theme_color_override(&"font_color", UiTokens.INK_MUTED)
	challenge_description.add_theme_color_override(&"font_color", UiTokens.DANGER)
	record_label.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	shop_notice.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	shop_balance.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	for button in codex_category_buttons.values():
		UiStyleFactory.apply_button(button as Button, UiTokens.INK_ROYAL)

func _apply_hub_action_style(button: Button, primary: bool) -> void:
	UiStyleFactory.apply_hud_button(button, UiTokens.ACCENT_GOLD, primary)
	button.custom_minimum_size.y = 82.0
	button.add_theme_font_size_override(&"font_size", 20)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		if style == null:
			continue
		style.set_border_width(SIDE_LEFT, 5)
		style.set_border_width(SIDE_TOP, 2 if state in [&"hover", &"pressed", &"focus"] else 1)
		style.set_border_width(SIDE_RIGHT, 2 if state in [&"hover", &"pressed", &"focus"] else 1)
		style.set_border_width(SIDE_BOTTOM, 2 if state in [&"hover", &"pressed", &"focus"] else 1)
		style.content_margin_left = 22.0
		style.content_margin_right = 18.0

func _open_meta_page(page: MenuPage, origin: Control) -> void:
	title_return_focus = origin
	show_page(page)

func _recover_pending_checkpoint() -> bool:
	var recovery := RunCheckpointService.recover_pending()
	checkpoint_recovery_blocked = not bool(recovery.get("completed", false))
	if checkpoint_recovery_blocked:
		var message := "이전 출격 보상 복구에 실패했습니다. 출격 메뉴를 눌러 다시 시도해 주세요."
		GameSession.meta_notice = message
		title_status.text = message
		title_status.visible = true
	return not checkpoint_recovery_blocked

func _open_game_setup() -> void:
	if ConceptService.active == null or ConceptService.get_default_stage() == null:
		_apply_concept_failure_state()
		return
	if checkpoint_recovery_blocked and not _recover_pending_checkpoint():
		return
	if not SaveManager.tutorial_completed:
		_start_tutorial()
		return
	title_return_focus = %GameMenuButton
	show_page(MenuPage.GAME_SETUP)

func _start_tutorial() -> void:
	GameSession.configure_tutorial()
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial_game.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if splash_visible:
		if event.is_action_pressed(&"ui_accept"):
			_enter_main_hub()
			get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if current_page == MenuPage.TITLE:
		_show_title_splash()
	else:
		_return_to_title()
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		directional_focus_active = false
		_clear_gui_focus()
	elif event is InputEventKey and event.pressed and not event.echo:
		directional_focus_active = true
	elif event is InputEventJoypadButton and event.pressed:
		directional_focus_active = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5:
		directional_focus_active = true

func _show_title_splash(play_sound: bool = true) -> void:
	splash_visible = true
	splash_page.visible = true
	build_version_label.visible = true
	main_safe_area.visible = false
	_set_background(title_background, 0.34)
	if play_sound:
		AudioManager.play_ui()
	_request_focus(enter_hub_button)

func _enter_main_hub() -> void:
	splash_visible = false
	splash_page.visible = false
	build_version_label.visible = false
	main_safe_area.visible = true
	show_page(MenuPage.TITLE)

func show_page(page: MenuPage, play_sound: bool = true) -> void:
	splash_visible = false
	splash_page.visible = false
	build_version_label.visible = false
	main_safe_area.visible = true
	_set_background(hub_background, 0.18 if page == MenuPage.TITLE else 0.48)
	if page != current_page and page_shells.has(current_page):
		(page_shells[current_page] as UiPageShell).remember_focus()
	current_page = page
	title_page.visible = page == MenuPage.TITLE
	game_setup_page.visible = page == MenuPage.GAME_SETUP
	shop_page.visible = page == MenuPage.SHOP
	achievements_page.visible = page == MenuPage.ACHIEVEMENTS
	codex_page.visible = page == MenuPage.CODEX
	if play_sound:
		AudioManager.play_ui()
	match page:
		MenuPage.TITLE:
			var title_focus := title_return_focus if is_instance_valid(title_return_focus) and title_return_focus.is_visible_in_tree() else %GameMenuButton
			_request_focus(title_focus)
		MenuPage.GAME_SETUP:
			var selected_candidate_button := _selected_choice_button(candidate_choice_buttons, core_option)
			var setup_focus: Control = selected_candidate_button if campaign_choice_section.visible and selected_candidate_button != null else core_option
			_restore_page_focus(page_shells[page] as UiPageShell, setup_focus)
		MenuPage.SHOP:
			_restore_page_focus(page_shells[page] as UiPageShell, (page_shells[page] as UiPageShell).back_button)
		MenuPage.ACHIEVEMENTS:
			achievement_browser.refresh()
			achievement_browser.restore_view_state()
			_restore_page_focus(page_shells[page] as UiPageShell, (page_shells[page] as UiPageShell).back_button)
		MenuPage.CODEX:
			codex_browser.refresh()
			codex_browser.restore_view_state()
			var current_category_button := codex_category_buttons.get(codex_browser.current_category, codex_category_buttons[&"core"]) as Button
			current_category_button.set_pressed_no_signal(true)
			_restore_page_focus(page_shells[page] as UiPageShell, current_category_button)

func _request_focus(control: Control) -> void:
	if directional_focus_active and is_instance_valid(control):
		control.grab_focus.call_deferred()
	else:
		_clear_gui_focus.call_deferred()

func _restore_page_focus(shell: UiPageShell, fallback: Control) -> void:
	if directional_focus_active:
		shell.restore_focus(fallback)
	else:
		_clear_gui_focus.call_deferred()

func _clear_gui_focus() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()

func _return_to_title() -> void:
	if current_page == MenuPage.ACHIEVEMENTS and achievement_browser != null:
		achievement_browser.remember_view_state()
	elif current_page == MenuPage.CODEX and codex_browser != null:
		codex_browser.remember_view_state()
	_update_records()
	_refresh_meta_navigation()
	show_page(MenuPage.TITLE)

func _refresh_meta_navigation() -> void:
	var tutorial_locked := not SaveManager.tutorial_completed
	%ShopMenuButton.disabled = tutorial_locked or not MetaProgressionService.is_feature_unlocked(&"shop_system")
	%AchievementMenuButton.disabled = tutorial_locked or not MetaProgressionService.is_feature_unlocked(&"achievement_system")
	%CodexMenuButton.disabled = tutorial_locked or not MetaProgressionService.is_feature_unlocked(&"codex_system")
	var game_title := String(%GameMenuButton.get_meta(&"hub_title", %GameMenuButton.text))
	%GameMenuButton.text = "튜토리얼 시작" if tutorial_locked else game_title
	for button in [%ShopMenuButton, %AchievementMenuButton, %CodexMenuButton]:
		var menu_button := button as Button
		var base_title := String(menu_button.get_meta(&"hub_title", menu_button.text))
		menu_button.text = "%s  ·  잠김" % base_title if menu_button.disabled else base_title

func _refresh_shop() -> void:
	shop_balance.text = "보유 %s  %d" % [ConceptService.term(&"currency"), SaveManager.defense_funds]
	if page_shells.has(MenuPage.SHOP):
		var shop_shell := page_shells[MenuPage.SHOP] as UiPageShell
		shop_shell.status_label.text = shop_balance.text
		shop_shell.status_label.visible = true
	for child in shop_product_list.get_children():
		child.queue_free()
	for product in MetaProgressionService.get_shop_products():
		var state := MetaProgressionService.get_product_state(product)
		if state == &"HIDDEN":
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 70.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color("dce8e9"))
		button.add_theme_color_override("font_disabled_color", Color("9fb0b3"))
		button.text = _shop_product_text(product, state)
		button.tooltip_text = product.description
		button.disabled = state != &"DISCOVERED" or SaveManager.defense_funds < product.price
		var accent := UiTokens.FACTION_RETAINER if state == &"PURCHASED" else (UiTokens.ACCENT_GOLD if state == &"DISCOVERED" else UiTokens.DISABLED_INK)
		UiStyleFactory.apply_button(button, accent, state == &"PURCHASED")
		button.custom_minimum_size.y = 78.0
		if not button.disabled:
			button.pressed.connect(_purchase_product.bind(product.id))
		shop_product_list.add_child(button)

func _shop_product_text(product: ShopProductData, state: StringName) -> String:
	var state_text := ""
	match state:
		&"PURCHASED": state_text = "구매 완료"
		&"DISCOVERED":
			state_text = "구매 가능" if SaveManager.defense_funds >= product.price else "자금 %d 부족" % (product.price - SaveManager.defense_funds)
		&"DEV_GRANTED": state_text = "DEV 사용 중 · 발견 필요"
		_:
			var achievement := MetaProgressionService.get_achievement(product.discovery_achievement_id)
			state_text = "잠김 · %s" % (achievement.description if achievement != null else "발견 조건 확인 필요")
	return "%s  ·  %d %s  ·  %s\n%s" % [product.display_name, product.price, ConceptService.term(&"currency"), state_text, product.description]

func _purchase_product(product_id: StringName) -> void:
	var purchase := MetaProgressionService.purchase_product(product_id)
	shop_notice.text = String(purchase.get("reason", ""))
	shop_notice.modulate = Color("65e09e") if bool(purchase.get("purchased", false)) else Color("ffcf58")
	_refresh_shop()
	_refresh_achievements()
	_refresh_codex()
	_refresh_meta_navigation()
	_update_records()

func _refresh_achievements() -> void:
	if achievement_browser != null:
		achievement_browser.refresh()

func _refresh_codex() -> void:
	if codex_browser != null:
		codex_browser.refresh()

func _setup_meta_browsers() -> void:
	achievement_panel.custom_minimum_size = Vector2(1120.0, 520.0)
	achievement_host.alignment = BoxContainer.ALIGNMENT_BEGIN
	for child in achievement_host.get_children():
		child.visible = false
	achievement_browser = AchievementBrowser.new()
	achievement_browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	achievement_host.add_child(achievement_browser)

	codex_panel.custom_minimum_size = Vector2(1120.0, 520.0)
	codex_page_subtitle.text = "후보·심복·병력·편대·난입자와 용어·전투 규칙을 열람합니다."
	if page_shells.has(MenuPage.CODEX):
		(page_shells[MenuPage.CODEX] as UiPageShell).subtitle_label.text = codex_page_subtitle.text
	codex_host.alignment = BoxContainer.ALIGNMENT_BEGIN
	for child in codex_host.get_children():
		child.visible = false
	codex_browser = CodexBrowser.new()
	codex_browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	codex_host.add_child(codex_browser)

	var categories := codex_categories
	var formation_button := Button.new()
	formation_button.name = "Formation"
	formation_button.text = ConceptService.term(&"formation")
	formation_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories.add_child(formation_button)
	categories.move_child(formation_button, 3)
	var terms_button := Button.new()
	terms_button.name = "Terms"
	terms_button.text = "용어·규칙"
	terms_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories.add_child(terms_button)
	var group := ButtonGroup.new()
	codex_category_buttons = {
		&"core": categories.get_node("Core"),
		&"cursor": categories.get_node("Cursor"),
		&"tower": categories.get_node("Tower"),
		&"formation": formation_button,
		&"enemy": categories.get_node("Enemy"),
		&"terms": terms_button,
	}
	(codex_category_buttons[&"core"] as Button).text = ConceptService.term(&"core")
	(codex_category_buttons[&"cursor"] as Button).text = ConceptService.term(&"cursor")
	(codex_category_buttons[&"tower"] as Button).text = ConceptService.term(&"tower")
	(codex_category_buttons[&"enemy"] as Button).text = ConceptService.term(&"enemy")
	for category in codex_category_buttons:
		var button := codex_category_buttons[category] as Button
		button.disabled = false
		button.toggle_mode = true
		button.button_group = group
		UiStyleFactory.apply_button(button, UiTokens.INK_ROYAL, category == &"core")
		button.pressed.connect(_select_codex_category.bind(category))
	(codex_category_buttons[&"core"] as Button).set_pressed_no_signal(true)

func _select_codex_category(category: StringName) -> void:
	if codex_browser != null:
		codex_browser.remember_view_state()
	if codex_category_buttons.has(category):
		for category_id in codex_category_buttons:
			var category_button := codex_category_buttons[category_id] as Button
			var selected: bool = category_id == category
			category_button.set_pressed_no_signal(selected)
			UiStyleFactory.apply_button(category_button, UiTokens.INK_ROYAL, selected)
		var button := codex_category_buttons[category] as Button
		_request_focus(button)
	codex_browser.show_category(category)
	codex_browser.restore_view_state()
	AudioManager.play_ui()

func _fill_option(option: OptionButton, items: Array) -> void:
	option.clear()
	var campaign := ConceptService.get_election_campaign()
	for item in items:
		var unlocked := true
		if item is CoreData:
			unlocked = MetaProgressionService.is_core_unlocked(item.id)
		elif item is CursorData:
			unlocked = MetaProgressionService.is_cursor_unlocked(item.id)
		var display_name: String = item.display_name
		if campaign != null:
			if item is CoreData:
				var candidate := campaign.candidate_for_core(item.id)
				if candidate != null:
					display_name = "%s · %s" % [candidate.short_name, candidate.title]
			elif item is CursorData:
				var retainer := campaign.retainer_for_cursor(item.id)
				if retainer != null:
					display_name = "%s · %s" % [retainer.short_name, retainer.title]
		var label: String = display_name if unlocked else "잠김 · %s" % display_name
		# 고해상도 목표지점 원본을 OptionButton 아이콘으로 직접 넣으면
		# 컨트롤의 최소 크기가 이미지 크기까지 확장되어 화면 전체를 덮는다.
		option.add_item(label)
		option.set_item_metadata(option.item_count - 1, item.id)
		option.set_item_disabled(option.item_count - 1, not unlocked)

func _select_configured_item(option: OptionButton, configured_id: StringName) -> void:
	for index in option.item_count:
		if option.get_item_metadata(index) == configured_id and not option.is_item_disabled(index):
			option.select(index)
			return

func _build_campaign_choice_cards() -> void:
	for child in candidate_choice_list.get_children():
		child.queue_free()
	for child in retainer_choice_list.get_children():
		child.queue_free()
	candidate_choice_buttons.clear()
	retainer_choice_buttons.clear()
	var campaign := ConceptService.get_election_campaign()
	var has_campaign := campaign != null
	campaign_choice_section.visible = has_campaign
	%CoreLabel.visible = not has_campaign
	core_option.visible = not has_campaign
	%CursorLabel.visible = not has_campaign
	cursor_option.visible = not has_campaign
	if not has_campaign:
		return
	candidate_choice_group = ButtonGroup.new()
	retainer_choice_group = ButtonGroup.new()
	for candidate in campaign.candidates:
		if candidate == null:
			continue
		var core := DataRegistry.find_core(candidate.core_id)
		if core == null:
			continue
		var faction := campaign.faction(candidate.faction_id)
		var accent := faction.primary_color if faction != null else core.color
		var unlocked := MetaProgressionService.is_core_unlocked(core.id)
		var candidate_index := campaign.candidates.find(candidate)
		var candidate_lock_reason := "잠김 · 이전 후보로 표준 유세 최초 승리"
		if candidate_index <= 0:
			candidate_lock_reason = "기본 해금 후보"
		var button := _campaign_choice_button(
			candidate.id,
			core.id,
			candidate.short_name,
			candidate.title,
			ConceptService.content_texture(&"candidates", candidate.id),
			accent,
			faction.marker_display_name() if faction != null else "후보",
			unlocked,
			"%s\n%s\n%s" % [candidate.full_name, candidate.description, candidate.campaign_slogan],
			candidate_lock_reason
		)
		button.button_group = candidate_choice_group
		button.pressed.connect(_select_campaign_core.bind(core.id))
		candidate_choice_list.add_child(button)
		candidate_choice_buttons[core.id] = button
	for retainer in campaign.retainers:
		if retainer == null:
			continue
		var cursor := DataRegistry.get_cursor(retainer.cursor_id)
		if cursor == null or cursor.id != retainer.cursor_id:
			continue
		var unlocked := MetaProgressionService.is_cursor_unlocked(cursor.id)
		var preferred_candidate := campaign.candidate(retainer.preferred_candidate_id)
		var retainer_faction := campaign.faction(preferred_candidate.faction_id) if preferred_candidate != null else null
		var retainer_index := campaign.retainers.find(retainer)
		var retainer_lock_reason := "잠김 · 이전 심복으로 표준 유세 최초 승리"
		if retainer_index <= 0:
			retainer_lock_reason = "기본 해금 심복"
		var button := _campaign_choice_button(
			retainer.id,
			cursor.id,
			retainer.short_name,
			retainer.title,
			ConceptService.content_texture(&"retainers", retainer.id),
			retainer_faction.primary_color if retainer_faction != null else cursor.color,
			retainer_faction.marker_display_name() if retainer_faction != null else "심복",
			unlocked,
			"%s\n%s" % [retainer.full_name, retainer.description],
			retainer_lock_reason
		)
		button.button_group = retainer_choice_group
		button.pressed.connect(_select_campaign_cursor.bind(cursor.id))
		retainer_choice_list.add_child(button)
		retainer_choice_buttons[cursor.id] = button
	_sync_campaign_choice_buttons()

func _campaign_choice_button(
	profile_id: StringName,
	content_id: StringName,
	short_name: String,
	title: String,
	portrait: Texture2D,
	accent: Color,
	marker_label: String,
	unlocked: bool,
	tooltip: String,
	lock_reason: String
) -> Button:
	var button := Button.new()
	button.name = "Choice_%s" % profile_id
	button.custom_minimum_size = Vector2(200.0, 62.0)
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.icon = portrait
	button.text = "%s\n%s · %s\n%s" % [short_name, title, marker_label, "해금 · 선택 가능" if unlocked else "잠김 · 최초 승리 필요"]
	button.tooltip_text = tooltip if unlocked else "%s\n\n%s" % [lock_reason, tooltip]
	button.disabled = not unlocked
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiStyleFactory.apply_button(button, accent)
	button.add_theme_font_size_override("font_size", 12)
	button.set_meta(&"content_id", content_id)
	button.set_meta(&"lock_reason", "" if unlocked else lock_reason)
	return button

func _on_core_option_selected(_index: int) -> void:
	_update_description()

func _on_cursor_option_selected(_index: int) -> void:
	_update_description()

func _select_campaign_core(core_id: StringName) -> void:
	_select_configured_item(core_option, core_id)
	_update_description()
	AudioManager.play_ui()

func _select_campaign_cursor(cursor_id: StringName) -> void:
	_select_configured_item(cursor_option, cursor_id)
	_update_description()
	AudioManager.play_ui()

func _selected_choice_button(buttons: Dictionary, option: OptionButton) -> Button:
	if option.item_count == 0 or option.selected < 0:
		return null
	return buttons.get(StringName(option.get_item_metadata(option.selected))) as Button

func _sync_campaign_choice_buttons() -> void:
	if not campaign_choice_section.visible:
		return
	var candidate_button := _selected_choice_button(candidate_choice_buttons, core_option)
	var retainer_button := _selected_choice_button(retainer_choice_buttons, cursor_option)
	if candidate_button != null:
		candidate_button.set_pressed_no_signal(true)
		candidate_choice_scroll.ensure_control_visible.call_deferred(candidate_button)
	if retainer_button != null:
		retainer_button.set_pressed_no_signal(true)
		retainer_choice_scroll.ensure_control_visible.call_deferred(retainer_button)

func _update_description() -> void:
	if core_option.item_count == 0 or cursor_option.item_count == 0:
		return
	var core: CoreData = DataRegistry.get_core(core_option.get_item_metadata(core_option.selected))
	var cursor: CursorData = DataRegistry.get_cursor(cursor_option.get_item_metadata(cursor_option.selected))
	var campaign := ConceptService.get_election_campaign()
	_refresh_hub_identity(core, cursor, campaign)
	_sync_campaign_choice_buttons()
	campaign_profile_section.visible = campaign != null
	description_label.visible = campaign == null
	if campaign != null:
		_update_campaign_profile_cards(campaign, core, cursor)
		return
	var unique_tower := DataRegistry.find_tower(core.unique_tower_id)
	var unique_formation := DataRegistry.find_formation(core.unique_formation_id)
	var unique_line := ""
	if unique_tower != null and unique_formation != null:
		unique_line = "\n전용 공명 %s · %s / %s (런당 1회)" % [ConceptService.term(&"formation"), unique_formation.display_name, unique_tower.display_name]
	description_label.text = "%s · %s\n%s%s\n\n%s · %s  ·  이동속도 %.0f\n%s\n\n%s은 지정한 위치까지 고유 속도로 이동하며 자동 공격·경험치 회수를 수행합니다.\n%s %s는 전투 중 레벨업으로 설치합니다." % [
		ConceptService.term(&"core"), core.display_name, core.description, unique_line,
		ConceptService.term(&"cursor"), cursor.display_name, cursor.movement_speed, cursor.description,
		ConceptService.term(&"cursor"), ConceptService.term(&"tower"), ConceptService.term(&"formation"),
	]

func _refresh_hub_identity(core: CoreData, cursor: CursorData, campaign: ElectionCampaignData) -> void:
	if campaign != null:
		var candidate := campaign.candidate_for_core(core.id)
		var retainer := campaign.retainer_for_cursor(cursor.id)
		if candidate != null and retainer != null:
			hub_candidate_portrait.texture = ConceptService.content_texture(&"candidates", candidate.id)
			hub_candidate_name.text = "현재 후보 · %s" % candidate.short_name
			hub_candidate_meta.text = "심복 %s  ·  지지도 %d  ·  %s %d" % [
				retainer.short_name,
				SaveManager.get_candidate_support(candidate.id),
				ConceptService.term(&"currency"),
				SaveManager.defense_funds,
			]
			return
	hub_candidate_portrait.texture = ConceptService.content_texture(&"cores", core.id)
	hub_candidate_name.text = "현재 %s · %s" % [ConceptService.term(&"core"), core.display_name]
	hub_candidate_meta.text = "%s %s  ·  %s %d" % [
		ConceptService.term(&"cursor"), cursor.display_name,
		ConceptService.term(&"currency"), SaveManager.defense_funds,
	]

func _update_campaign_profile_cards(campaign: ElectionCampaignData, core: CoreData, cursor: CursorData) -> void:
	var candidate := campaign.candidate_for_core(core.id)
	var retainer := campaign.retainer_for_cursor(cursor.id)
	if candidate == null or retainer == null:
		campaign_profile_section.visible = false
		description_label.visible = true
		description_label.text = "선택한 출격 데이터에 연결된 후보 또는 심복 프로필이 없습니다."
		return
	var faction := campaign.faction(candidate.faction_id)
	var candidate_color := faction.primary_color if faction != null else core.color
	var preferred_pair := candidate.default_retainer_id == retainer.id and retainer.preferred_candidate_id == candidate.id

	candidate_portrait.texture = ConceptService.content_texture(&"candidates", candidate.id)
	candidate_emblem.texture = ConceptService.content_texture(&"emblems", candidate.emblem_id)
	candidate_name.text = "마왕 후보 · %s · %s" % [candidate.short_name, faction.marker_display_name() if faction != null else "독립"]
	candidate_title.text = candidate.title
	candidate_slogan.text = "“%s”" % candidate.campaign_slogan
	var candidate_support := SaveManager.get_candidate_support(candidate.id)
	var elected := SaveManager.is_candidate_elected(candidate.id)
	var approval := SaveManager.get_governance_approval(candidate.id)
	var governance_reaction := campaign.governance_reaction(approval) if elected else null
	var election_state := (
		"당선 · 통치 %s %d" % [governance_reaction.display_name, approval]
		if governance_reaction != null else
		("당선" if elected else "지지 %d/%d" % [candidate_support, candidate.support_required_for_election])
	)
	candidate_stats.text = "%s%s" % [
		election_state,
		" · 기본 조합" if preferred_pair else "",
	]
	candidate_card.tooltip_text = "%s\n%s\n체력 %.0f · 액티브 %.1f초" % [candidate.full_name, candidate.description, core.max_health, core.skill_cast_seconds]
	if governance_reaction != null:
		candidate_card.tooltip_text += "\n\n통치 반응 · %s %d\n%s" % [governance_reaction.display_name, approval, governance_reaction.battle_chant]
	_configure_decree_selector(candidate)
	candidate_card.add_theme_stylebox_override("panel", _profile_card_style(candidate_color))
	candidate_name.add_theme_color_override("font_color", candidate_color.darkened(0.28))
	candidate_title.add_theme_color_override("font_color", UiTokens.INK_MUTED)
	candidate_slogan.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	candidate_stats.add_theme_color_override("font_color", candidate_color.darkened(0.24))

	retainer_portrait.texture = ConceptService.content_texture(&"retainers", retainer.id)
	retainer_name.text = "수석 심복 · %s" % retainer.short_name
	retainer_title.text = retainer.title
	var action_summary := _retainer_action_summary(retainer)
	retainer_description.text = "기본 행동 · %s" % action_summary
	retainer_stats.text = "이동 %.0f · 피해 %.0f · 넉백 %.0f%s" % [
		cursor.movement_speed, cursor.damage, cursor.knockback,
		" · 후보 선호 일치" if preferred_pair else "",
	]
	retainer_card.tooltip_text = "%s\n%s\n\n기본 행동 · %s" % [retainer.full_name, retainer.description, action_summary]
	retainer_card.add_theme_stylebox_override("panel", _profile_card_style(cursor.color))
	retainer_name.add_theme_color_override("font_color", cursor.color.darkened(0.28))
	retainer_title.add_theme_color_override("font_color", UiTokens.INK_MUTED)
	retainer_description.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	retainer_stats.add_theme_color_override("font_color", cursor.color.darkened(0.24))

	var rivals: PackedStringArray = []
	for rival_faction in campaign.factions:
		if rival_faction != null and rival_faction.id != candidate.faction_id:
			rivals.append(rival_faction.display_name)
	var plan_note := "고정 난입 계획" if campaign.expected_candidate_count <= campaign.expected_boss_slot_count else "출격 시 난입 순서 확정"
	campaign_rival_preview.text = "경쟁 진영 · %s  |  %d후보 수직 절편 · %s" % [
		" / ".join(rivals), campaign.expected_candidate_count, plan_note,
	]
	campaign_rival_preview.add_theme_color_override(&"font_color", UiTokens.INK_MUTED)

func _retainer_action_summary(retainer: RetainerProfileData) -> String:
	match retainer.action_profile_id if retainer != null else &"":
		&"kanda_sword": return "근접 검격 · 넉백 · 상태/회오리 특화"
		&"given_whip": return "채찍 · 출혈/넉백/환혹 · 연격당 환혹 1회"
		&"jeomujeom_abyss_zone": return "지속 장판 · 둔화/공포 · 위치 재소환 특화"
		&"jugdied_cavalry": return "기마 참격 · 후보 액티브 합동 돌격 · 재구성"
		&"death_vanguard_squad": return "인원 비례 중공격 · 처형/충원 · 부대 희생 특화"
	return "자동 공격 · 이동 · 유세 열기 회수"

func _configure_decree_selector(candidate: CandidateProfileData) -> void:
	decree_option.clear()
	decree_option.tooltip_text = ""
	if candidate == null or not SaveManager.is_candidate_elected(candidate.id):
		decree_option.add_item("당선 후 칙령")
		decree_option.disabled = true
		candidate_slogan.text += "\n칙령 잠김 · 후보 당선 후 정책 효과를 선택할 수 있습니다."
		return
	var decrees := MetaProgressionService.get_candidate_decrees(candidate.id)
	var selected_id := MetaProgressionService.ensure_candidate_decree(candidate.id)
	if selected_id == &"":
		decree_option.add_item("칙령 선택")
		decree_option.set_item_disabled(0, true)
	for decree in decrees:
		decree_option.add_item(decree.display_name)
		var index := decree_option.item_count - 1
		decree_option.set_item_metadata(index, decree.id)
		decree_option.set_item_tooltip(index, "%s\n%s" % [decree.description, decree.effect_summary])
		if decree.id == selected_id:
			decree_option.select(index)
			decree_option.tooltip_text = "%s\n%s" % [decree.description, decree.effect_summary]
			candidate_card.tooltip_text += "\n\n칙령 · %s\n%s" % [decree.display_name, decree.effect_summary]
			candidate_slogan.text = "칙령 · %s\n%s" % [decree.display_name, decree.effect_summary]
	decree_option.disabled = decrees.is_empty()

func _on_decree_selected(index: int) -> void:
	var decree_id := StringName(decree_option.get_item_metadata(index))
	var campaign := ConceptService.get_election_campaign()
	if decree_id == &"" or campaign == null or core_option.selected < 0:
		return
	var candidate := campaign.candidate_for_core(StringName(core_option.get_item_metadata(core_option.selected)))
	if candidate == null or not MetaProgressionService.select_candidate_decree(candidate.id, decree_id):
		_configure_decree_selector(candidate)
		return
	GameSession.selected_decree_id = decree_id
	var decree := campaign.decree(decree_id)
	if decree != null:
		decree_option.tooltip_text = "%s\n%s" % [decree.description, decree.effect_summary]
		candidate_card.tooltip_text = "%s\n%s\n\n칙령 · %s\n%s" % [candidate.full_name, candidate.description, decree.display_name, decree.effect_summary]
		candidate_slogan.text = "칙령 · %s\n%s" % [decree.display_name, decree.effect_summary]
	AudioManager.play_ui()

func _profile_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.12)
	style.border_color = Color(accent, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12.0
	style.content_margin_top = 9.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 9.0
	return style

func _configure_challenge_selector() -> void:
	var stage_id := _stage_id()
	var unlocked := SaveManager.is_challenge_unlocked(stage_id)
	challenge_label.visible = true
	challenge_controls.visible = unlocked
	challenge_description.visible = not unlocked
	challenge_description.text = "도전 단계 잠김 · 표준 10분 유세를 한 번 완주하면 최대 단계와 추가 제약이 공개됩니다."
	challenge_slider.editable = unlocked
	var maximum := SaveManager.get_max_selectable_challenge(stage_id)
	challenge_slider.max_value = maximum
	challenge_slider.tick_count = maximum + 1
	var initial_level := SaveManager.get_selected_challenge(stage_id) if unlocked else 0
	challenge_slider.set_value_no_signal(initial_level)
	_on_challenge_changed(initial_level)

func _set_challenge_level(level: int) -> void:
	if not SaveManager.is_challenge_unlocked(_stage_id()):
		return
	challenge_slider.value = clampi(ChallengeRules.clamp_level(level), 0, SaveManager.get_max_selectable_challenge(_stage_id()))

func _on_challenge_changed(value: float) -> void:
	var unlocked := SaveManager.is_challenge_unlocked(_stage_id())
	var maximum := SaveManager.get_max_selectable_challenge(_stage_id())
	var level := clampi(ChallengeRules.clamp_level(roundi(value)), 0, maximum) if unlocked else 0
	if unlocked and not is_equal_approx(challenge_slider.value, float(level)):
		challenge_slider.set_value_no_signal(level)
	%ChallengeDecrease.disabled = not unlocked or level <= 0
	%ChallengeIncrease.disabled = not unlocked or level >= maximum
	challenge_value_label.text = "도전 %d단계" % level if unlocked else "잠김"
	var challenge_detail := "%s  ·  현재 선택 가능: 0~%d단계" % [ChallengeRules.summary(level), maximum]
	challenge_summary.text = challenge_detail if unlocked else ""
	challenge_summary.tooltip_text = challenge_detail if unlocked else ""
	challenge_controls.tooltip_text = challenge_detail if unlocked else ""
	var stage := ConceptService.get_default_stage()
	var stage_name := stage.display_name if stage != null else "10분 방어"
	%StartButton.text = "%s 시작 · 도전 %d단계" % [stage_name, level] if unlocked else "%s 시작" % stage_name

func _update_records() -> void:
	var minutes := floori(SaveManager.best_time) / 60
	var seconds := floori(SaveManager.best_time) % 60
	var highest_challenge := SaveManager.get_highest_challenge(_stage_id())
	var challenge_record := "잠김" if highest_challenge < 0 else "%d단계" % highest_challenge
	record_label.text = "최고 생존 %02d:%02d  ·  최고 레벨 %d  ·  최고 도전 %s  ·  %s %d  ·  총 출격 %d" % [
		minutes, seconds, SaveManager.best_level, challenge_record, ConceptService.term(&"currency"), SaveManager.defense_funds, SaveManager.total_runs,
	]

func _apply_concept_profile() -> void:
	var concept := ConceptService.active
	if concept == null:
		return
	title_background = ConceptService.texture(&"title_background")
	hub_background = ConceptService.texture(&"main_hub_background")
	concept_overlay_color = concept.background_overlay
	_set_background(title_background, 0.34)
	%SplashTitle.text = concept.project_title
	%SplashTagline.text = concept.hero_title.replace("\n", " ")
	hub_sector.text = "현재 출격 조합"
	hub_sector.add_theme_color_override("font_color", concept.accent_color)
	hub_title.text = "유세 본부"
	hub_description.text = "후보와 심복을 확인하고 다음 행동을 선택하세요."
	title_status.text = ""
	title_status.visible = false
	title_status.add_theme_color_override("font_color", concept.accent_color)
	var terms := {
		&"core": concept.core_term, &"cursor": concept.cursor_term,
		&"tower": concept.tower_term, &"formation": concept.formation_term,
		&"enemy": concept.enemy_term,
	}
	_configure_hub_action(
		%GameMenuButton,
		"출격 준비",
		ConceptService.ui_text(&"menu.game_subtitle", terms, "출격 선택 · %s / %s" % [concept.core_term, concept.cursor_term])
	)
	_configure_hub_action(
		%ShopMenuButton,
		"병력 확보",
		ConceptService.ui_text(&"menu.shop_subtitle", terms, "구매 목록 · %s" % concept.tower_term)
	)
	_configure_hub_action(
		%AchievementMenuButton,
		ConceptService.ui_text(&"menu.achievements_title", terms, "업적"),
		ConceptService.ui_text(&"menu.achievements_subtitle", terms, "달성한 방어 기록을 확인합니다")
	)
	_configure_hub_action(
		%CodexMenuButton,
		ConceptService.ui_text(&"menu.codex_title", terms, "도감"),
		ConceptService.ui_text(&"menu.codex_subtitle", terms, "%s·%s와 용어·전투 규칙을 열람합니다" % [concept.formation_term, concept.enemy_term])
	)
	$SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/PageTitle.text = ConceptService.ui_text(&"setup.page_title", terms, "출격 설정")
	$SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/PageSubtitle.text = ConceptService.ui_text(&"setup.page_subtitle", terms, "출격 설정 · %s / %s" % [concept.core_term, concept.cursor_term])
	$SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/Selectors/CoreLabel.text = concept.core_term
	$SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/Selectors/CursorLabel.text = concept.cursor_term
	$SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/Selectors/CoreLabel.add_theme_color_override("font_color", concept.accent_color)
	$SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/Selectors/CursorLabel.add_theme_color_override("font_color", concept.secondary_color)
	$SafeArea/Shell/Pages/ShopPage/Center/Panel/Content/Title.text = ConceptService.ui_text(&"menu.shop_title", terms, "상점")
	$SafeArea/Shell/Pages/ShopPage/Center/Panel/Content/Subtitle.text = ConceptService.ui_text(&"setup.shop_hint", terms, "원하는 %s을 자유 구매하면 관련 편대가 다음 출격부터 자동 적격화됩니다." % concept.tower_term)
	$SafeArea/Shell/Pages/AchievementsPage/Center/Panel/Content/PageTitle.text = ConceptService.ui_text(&"menu.achievements_title", terms, "업적")
	$SafeArea/Shell/Pages/AchievementsPage/Center/Panel/Content/PageSubtitle.text = ConceptService.ui_text(&"menu.achievements_subtitle", terms, "달성한 방어 기록을 확인합니다")
	$SafeArea/Shell/Pages/CodexPage/Center/Panel/Content/PageTitle.text = ConceptService.ui_text(&"menu.codex_title", terms, "도감")
	$SafeArea/Shell/Pages/CodexPage/Center/Panel/Content/PageSubtitle.text = ConceptService.ui_text(&"menu.codex_subtitle", terms, "%s·%s와 용어·전투 규칙을 열람합니다" % [concept.formation_term, concept.enemy_term])

func _apply_concept_failure_state() -> void:
	if ConceptService.active != null:
		return
	var build_id := BUILD_INFO.display_text()
	var detail := ConceptService.get_load_error_summary()
	var message := "콘텐츠 로드 오류 [CONTENT-PROFILE] · %s" % build_id
	if not detail.is_empty():
		message += "\n%s" % detail
	title_status.text = message
	title_status.visible = true
	%GameMenuButton.text = "출격 불가 · 콘텐츠 오류"
	%GameMenuButton.tooltip_text = message
	%GameMenuButton.disabled = true
	%StartButton.disabled = true
	push_warning(message)

func _configure_hub_action(button: Button, action_title: String, description: String) -> void:
	button.text = action_title
	button.tooltip_text = description
	button.set_meta(&"hub_title", action_title)

func _set_background(texture: Texture2D, overlay_alpha: float) -> void:
	background.texture = texture if texture != null else ConceptService.texture(&"menu_background")
	background_overlay.color = Color(concept_overlay_color.r, concept_overlay_color.g, concept_overlay_color.b, overlay_alpha)

func _start_game() -> void:
	if ConceptService.active == null or ConceptService.get_default_stage() == null:
		_apply_concept_failure_state()
		return
	if core_option.item_count == 0 or cursor_option.item_count == 0:
		title_status.text = "출격 선택 오류 [RUN-SELECTION] · 후보/심복 데이터를 확인해 주세요."
		title_status.visible = true
		return
	if checkpoint_recovery_blocked and not _recover_pending_checkpoint():
		show_page(MenuPage.TITLE)
		return
	var stage_id := _stage_id()
	var challenge_level := clampi(ChallengeRules.clamp_level(roundi(challenge_slider.value)), 0, SaveManager.get_max_selectable_challenge(stage_id)) if SaveManager.is_challenge_unlocked(stage_id) else 0
	SaveManager.set_selected_challenge(stage_id, challenge_level)
	GameSession.configure(
		core_option.get_item_metadata(core_option.selected),
		cursor_option.get_item_metadata(cursor_option.selected),
		challenge_level
	)
	var scene_change_error := get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	if scene_change_error != OK:
		title_status.text = "게임 화면 전환 오류 [RUN-SCENE-%d] · %s" % [scene_change_error, BUILD_INFO.display_text()]
		title_status.visible = true
		push_error(title_status.text)

func _stage_id() -> StringName:
	var stage := ConceptService.get_default_stage()
	return stage.id if stage != null and stage.id != &"" else FALLBACK_STAGE_ID
