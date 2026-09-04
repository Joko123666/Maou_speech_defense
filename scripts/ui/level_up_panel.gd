class_name LevelUpPanel
extends Control

signal choice_selected(choice: UpgradeData)
signal reroll_requested

const FLAT_EFFECT_ICON_SCRIPT := preload("res://scripts/ui/flat_effect_icon.gd")
const CARD_REVEAL_DURATION := 0.24
const CARD_REVEAL_STAGGER := 0.16
const CARD_REVEAL_START_SCALE := Vector2(0.9, 0.9)

@onready var buttons: Array[UiChoiceCard] = [%Choice1, %Choice2, %Choice3]
@onready var back_button: Button = %BackButton
@onready var hint_label: Label = %Hint
@onready var reroll_button: Button = %RerollButton
var choices: Array[UpgradeData] = []
var formation_previews: Array[HBoxContainer] = []
var detail_buttons: Array[Button] = []
var card_text_labels: Array[RichTextLabel] = []
var details_overlay: Control
var details_title: Label
var details_summary: Label
var details_shape_preview: HBoxContainer
var details_tower_list: VBoxContainer
var details_open: bool = false
var previous_choices: Array[UpgradeData] = []
var previous_title: String = ""
var previous_hint: String = ""
var previous_focus_index: int = 0
var subchoice_mode: bool = false
var rerolls_remaining: int = 0
var reroll_limit: int = 0
var reroll_available: bool = false
var subchoice_return_allowed: bool = true
var cards_revealing: bool = false
var card_reveal_tween: Tween
var revealed_hint_text: String = ""
var presentation_service := UpgradePresentationService.new()

func _ready() -> void:
	add_to_group(&"level_up_panels")
	visible = false
	for index in buttons.size():
		buttons[index].pressed.connect(_select.bind(index))
		card_text_labels.append(buttons[index].effect_label)
		formation_previews.append(buttons[index].get_visual_host())
		detail_buttons.append(_create_detail_button(buttons[index], index))
	UiStyleFactory.apply_button(back_button, UiTokens.INK_ROYAL)
	UiStyleFactory.apply_button(reroll_button, UiTokens.ACCENT_GOLD)
	back_button.pressed.connect(_return_to_previous_step)
	reroll_button.pressed.connect(_request_reroll)
	_update_reroll_button()
	_create_details_overlay()

func show_choices(new_choices: Array[UpgradeData], level: int, remaining_rerolls: int = -1, maximum_rerolls: int = -1) -> void:
	if remaining_rerolls >= 0 and maximum_rerolls >= 0:
		set_reroll_state(remaining_rerolls, maximum_rerolls)
	previous_choices.clear()
	subchoice_mode = false
	back_button.visible = false
	var replacements := _campaign_text_replacements({&"level": level})
	_show_choice_cards(
		new_choices,
		ConceptService.ui_text(&"level_up.title", replacements, "LEVEL %d · 특성 선택" % level),
		ConceptService.ui_text(&"level_up.hint", replacements, "카드를 터치하거나 1 · 2 · 3 키로 선택"),
		true
	)

func show_event_choices(new_choices: Array[UpgradeData], title: String, hint: String) -> void:
	previous_choices.clear()
	subchoice_mode = false
	back_button.visible = false
	_show_choice_cards(new_choices, title, hint, false)

func tutorial_action_controls() -> Array[Control]:
	var targets: Array[Control] = []
	if not choices.is_empty() and not buttons.is_empty() and is_instance_valid(buttons[0]):
		targets.append(buttons[0])
	return targets

func set_reroll_state(remaining: int, maximum: int) -> void:
	reroll_limit = maxi(maximum, 0)
	rerolls_remaining = clampi(remaining, 0, reroll_limit)
	_update_reroll_button()

