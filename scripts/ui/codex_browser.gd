class_name CodexBrowser
extends VBoxContainer

const TAG_SCENE := preload("res://scenes/ui/components/tag_chip.tscn")

var current_category: StringName = &"core"
var entries: Array[Dictionary] = []
var counter_label: Label
var entry_list: VBoxContainer
var detail_title: Label
var detail_state: UiTagChip
var detail_description: Label
var detail_axes: HBoxContainer
var detail_stats: RichTextLabel
var detail_related: Label
var detail_icon: TextureRect
var detail_rule_icon: FlatEffectIcon
var detail_faction_emblem: TextureRect
var detail_accent: ColorRect
var selected_key: String = ""
var list_scroll: ScrollContainer
var entry_buttons: Dictionary = {}
var selected_keys: Dictionary = {}
var scroll_positions: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_build_ui()
	refresh()

func show_category(category: StringName) -> void:
	current_category = category
	selected_key = String(selected_keys.get(category, ""))
	refresh()

func refresh() -> void:
	if entry_list == null:
		return
	for child in entry_list.get_children():
		child.free()
	entry_buttons.clear()
	entries = MetaProgressionService.get_codex_entries(current_category)
	var discovered := entries.filter(func(entry: Dictionary) -> bool: return entry.state == &"discovered").size()
	var dev_count := entries.filter(func(entry: Dictionary) -> bool: return entry.state == &"dev").size()
	counter_label.text = "발견 %d / %d%s" % [discovered, entries.size(), "   ·   DEV 열람 %d" % dev_count if dev_count > 0 else ""]
	for entry in entries:
		var button := _make_entry_button(entry)
		entry_list.add_child(button)
		entry_buttons[String(entry.key)] = button
	if entries.is_empty():
		_show_empty()
	else:
		var selected: Dictionary = entries[0]
		for entry in entries:
			if entry.key == selected_key:
				selected = entry
				break
		_select_entry(selected)

func get_entry_count() -> int:
	return entries.size()

func get_selected_entry() -> Dictionary:
	for entry in entries:
		if entry.key == selected_key:
			return entry
	return {}

func _build_ui() -> void:
	counter_label = Label.new()
	counter_label.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	counter_label.add_theme_font_size_override("font_size", 17)
	add_child(counter_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	add_child(body)

	list_scroll = ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 345.0
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entry_list = VBoxContainer.new()
	entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_list.add_theme_constant_override("separation", 6)
	list_scroll.add_child(entry_list)
	body.add_child(list_scroll)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT, UiTokens.INK_MUTED, UiTokens.RADIUS_CARD, 1, 14.0))
	body.add_child(detail_panel)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 7)
	detail_panel.add_child(detail)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	detail.add_child(heading)
	var icon_stack := Control.new()
	icon_stack.custom_minimum_size = Vector2(72.0, 72.0)
	heading.add_child(icon_stack)
	detail_accent = ColorRect.new()
	detail_accent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_accent.color = Color(UiTokens.INK_ROYAL, 0.12)
	icon_stack.add_child(detail_accent)
	detail_icon = TextureRect.new()
	detail_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_stack.add_child(detail_icon)
	detail_rule_icon = FlatEffectIcon.new()
	detail_rule_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_rule_icon.visible = false
	icon_stack.add_child(detail_rule_icon)
	detail_faction_emblem = TextureRect.new()
	detail_faction_emblem.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	detail_faction_emblem.position = Vector2(43.0, 43.0)
	detail_faction_emblem.size = Vector2(27.0, 27.0)
	detail_faction_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_faction_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_faction_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_faction_emblem.visible = false
	icon_stack.add_child(detail_faction_emblem)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_child(title_stack)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 26)
	detail_title.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	title_stack.add_child(detail_title)
	detail_state = TAG_SCENE.instantiate() as UiTagChip
	title_stack.add_child(detail_state)
	detail_state.configure("상태", UiTokens.INK_MUTED)

	detail_description = Label.new()
	detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_description.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	detail.add_child(detail_description)
	detail_axes = HBoxContainer.new()
	detail_axes.name = "DefenseStatAxes"
	detail_axes.add_theme_constant_override("separation", 8)
	detail_axes.visible = false
	detail.add_child(detail_axes)

	detail_stats = RichTextLabel.new()
	detail_stats.bbcode_enabled = true
	detail_stats.fit_content = false
	detail_stats.scroll_active = true
	detail_stats.custom_minimum_size.y = 74.0
	detail_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_stats.add_theme_color_override("default_color", UiTokens.INK_ROYAL)
	detail_stats.add_theme_font_size_override("normal_font_size", 15)
	detail.add_child(detail_stats)

	detail_related = Label.new()
	detail_related.visible = false
	detail_related.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_related.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	detail.add_child(detail_related)

