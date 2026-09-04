class_name AchievementBrowser
extends VBoxContainer

const TAG_SCENE := preload("res://scenes/ui/components/tag_chip.tscn")

const FILTERS: Array[Dictionary] = [
	{"id": &"all", "label": "전체"},
	{"id": &"start", "label": "시작"},
	{"id": &"tower", "label": "수비병력"},
	{"id": &"status", "label": "상태이상"},
	{"id": &"boss", "label": "공식 난입"},
	{"id": &"challenge", "label": "도전"},
]

var current_filter: StringName = &"all"
var counter_label: Label
var achievement_list: VBoxContainer
var scroll_container: ScrollContainer
var filter_buttons: Dictionary = {}
var scroll_positions: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build_ui()
	refresh()

func _build_ui() -> void:
	var summary := HBoxContainer.new()
	counter_label = Label.new()
	counter_label.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	counter_label.add_theme_font_size_override("font_size", 18)
	summary.add_child(counter_label)
	var summary_spacer := Control.new()
	summary_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(summary_spacer)
	var settlement_note := Label.new()
	settlement_note.text = "보상은 결과 정산 시 자동 지급"
	settlement_note.add_theme_color_override("font_color", UiTokens.INK_MUTED)
	summary.add_child(settlement_note)
	add_child(summary)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 7)
	var group := ButtonGroup.new()
	for data in FILTERS:
		var button := Button.new()
		button.text = ConceptService.term(&"tower") if data.id == &"tower" else data.label
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyleFactory.apply_button(button, UiTokens.INK_ROYAL, data.id == current_filter)
		button.pressed.connect(_set_filter.bind(data.id))
		filters.add_child(button)
		filter_buttons[data.id] = button
	add_child(filters)
	(filter_buttons[current_filter] as Button).set_pressed_no_signal(true)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.scroll_deadzone = 12
	achievement_list = VBoxContainer.new()
	achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievement_list.add_theme_constant_override("separation", 8)
	scroll_container.add_child(achievement_list)
	add_child(scroll_container)

func refresh() -> void:
	if achievement_list == null:
		return
	for child in achievement_list.get_children():
		child.free()
	var catalog := MetaProgressionService.get_achievements()
	var completed := 0
	var visible_count := 0
	for achievement in catalog:
		var state := MetaProgressionService.get_achievement_state(achievement)
		if bool(state.get("completed", false)):
			completed += 1
		if not _matches_filter(achievement):
			continue
		achievement_list.add_child(_make_card(achievement, state))
		visible_count += 1
	counter_label.text = "달성 %d / %d   ·   현재 분류 %d개" % [completed, catalog.size(), visible_count]

func get_visible_entry_count() -> int:
	return achievement_list.get_child_count() if achievement_list != null else 0

func _set_filter(filter_id: StringName) -> void:
	remember_view_state()
	current_filter = filter_id
	refresh()
	scroll_positions[current_filter] = 0
	for id in filter_buttons:
		var selected: bool = id == current_filter
		var button := filter_buttons[id] as Button
		button.set_pressed_no_signal(selected)
		UiStyleFactory.apply_button(button, UiTokens.INK_ROYAL, selected)
	restore_view_state()
	AudioManager.play_ui()

func remember_view_state() -> void:
	if scroll_container != null:
		scroll_positions[current_filter] = scroll_container.scroll_vertical

func restore_view_state() -> void:
	if scroll_container == null:
		return
	var target := int(scroll_positions.get(current_filter, 0))
	scroll_container.set_deferred(&"scroll_vertical", target)

func get_scroll_position() -> int:
	return scroll_container.scroll_vertical if scroll_container != null else 0

func _matches_filter(achievement: AchievementData) -> bool:
	if current_filter == &"all":
		return true
	if current_filter == &"challenge":
		return achievement.category == &"challenge"
	return achievement.category == current_filter