func _show_choice_cards(new_choices: Array[UpgradeData], title: String, hint: String, allow_reroll: bool = false) -> void:
	_cancel_card_reveal()
	choices = new_choices
	reroll_available = allow_reroll
	$Layout.visible = true
	%Title.text = title
	revealed_hint_text = hint
	hint_label.text = "%s · 카드를 준비하고 있습니다…" % hint
	for index in buttons.size():
		if index >= choices.size():
			buttons[index].visible = false
			buttons[index].disabled = true
			buttons[index].modulate = Color.WHITE
			buttons[index].scale = Vector2.ONE
			detail_buttons[index].visible = false
			detail_buttons[index].disabled = true
			formation_previews[index].visible = false
			continue
		buttons[index].visible = true
		buttons[index].set_selected_state(false)
		buttons[index].set_locked(true, "카드 공개가 끝나면 선택할 수 있습니다.")
		buttons[index].modulate = Color(1.0, 1.0, 1.0, 0.0)
		buttons[index].scale = CARD_REVEAL_START_SCALE
		var choice := choices[index]
		var presentation := _category_presentation(choice.category)
		if choice.display_name.contains("Lv.7"):
			presentation = {"badge": "[Lv.7 최종 완성]", "color": Color("ffe16b")}
		buttons[index].text = ""
		buttons[index].configure(_build_choice_card_data(index, choice, presentation))
		_update_formation_preview(index, choice)
		detail_buttons[index].visible = true
		detail_buttons[index].disabled = true
	_close_formation_details()
	visible = true
	_start_card_reveal()

func _start_card_reveal() -> void:
	cards_revealing = not choices.is_empty()
	_update_reveal_input_lock()
	if not cards_revealing:
		_finish_card_reveal()
		return
	if UiMotion.is_reduced():
		_finish_card_reveal()
		return
	card_reveal_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for index in mini(choices.size(), buttons.size()):
		var button := buttons[index]
		button.pivot_offset = button.size * 0.5
		var delay := float(index) * CARD_REVEAL_STAGGER
		card_reveal_tween.tween_property(button, "modulate", Color.WHITE, CARD_REVEAL_DURATION).set_delay(delay)
		card_reveal_tween.tween_property(button, "scale", Vector2.ONE, CARD_REVEAL_DURATION).set_delay(delay)
	card_reveal_tween.chain().tween_callback(_finish_card_reveal)

func _finish_card_reveal() -> void:
	card_reveal_tween = null
	cards_revealing = false
	for index in buttons.size():
		if index < choices.size():
			buttons[index].modulate = Color.WHITE
			buttons[index].scale = Vector2.ONE
	hint_label.text = revealed_hint_text
	_update_reveal_input_lock()
	if not choices.is_empty() and visible and $Layout.visible:
		buttons[0].grab_focus()

func complete_card_reveal() -> void:
	if not cards_revealing:
		return
	if card_reveal_tween != null and card_reveal_tween.is_valid():
		card_reveal_tween.kill()
	_finish_card_reveal()

func _cancel_card_reveal() -> void:
	if card_reveal_tween != null and card_reveal_tween.is_valid():
		card_reveal_tween.kill()
	card_reveal_tween = null
	cards_revealing = false

func _update_reveal_input_lock() -> void:
	for index in buttons.size():
		var locked := cards_revealing or index >= choices.size()
		buttons[index].set_locked(locked, "카드 공개가 끝나면 선택할 수 있습니다." if cards_revealing else "")
		detail_buttons[index].disabled = cards_revealing
	back_button.disabled = cards_revealing
	_update_reroll_button()

func show_subchoices(new_choices: Array[UpgradeData], parent_title: String, level: int, allow_return: bool = true) -> void:
	previous_choices = choices.duplicate()
	previous_title = %Title.text
	previous_hint = revealed_hint_text if cards_revealing else hint_label.text
	subchoice_mode = true
	subchoice_return_allowed = allow_return
	back_button.visible = allow_return
	var replacements := _campaign_text_replacements({&"parent": parent_title, &"level": level})
	var formation_subchoice := not new_choices.is_empty() and new_choices.all(
		func(choice: UpgradeData) -> bool: return choice.category == &"new_formation"
	)
	var subchoice_title := ConceptService.ui_text(&"level_up.subchoice_title", replacements, "%s · 하위 특화 선택" % parent_title)
	var subchoice_hint := ConceptService.ui_text(&"level_up.subchoice_hint", replacements, "특화 카드 중 하나를 선택하면 Lv.4가 활성화됩니다")
	if formation_subchoice:
		subchoice_title = "%s · 편대 선택" % parent_title
		subchoice_hint = "형태와 병력 구성을 확인한 뒤 배치할 편대 하나를 선택하세요"
	_show_choice_cards(
		new_choices,
		subchoice_title,
		subchoice_hint,
		false
	)