func _make_entry_button(entry: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 62.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.text = "%s  %s\n%s  ·  %s" % [_state_icon(entry.state), entry.title, _state_short_text(entry.state), entry.subtitle]
	button.tooltip_text = entry.unlock_hint if entry.state == &"locked" else entry.description
	var accent := UiTokens.FACTION_RETAINER if entry.state == &"discovered" else (UiTokens.ACCENT_GOLD if entry.state == &"dev" else UiTokens.DISABLED_INK)
	UiStyleFactory.apply_button(button, accent, String(entry.key) == selected_key)
	button.add_theme_font_size_override(&"font_size", 14)
	button.pressed.connect(_select_entry.bind(entry))
	return button

func _select_entry(entry: Dictionary) -> void:
	selected_key = String(entry.key)
	selected_keys[current_category] = selected_key
	for key in entry_buttons:
		var entry_button := entry_buttons[key] as Button
		var selected: bool = key == selected_key
		var entry_state: StringName = &"locked"
		for candidate in entries:
			if String(candidate.key) == key:
				entry_state = candidate.state
				break
		var accent := UiTokens.FACTION_RETAINER if entry_state == &"discovered" else (UiTokens.ACCENT_GOLD if entry_state == &"dev" else UiTokens.DISABLED_INK)
		UiStyleFactory.apply_button(entry_button, accent, selected)
	if entry_buttons.has(selected_key):
		_ensure_entry_visible.call_deferred(selected_key)
	var revealed := bool(entry.revealed)
	detail_state.visible = true
	detail_title.text = String(entry.title) if revealed else "미확인 · %s" % String(entry.title)
	var state_accent := UiTokens.FACTION_RETAINER if entry.state == &"discovered" else (UiTokens.ACCENT_GOLD if entry.state == &"dev" else UiTokens.DANGER)
	detail_state.configure(_state_text(entry.state), state_accent)
	detail_description.text = String(entry.description) if revealed else String(entry.unlock_hint)
	detail_icon.texture = entry.texture if revealed else null
	detail_icon.visible = detail_icon.texture != null
	var color: Color = entry.color
	var icon_key := StringName(entry.get("icon_key", ""))
	detail_rule_icon.visible = revealed and detail_icon.texture == null and icon_key != &""
	if detail_rule_icon.visible:
		detail_rule_icon.configure(icon_key, color)
	var emblem_id := StringName(entry.get("faction_emblem_id", ""))
	detail_faction_emblem.texture = ConceptService.optional_content_texture(&"emblems", emblem_id) if revealed and emblem_id != &"" else null
	detail_faction_emblem.visible = detail_faction_emblem.texture != null
	detail_accent.color = Color(color.r, color.g, color.b, 0.28 if revealed else 0.08)
	_update_defense_stat_axes(entry.get("stat_axes", []) as Array, revealed)
	if revealed:
		var stat_lines: Array[String] = entry.stats
		var related_lines: Array[String] = entry.related
		var related_text := "  /  ".join(related_lines) if not related_lines.is_empty() else "없음"
		detail_stats.text = "[color=#39234f][b]상세 성능[/b][/color]\n%s\n\n[color=#9d671c][b]연관 정보[/b][/color]\n%s" % ["\n".join(stat_lines), related_text]
	else:
		detail_stats.text = "[color=#6f6079]상세 성능은 발견 후 공개됩니다.[/color]\n\n[color=#9d671c][b]해금 힌트[/b][/color]\n%s" % String(entry.unlock_hint)

func remember_view_state() -> void:
	if list_scroll != null:
		scroll_positions[current_category] = list_scroll.scroll_vertical
	if not selected_key.is_empty():
		selected_keys[current_category] = selected_key

func restore_view_state() -> void:
	if list_scroll == null:
		return
	var target := int(scroll_positions.get(current_category, 0))
	list_scroll.set_deferred(&"scroll_vertical", target)
	if entry_buttons.has(selected_key):
		_ensure_entry_visible.call_deferred(selected_key)

func get_scroll_position() -> int:
	return list_scroll.scroll_vertical if list_scroll != null else 0

func _ensure_entry_visible(key: String) -> void:
	if list_scroll == null or not entry_buttons.has(key):
		return
	var button := entry_buttons[key] as Control
	if is_instance_valid(button) and list_scroll.is_ancestor_of(button):
		list_scroll.ensure_control_visible(button)

func _update_defense_stat_axes(axis_presentations: Array, revealed: bool) -> void:
	for child in detail_axes.get_children():
		child.free()
	detail_axes.visible = revealed and not axis_presentations.is_empty()
	if not detail_axes.visible:
		return
	for presentation in axis_presentations:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var color: Color = presentation.color
		var style := StyleBoxFlat.new()
		style.bg_color = Color(color, 0.08)
		style.border_color = Color(color, 0.7)
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.set_content_margin_all(8.0)
		panel.add_theme_stylebox_override("panel", style)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 3)
		panel.add_child(stack)
		var icon_center := CenterContainer.new()
		stack.add_child(icon_center)
		var icon := FlatEffectIcon.new().configure(presentation.icon_key, color)
		icon.custom_minimum_size = Vector2(30.0, 30.0)
		icon_center.add_child(icon)
		var label := Label.new()
		label.text = "%s\n%s" % [presentation.display_name, presentation.mapping_name]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", color.lightened(0.16))
		stack.add_child(label)
		detail_axes.add_child(panel)

func _show_empty() -> void:
	selected_key = ""
	detail_title.text = "등록된 항목 없음"
	detail_state.visible = false
	detail_description.text = "이 분류에는 아직 콘텐츠가 없습니다."
	detail_stats.text = ""
	detail_icon.visible = false
	detail_rule_icon.visible = false
	detail_axes.visible = false

func _state_icon(state: StringName) -> String:
	return {&"discovered": "◆", &"dev": "◇ DEV", &"locked": "▧"}.get(state, "·")

func _state_text(state: StringName) -> String:
	return {&"discovered": "발견 완료 · 상세 기록 공개", &"dev": "DEV 열람 · 실제 발견 필요", &"locked": "미발견 · 해금 조건 확인"}.get(state, String(state))

func _state_short_text(state: StringName) -> String:
	return {&"discovered": "발견", &"dev": "DEV", &"locked": "미발견"}.get(state, String(state))