func _make_card(achievement: AchievementData, state: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 104.0)
	var completed := bool(state.get("completed", false))
	var available := bool(state.get("available", true))
	panel.add_theme_stylebox_override("panel", UiStyleFactory.panel(
		UiTokens.SURFACE_PARCHMENT_MUTED.lerp(UiTokens.FACTION_RETAINER, 0.16) if completed else UiTokens.SURFACE_PARCHMENT,
		UiTokens.FACTION_RETAINER if completed else UiTokens.INK_MUTED,
		UiTokens.RADIUS_CARD,
		2 if completed else 1,
		12.0
	))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)

	var header := HBoxContainer.new()
	var title := Label.new()
	var secret := achievement.hidden and not completed
	title.text = "숨겨진 업적" if secret else achievement.display_name
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", UiTokens.FACTION_RETAINER.darkened(0.22) if completed else UiTokens.INK_ROYAL)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var status := TAG_SCENE.instantiate() as UiTagChip
	var status_text := "✓ 달성·지급 완료" if completed else ("잠김 · 선행 조건 대기" if not available else "진행 중 · %s" % _category_name(achievement.category))
	var status_accent := UiTokens.FACTION_RETAINER if completed else (UiTokens.DANGER if not available else UiTokens.ACCENT_GOLD)
	header.add_child(status)
	status.configure(status_text, status_accent)
	content.add_child(header)

	var description := Label.new()
	description.text = "조건을 충족하면 내용이 공개됩니다." if secret else achievement.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	content.add_child(description)

	var progress_row := HBoxContainer.new()
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.max_value = maxf(achievement.target_value, 1.0)
	progress.value = minf(float(state.get("progress", 0.0)), progress.max_value)
	progress.custom_minimum_size = Vector2(0.0, 10.0)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(progress)
	var progress_text := Label.new()
	progress_text.custom_minimum_size.x = 112.0
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_text.text = "완료" if completed else (_progress_text(state, achievement) if available and not secret else "—")
	progress_text.add_theme_color_override("font_color", UiTokens.INK_MUTED)
	progress_row.add_child(progress_text)
	content.add_child(progress_row)

	var reward := Label.new()
	reward.text = "보상 · %s%s" % [_reward_text(achievement), _requirements_text(achievement) if not available else ""]
	reward.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(reward)
	_allow_scroll_drag(panel)
	return panel

func _allow_scroll_drag(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in control.get_children():
		if child is Control:
			_allow_scroll_drag(child as Control)

func _progress_text(state: Dictionary, achievement: AchievementData) -> String:
	var current := minf(float(state.get("progress", 0.0)), achievement.target_value)
	var suffix := "한 런 최고" if achievement.progress_mode in [&"maximum", &"single_run"] else "누적"
	return "%.0f / %.0f · %s" % [current, achievement.target_value, suffix]

func _reward_text(achievement: AchievementData) -> String:
	var rewards: Array[String] = []
	if achievement.reward_funds > 0:
		rewards.append("%s +%d" % [ConceptService.term(&"currency"), achievement.reward_funds])
	for product_id in achievement.discover_product_ids:
		var product := MetaProgressionService.get_shop_product(product_id)
		rewards.append("상품 발견 ‘%s’" % (product.display_name if product != null else String(product_id)))
	for feature_id in achievement.unlock_feature_ids:
		rewards.append("기능 해금 ‘%s’" % _feature_name(feature_id))
	for content_id in achievement.unlock_content_ids:
		rewards.append("콘텐츠 해금 ‘%s’" % String(content_id))
	return " · ".join(rewards) if not rewards.is_empty() else "업적 기록 배지"

func _requirements_text(achievement: AchievementData) -> String:
	var requirements: Array[String] = []
	for product_id in achievement.required_product_ids:
		var product := MetaProgressionService.get_shop_product(product_id)
		requirements.append(product.display_name if product != null else String(product_id))
	if not achievement.required_any_product_ids.is_empty():
		var names: Array[String] = []
		for product_id in achievement.required_any_product_ids:
			var product := MetaProgressionService.get_shop_product(product_id)
			names.append(product.display_name if product != null else String(product_id))
		requirements.append(" 또는 ".join(names))
	return "   ·   선행 구매: %s" % ", ".join(requirements) if not requirements.is_empty() else ""

func _category_name(category: StringName) -> String:
	return {&"start": "시작", &"tower": ConceptService.term(&"tower"), &"status": "상태이상", &"boss": "공식 난입", &"challenge": "도전"}.get(category, String(category))

func _feature_name(feature_id: StringName) -> String:
	return {
		&"shop_system": "상점", &"achievement_system": "업적",
		&"challenge_system": "도전 단계", &"status_growth_poison": "독 성장", &"status_growth_bleed": "출혈 성장",
		&"status_growth_burn": "화상 성장", &"status_growth_shock": "감전 성장", &"codex_system": "도감",
	}.get(feature_id, String(feature_id))