func hide_panel() -> void:
	_cancel_card_reveal()
	_close_formation_details()
	visible = false
	$Layout.visible = true
	back_button.visible = false
	previous_choices.clear()
	subchoice_mode = false
	subchoice_return_allowed = true
	reroll_available = false
	_update_reroll_button()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	if cards_revealing:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel"):
		if details_open:
			_close_formation_details()
		elif subchoice_mode and subchoice_return_allowed:
			_return_to_previous_step()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		if details_open:
			return
		elif not event.echo and event.keycode == KEY_Q:
			_request_reroll()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_select(event.keycode - KEY_1)

func _request_reroll() -> void:
	if details_open or subchoice_mode or not reroll_available or rerolls_remaining <= 0:
		return
	reroll_requested.emit()
	AudioManager.play_ui()

func _update_reroll_button() -> void:
	if reroll_button == null:
		return
	reroll_button.visible = reroll_available
	reroll_button.disabled = cards_revealing or rerolls_remaining <= 0
	var replacements := _campaign_text_replacements({&"remaining": rerolls_remaining, &"limit": reroll_limit})
	reroll_button.text = ConceptService.ui_text(
		&"level_up.reroll", replacements,
		"특성 리롤  %d / %d  [Q]" % [rerolls_remaining, reroll_limit]
	)
	reroll_button.tooltip_text = ConceptService.ui_text(
		&"level_up.reroll_tooltip", replacements,
		"현재 3개의 일반 특성 카드를 다시 뽑습니다. 게임당 %d회 사용할 수 있습니다." % reroll_limit
	)

func _campaign_text_replacements(extra: Dictionary = {}) -> Dictionary:
	var replacements := extra.duplicate()
	replacements[&"candidate"] = ConceptService.term(&"core")
	var campaign := ConceptService.get_election_campaign()
	if campaign != null:
		var candidate := campaign.candidate_for_core(GameSession.selected_core_id)
		if candidate != null:
			replacements[&"candidate"] = candidate.short_name
	return replacements

func _select(index: int) -> void:
	if details_open or index < 0 or index >= choices.size():
		return
	_cancel_card_reveal()
	previous_focus_index = index
	visible = false
	choice_selected.emit(choices[index])

func _return_to_previous_step() -> void:
	if subchoice_mode and subchoice_return_allowed and not previous_choices.is_empty():
		var restored_choices := previous_choices
		var restored_title := previous_title
		var restored_hint := previous_hint
		previous_choices = []
		subchoice_mode = false
		back_button.visible = false
		_show_choice_cards(restored_choices, restored_title, restored_hint, true)
		buttons[clampi(previous_focus_index, 0, buttons.size() - 1)].grab_focus.call_deferred()
		AudioManager.play_ui()

func _category_presentation(category: StringName) -> Dictionary:
	return presentation_service.category_presentation(category)

func _build_choice_card_data(index: int, choice: UpgradeData, presentation: Dictionary) -> Dictionary:
	var accent: Color = presentation.color
	var badge := String(presentation.badge).trim_prefix("[").trim_suffix("]")
	var impacts: Array = _choice_impacts(choice)
	var effect_lines := _choice_compact_change_lines(choice, impacts)
	var effect_text := "\n".join(effect_lines)
	if not effect_text.is_empty():
		effect_text = "[center][color=#%s][b]%s[/b][/color][/center]" % [accent.darkened(0.24).to_html(false), _escape_card_text(effect_text)]
	var primary_icon_key := _choice_header_icon_key(choice, impacts)
	var primary_icon_color: Color = accent
	if not impacts.is_empty():
		primary_icon_color = (impacts[0] as Dictionary).get("color", primary_icon_color) as Color
	var tags: Array[String] = []
	for impact in impacts:
		var label := String(impact.get("label", ""))
		if not label.is_empty() and label not in tags:
			tags.append(label)
		if tags.size() >= 3:
			break
	return {
		"eyebrow": badge,
		"title": choice.display_name,
		"effect": effect_text,
		"tags": tags,
		"description": _choice_compact_narrative(choice),
		"compact": false,
		"selection_label": "[%d] 선택" % (index + 1),
		"tooltip": "%s\n%s\n전체 수치는 상세에서 확인" % [choice.display_name, " · ".join(effect_lines)],
		"icon": _choice_card_icon(choice),
		"icon_key": primary_icon_key,
		"icon_color": primary_icon_color,
		"accent": accent,
	}

func _choice_compact_change_lines(choice: UpgradeData, impacts: Array) -> Array[String]:
	var result: Array[String] = []
	if choice.category == &"artifact":
		var effects := choice.offer_metadata.get("effects", []) as Array
		for effect_index in mini(effects.size(), 2):
			var effect := effects[effect_index] as Dictionary
			var label := String((impacts[effect_index] as Dictionary).get("label", "효과")) if effect_index < impacts.size() else "효과"
			var direction := "증가" if float(effect.get("value", 0.0)) >= 0.0 else "감소"
			_append_unique_change(result, "%s %s" % [label, direction])
		return result
	if choice.category == &"status_upgrade":
		match choice.data_id:
			&"poison": return ["독 피해·중첩 강화"]
			&"burn": return ["화상 피해·지속 강화"]
			&"bleed": return ["출혈 피해·중첩 강화"]
			&"shock": return ["감전 피해·전이 강화"]
		return ["%s 효과 강화" % _status_display_name(choice.data_id)]
	if StringName(choice.offer_metadata.get("family", "")) == &"overgrowth":
		var growth_label := "완성 능력"
		for impact_value in impacts:
			var impact_label := String((impact_value as Dictionary).get("label", ""))
			if impact_label not in ["후보", "심복", "반복 수치"] and not impact_label.is_empty():
				growth_label = impact_label
				break
		return ["%s 반복 강화" % growth_label]
	for raw_line in choice.description.split("\n"):
		var line := _strip_change_prefix(String(raw_line).strip_edges())
		if line.is_empty() or not line.contains("→"):
			continue
		for raw_segment in line.replace("  /  ", "\n").split("\n"):
			var summary := _compact_transition(String(raw_segment).strip_edges())
			if not summary.is_empty():
				_append_unique_change(result, summary)
				if result.size() >= 2:
					return result
	if not result.is_empty():
		return result
	return [_choice_fallback_change(choice, impacts)]

func _append_unique_change(changes: Array[String], value: String) -> void:
	if not value.is_empty() and value not in changes and changes.size() < 2:
		changes.append(value)

func _strip_change_prefix(value: String) -> String:
	for prefix in ["수치 변화", "Lv.4 수치", "Lv.7 수치", "Lv.7 완성 수치"]:
		if value.begins_with(prefix):
			var separator_index := value.find("·")
			return value.substr(separator_index + 1).strip_edges() if separator_index >= 0 else ""
	return value

func _compact_transition(value: String) -> String:
	var arrow_index := value.find("→")
	if arrow_index < 0:
		return ""
	var before := value.substr(0, arrow_index).strip_edges()
	var after := value.substr(arrow_index + 1).strip_edges()
	var label := _transition_label(before)
	if label.is_empty():
		label = "효과"
	var previous_value := _first_numeric_value(before)
	var next_value := _first_numeric_value(after)
	var direction := "변경"
	if not previous_value.is_empty() and not next_value.is_empty():
		var previous_number := float(previous_value)
		var next_number := float(next_value)
		if next_number > previous_number:
			direction = "증가"
		elif next_number < previous_number:
			direction = "감소"
		else:
			direction = "강화"
	return "%s %s" % [label, direction]

func _transition_label(value: String) -> String:
	var clean := value.replace("🔴", "").replace("🟢", "").replace("🔵", "").replace("◆", "").strip_edges()
	for index in clean.length():
		var character := clean.substr(index, 1)
		if "0123456789×+-".contains(character):
			return clean.substr(0, index).strip_edges().trim_suffix("·").strip_edges()
	return clean

func _first_numeric_value(value: String) -> String:
	var number_pattern := RegEx.new()
	if number_pattern.compile("-?[0-9]+(?:\\.[0-9]+)?") != OK:
		return ""
	var match_result := number_pattern.search(value)
	return match_result.get_string() if match_result != null else ""

func _choice_fallback_change(choice: UpgradeData, impacts: Array) -> String:
	if _is_formation_choice(choice) or choice.category == &"formation_set":
		return "새 편대 선택"
	if choice.category == &"status_upgrade":
		return "%s 강화" % _status_display_name(choice.data_id)
	if choice.category in [&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry", &"guard_specialization_entry"]:
		return "전용 특화 선택 해금"
	if choice.category in [&"tower_branch", &"core_branch", &"cursor_branch", &"guard_branch", &"candidate_branch"]:
		var branch_labels: Array[String] = []
		for impact_value in impacts:
			var impact_label := String((impact_value as Dictionary).get("label", ""))
			if impact_label in ["후보", "심복", "친위대", ConceptService.term(&"core"), ConceptService.term(&"tower")] or impact_label.is_empty():
				continue
			if impact_label not in branch_labels:
				branch_labels.append(impact_label)
			if branch_labels.size() >= 2:
				break
		return "%s 변화" % "·".join(branch_labels) if not branch_labels.is_empty() else "전투 분기 활성화"
	if StringName(choice.offer_metadata.get("family", "")) == &"overgrowth":
		return "완성 능력 추가 강화"
	if not impacts.is_empty():
		var impact_label := String((impacts[0] as Dictionary).get("label", ""))
		if not impact_label.is_empty():
			return "%s 강화" % impact_label
	return "전투 효과 강화"

func _choice_compact_narrative(choice: UpgradeData) -> String:
	if _is_formation_choice(choice) or choice.category == &"formation_set":
		return "선택 후 전장에서 배치 위치를 정합니다."
	if choice.category == &"artifact":
		return "이득과 손해를 함께 적용합니다." if bool(choice.offer_metadata.get("trade_off", false)) else "선택 즉시 고유 효과를 적용합니다."
	if choice.category in [&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry", &"guard_specialization_entry"]:
		return "선택 후 전용 특화 3택으로 이동합니다."
	if StringName(choice.offer_metadata.get("family", "")) == &"overgrowth":
		return "완성된 성장 축을 한 단계 더 강화합니다."
	for raw_line in choice.description.split("\n"):
		var line := String(raw_line).strip_edges()
		if line.is_empty() or _is_stat_description_line(line) or line.contains("→") or line.begins_with("병종 능력축"):
			continue
		var separator_index := line.find(" · ")
		if separator_index >= 0 and line.substr(0, separator_index).contains("Lv."):
			line = line.substr(separator_index + 3).strip_edges()
		if not _contains_numeric_detail(line):
			return line
	match choice.category:
		&"status_upgrade": return "해당 상태이상의 효과를 강화합니다."
		&"tower_type_level": return "같은 종류의 모든 병력을 강화합니다."
		&"core_level": return "%s의 전투 역할을 강화합니다." % ConceptService.term(&"core")
		&"cursor_level": return "심복의 전투 역할을 강화합니다."
		&"tower_branch", &"core_branch", &"cursor_branch", &"guard_branch", &"candidate_branch": return "선택한 전투 분기를 활성화합니다."
	return "선택 즉시 해당 변화를 적용합니다."

func _contains_numeric_detail(value: String) -> bool:
	return not _first_numeric_value(value).is_empty()

func _is_stat_description_line(line: String) -> bool:
	return line.begins_with("수치 변화") or line.begins_with("Lv.4 수치") or line.begins_with("Lv.7 수치") or line.begins_with("Lv.7 완성 수치") or line == "기본 수치 변화 없음"

func _needs_choice_details(choice: UpgradeData) -> bool:
	return choice != null

func _choice_card_icon(choice: UpgradeData) -> Texture2D:
	if choice.category in [&"tower_type_level", &"tower_specialization_entry"]:
		var tower_id := _choice_tower_id(choice)
		if tower_id != &"":
			return _tower_level_up_icon(DataRegistry.get_tower(tower_id))
	if choice.category == &"core_level":
		return ConceptService.content_texture(&"cores", choice.data_id)
	if choice.category == &"cursor_level":
		return ConceptService.content_texture(&"cursors", choice.data_id)
	return null

func _choice_header_icon_key(choice: UpgradeData, impacts: Array = []) -> StringName:
	var resolved_impacts := impacts if not impacts.is_empty() else _choice_impacts(choice)
	var icon_key: StringName = &"formation" if choice.category in [&"formation_set", &"new_formation"] else &"global"
	if not resolved_impacts.is_empty():
		icon_key = StringName((resolved_impacts[0] as Dictionary).get("icon", icon_key))
	return icon_key

func _choice_header_semantic_icon_keys(choice: UpgradeData, impacts: Array) -> Dictionary:
	var result: Dictionary = {}
	if _choice_card_icon(choice) == null:
		result[_choice_header_icon_key(choice, impacts)] = true
		return result
	match choice.category:
		&"tower_type_level", &"tower_specialization_entry": result[&"tower"] = true
		&"core_level": result[&"core"] = true
		&"cursor_level": result[&"cursor"] = true
	return result

func _choice_body_impacts(choice: UpgradeData) -> Array:
	var impacts: Array = _choice_impacts(choice)
	var header_icon_keys := _choice_header_semantic_icon_keys(choice, impacts)
	var normalized_title := _normalize_semantic_text(choice.display_name)
	var seen_icon_keys: Dictionary = {}
	var seen_labels: Dictionary = {}
	var result: Array = []
	for impact_value in impacts:
		var impact := impact_value as Dictionary
		var icon_key := StringName(impact.get("icon", &"global"))
		var label := String(impact.get("label", "")).strip_edges()
		var normalized_label := _normalize_semantic_text(label)
		if header_icon_keys.has(icon_key):
			continue
		if not normalized_label.is_empty() and normalized_title.contains(normalized_label):
			continue
		if seen_icon_keys.has(icon_key) or seen_labels.has(normalized_label):
			continue
		seen_icon_keys[icon_key] = true
		if not normalized_label.is_empty():
			seen_labels[normalized_label] = true
		result.append(impact)
	return result

func _normalize_semantic_text(value: String) -> String:
	var normalized := value.to_lower()
	for separator in [" ", "·", "・", "-", "_", "/", "[", "]", "(", ")", "."]:
		normalized = normalized.replace(separator, "")
	return normalized

func _escape_card_text(value: String) -> String:
	return value.replace("[", "［").replace("]", "］")

func _create_detail_button(card: UiChoiceCard, index: int) -> Button:
	var detail_button := Button.new()
	detail_button.name = "DetailButton%d" % (index + 1)
	detail_button.text = "상세"
	detail_button.visible = true
	detail_button.z_index = 4
	detail_button.custom_minimum_size = Vector2(96.0, UiTokens.TOUCH_TARGET_MIN)
	detail_button.focus_mode = Control.FOCUS_ALL
	detail_button.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_button.anchor_left = 0.5
	detail_button.anchor_top = 1.0
	detail_button.anchor_right = 0.5
	detail_button.anchor_bottom = 1.0
	detail_button.offset_left = -48.0
	detail_button.offset_top = -116.0
	detail_button.offset_right = 48.0
	detail_button.offset_bottom = -68.0
	UiStyleFactory.apply_button(detail_button, UiTokens.AXIS_RANGE)
	detail_button.add_theme_font_size_override(&"font_size", UiTokens.FONT_CAPTION)
	detail_button.tooltip_text = "전체 설명과 정확한 수치 보기"
	detail_button.pressed.connect(_show_choice_details.bind(index))
	card.get_parent().add_child(detail_button)
	return detail_button

func _create_details_overlay() -> void:
	details_overlay = Control.new()
	details_overlay.name = "ChoiceDetailsOverlay"
	details_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	details_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	details_overlay.z_index = 30
	details_overlay.visible = false
	add_child(details_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005, 0.015, 0.025, 0.9)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	details_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -470.0
	panel.offset_top = -310.0
	panel.offset_right = 470.0
	panel.offset_bottom = 310.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("0b202b", 0.995)
	panel_style.border_color = Color("54ced9")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(24.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	details_overlay.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	details_title = Label.new()
	details_title.add_theme_font_size_override("font_size", 30)
	details_title.add_theme_color_override("font_color", Color("8ff4e7"))
	details_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(details_title)
	details_summary = Label.new()
	details_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_summary.add_theme_font_size_override("font_size", 16)
	details_summary.add_theme_color_override("font_color", Color("c4dce2"))
	details_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(details_summary)
	details_shape_preview = HBoxContainer.new()
	details_shape_preview.name = "FormationDetailsShapePreview"
	details_shape_preview.alignment = BoxContainer.ALIGNMENT_CENTER
	details_shape_preview.add_theme_constant_override("separation", 6)
	content.add_child(details_shape_preview)
	var separator := HSeparator.new()
	content.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	details_tower_list = VBoxContainer.new()
	details_tower_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_tower_list.add_theme_constant_override("separation", 10)
	scroll.add_child(details_tower_list)
	var close_button := Button.new()
	close_button.text = "닫기  [Esc]"
	close_button.custom_minimum_size = Vector2(0.0, UiTokens.TOUCH_TARGET_MIN)
	close_button.add_theme_font_size_override("font_size", 17)
	UiStyleFactory.apply_button(close_button, UiTokens.AXIS_RANGE)
	close_button.pressed.connect(_close_formation_details)
	content.add_child(close_button)

func _show_choice_details(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	var choice := choices[index]
	if _is_formation_choice(choice):
		_show_formation_details(index)
		return
	for child in details_tower_list.get_children():
		details_tower_list.remove_child(child)
		child.queue_free()
	for child in details_shape_preview.get_children():
		details_shape_preview.remove_child(child)
		child.queue_free()
	details_title.text = "%s · 전체 수치" % choice.display_name
	details_summary.text = choice.description.replace("  /  ", "\n").replace(" / ", "\n")
	for impact in _choice_impacts(choice):
		details_shape_preview.add_child(_create_impact_icon_slot(impact.label, impact.icon, impact.color))
	details_overlay.visible = true
	details_open = true

func _show_formation_details(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	var choice := choices[index]
	if not _is_formation_choice(choice):
		return
	var formation := DataRegistry.get_formation(choice.data_id)
	if formation == null:
		return
	for child in details_tower_list.get_children():
		details_tower_list.remove_child(child)
		child.queue_free()
	for child in details_shape_preview.get_children():
		details_shape_preview.remove_child(child)
		child.queue_free()
	details_title.text = "%s · %s 상세" % [formation.display_name, ConceptService.term(&"formation")]
	var role_text := ", ".join(formation.role_tags)
	var unique_note := "  ·  %s 공명 전용 / 런당 1회" % ConceptService.term(&"core") if formation.is_unique() else ""
	details_summary.text = "%s\n%s · %d칸 · %d병종 · 배치 %s  ·  의도 태그: %s  ·  기초 편성점수 %d%s" % [
		formation.description,
		formation.get_shape_display_name(),
		formation.cells.size(),
		formation.get_distinct_tower_count(),
		formation.get_placement_difficulty_display_name(),
		role_text,
		formation.formation_score,
		unique_note,
	]
	details_shape_preview.add_child(_create_formation_shape_grid(formation))
	var listed_ids: Array[StringName] = []
	var formation_tower_ids := formation.get_tower_ids()
	for tower_id in formation_tower_ids:
		if tower_id == &"" or tower_id in listed_ids:
			continue
		listed_ids.append(tower_id)
		var tower := DataRegistry.get_tower(tower_id)
		if tower != null:
			details_tower_list.add_child(_create_tower_detail_row(tower, formation_tower_ids.count(tower_id)))
	details_overlay.visible = true
	details_open = true

func _close_formation_details() -> void:
	if details_overlay != null:
		details_overlay.visible = false
	details_open = false

func _create_tower_detail_row(tower: TowerData, count: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 108.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(tower.color, 0.09)
	style.border_color = Color(tower.color, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12.0)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(82.0, 82.0)
	icon.texture = _tower_level_up_icon(tower)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE.lerp(tower.color, 0.08)
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var name_label := Label.new()
	name_label.text = "%s  ×%d" % [tower.display_name, count]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", tower.color.lightened(0.22))
	copy.add_child(name_label)
	var description_label := Label.new()
	description_label.text = tower.description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 15)
	copy.add_child(description_label)
	var stats_label := Label.new()
	stats_label.text = "공격 방식: %s  ·  대상 기준: %s  ·  기본 피해 %.1f  ·  주기 %.2f초  ·  사거리 %.2f칸" % [_tower_attack_style(tower.behavior), _tower_target_rule(tower.target_rule), tower.damage, tower.attack_interval, tower.attack_range_cells]
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.add_theme_color_override("font_color", Color("91aeb8"))
	copy.add_child(stats_label)
	return panel

func _tower_attack_style(behavior: StringName) -> String:
	return presentation_service.tower_attack_style(behavior)

func _tower_target_rule(rule: StringName) -> String:
	return presentation_service.tower_target_rule(rule)

func _update_formation_preview(index: int, choice: UpgradeData) -> void:
	var preview := formation_previews[index]
	for child in preview.get_children():
		preview.remove_child(child)
		child.queue_free()
	preview.visible = true
	if _is_formation_choice(choice):
		var formation := DataRegistry.get_formation(choice.data_id)
		preview.add_child(_create_formation_shape_grid(formation, true))
		return
	for impact in _choice_body_impacts(choice):
		preview.add_child(_create_impact_icon_slot(impact.label, impact.icon, impact.color))

func _create_formation_shape_grid(formation: TowerFormationData, compact: bool = false) -> GridContainer:
	var shape_grid := GridContainer.new()
	shape_grid.name = "FormationShapeGrid"
	if formation == null:
		return shape_grid
	var bounds := formation.get_bounds()
	shape_grid.columns = maxi(bounds.size.x, 1)
	shape_grid.add_theme_constant_override("h_separation", 4)
	shape_grid.add_theme_constant_override("v_separation", 4)
	var cells_by_offset: Dictionary = {}
	for formation_cell in formation.cells:
		if formation_cell != null:
			cells_by_offset[formation_cell.offset] = formation_cell.tower_id
	for y in maxi(bounds.size.y, 1):
		for x in maxi(bounds.size.x, 1):
			shape_grid.add_child(_create_tower_icon_slot(cells_by_offset.get(Vector2i(x, y), &"") as StringName, compact))
	return shape_grid

func _choice_tower_id(choice: UpgradeData) -> StringName:
	return presentation_service.choice_tower_id(choice)

func _is_formation_choice(choice: UpgradeData) -> bool:
	return presentation_service.is_formation_choice(choice)

func _choice_impacts(choice: UpgradeData) -> Array[Dictionary]:
	return presentation_service.choice_impacts(choice)

func _status_display_name(status_id: StringName) -> String:
	return CommonStatusCatalog.display_name(status_id)

func _status_impact_color(status_id: StringName) -> Color:
	return CommonStatusCatalog.color(status_id)

func _create_impact_icon_slot(label: String, icon_key: StringName, color: Color) -> Control:
	var slot := VBoxContainer.new()
	slot.set_meta(&"impact_label", label)
	slot.set_meta(&"impact_icon_key", icon_key)
	slot.custom_minimum_size = Vector2(58.0, 76.0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(52.0, 52.0)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED.lerp(color, 0.14), color, UiTokens.RADIUS_SMALL, 2, 4.0)
	icon_panel.add_theme_stylebox_override("panel", style)
	var icon := FLAT_EFFECT_ICON_SCRIPT.new().configure(icon_key, color)
	icon_panel.add_child(icon)
	slot.add_child(icon_panel)
	var caption := Label.new()
	caption.text = label
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", color.darkened(0.24))
	slot.add_child(caption)
	return slot

func _create_tower_icon_slot(tower_id: StringName, compact: bool = false) -> Control:
	var slot := VBoxContainer.new()
	slot.custom_minimum_size = Vector2(42.0, 42.0) if compact else Vector2(58.0, 76.0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	if tower_id == &"":
		var blank_panel := Panel.new()
		blank_panel.custom_minimum_size = Vector2(38.0, 38.0) if compact else Vector2(52.0, 52.0)
		blank_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var blank_style := UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED.darkened(0.08), UiTokens.DISABLED_INK, UiTokens.RADIUS_SMALL, 2, 4.0)
		blank_panel.add_theme_stylebox_override("panel", blank_style)
		slot.add_child(blank_panel)
		if compact:
			slot.tooltip_text = "공란"
			return slot
		var blank_label := Label.new()
		blank_label.text = "공란"
		blank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blank_label.add_theme_font_size_override("font_size", 11)
		blank_label.add_theme_color_override("font_color", UiTokens.DISABLED_INK)
		slot.add_child(blank_label)
		return slot
	var tower := DataRegistry.get_tower(tower_id)
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(38.0, 38.0) if compact else Vector2(52.0, 52.0)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_style := UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED.lerp(tower.color, 0.14), tower.color, UiTokens.RADIUS_SMALL, 2, 4.0)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	var icon := TextureRect.new()
	icon.texture = _tower_level_up_icon(tower)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE.lerp(tower.color, 0.06)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon)
	slot.add_child(icon_panel)
	if compact:
		slot.tooltip_text = tower.display_name
		return slot
	var role_label := Label.new()
	role_label.text = _tower_icon_name(tower.behavior)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", tower.color.darkened(0.24))
	slot.add_child(role_label)
	slot.tooltip_text = tower.display_name
	return slot

func _tower_icon_name(behavior: StringName) -> String:
	return presentation_service.tower_icon_name(behavior)

func _tower_level_up_icon(tower: TowerData) -> Texture2D:
	if tower == null:
		return ConceptService.fallback_texture(&"defender_icons")
	var face_icon := ConceptService.optional_content_texture(&"defender_icons", tower.id)
	if face_icon != null:
		return face_icon
	return tower.texture if tower.texture != null else ConceptService.fallback_texture(&"defender_icons")
