class_name GameHUD
extends Control

const FLAT_EFFECT_ICON_SCRIPT := preload("res://scripts/ui/flat_effect_icon.gd")
const COMPACT_LAYOUT_WIDTH := 1120

signal restart_requested
signal menu_requested
signal skill_requested
signal speed_requested
signal range_overlay_requested(enabled: bool)
signal pause_requested

@onready var health_label: Label = %HealthLabel
@onready var time_label: Label = %TimeLabel
@onready var lane_label: Label = %LaneLabel
@onready var experience_label: Label = %ExperienceLabel
@onready var experience_bar: ProgressBar = %ExperienceBar
@onready var skill_button: Button = %SkillButton
@onready var speed_button: Button = %SpeedButton
@onready var range_button: Button = %RangeButton
@onready var pause_button: Button = %PauseButton
@onready var boss_panel: PanelContainer = %BossPanel
@onready var boss_label: Label = %BossLabel
@onready var boss_bar: ProgressBar = %BossBar
@onready var warning_label: Label = %WarningLabel
@onready var build_label: Label = %BuildLabel
@onready var kill_label: Label = %KillLabel
@onready var prelude_label: Label = %PreludeLabel
@onready var prelude_marker: FactionMarkerIcon = %PreludeMarker
@onready var warning_marker: FactionMarkerIcon = %WarningMarker
@onready var boss_marker: FactionMarkerIcon = %BossMarker
@onready var event_frame: PanelContainer = %EventFrame
@onready var governance_audience: Label = %GovernanceAudience
@onready var global_list: GridContainer = %GlobalList
@onready var global_count: Label = %GlobalCount
@onready var artifact_panel: PanelContainer = %ArtifactPanel
@onready var artifact_list: GridContainer = %ArtifactList
@onready var artifact_count: Label = %ArtifactCount
@onready var artifact_detail_button: Button = %ArtifactDetailButton
@onready var artifact_detail_panel: PanelContainer = %ArtifactDetailPanel
@onready var artifact_detail_label: Label = %ArtifactDetailLabel
@onready var instruction_label: Label = %Instruction
@onready var bottom_info: PanelContainer = %BottomInfo
@onready var bottom_info_toggle: Button = %BottomInfoToggle
@onready var result_overlay: CombatResultOverlay = %ResultOverlay
@onready var result_backdrop: ColorRect = result_overlay.backdrop
@onready var result_panel: PanelContainer = result_overlay.panel
@onready var result_title: Label = result_overlay.title_label
@onready var result_subtitle: Label = result_overlay.subtitle_label
@onready var result_progress_label: Label = result_overlay.progress_label
@onready var result_timeline: ResultProgressTimeline = result_overlay.timeline
@onready var funds_earned_label: Label = result_overlay.funds_earned_label
@onready var funds_total_label: Label = result_overlay.funds_total_label
@onready var reward_breakdown_label: Label = result_overlay.reward_breakdown_label
@onready var candidate_support_section: PanelContainer = result_overlay.candidate_support_section
@onready var candidate_support_label: Label = result_overlay.candidate_support_label
@onready var candidate_support_bar: ProgressBar = result_overlay.candidate_support_bar
@onready var candidate_election_label: Label = result_overlay.candidate_election_label
@onready var governance_result_label: Label = result_overlay.governance_result_label
@onready var result_detail: Label = result_overlay.detail_label
@onready var formation_board_preview: FormationBoardPreview = result_overlay.formation_board_preview
@onready var restart_button: Button = result_overlay.restart_button
@onready var menu_button: Button = result_overlay.menu_button
@onready var top_bar: HBoxContainer = $TopBar
@onready var run_context_panel: PanelContainer = $TopBar/RunContextPanel
@onready var combat_actions_panel: PanelContainer = $TopBar/CombatActionsPanel
@onready var effect_panels: VBoxContainer = $EffectPanels

var previous_health: float = -1.0
var previous_level: int = -1
var skill_was_ready: bool = false
var skill_casting: bool = false
var previous_speed: float = -1.0
var touch_hint_active: bool = false
var result_tweens: Array[Tween] = []
var tutorial_mode: bool = false
var prelude_active: bool = false
var compact_layout: bool = false
var _safe_rect_override := Rect2i()
var _has_safe_rect_override := false

func _ready() -> void:
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	skill_button.pressed.connect(func() -> void: skill_requested.emit())
	speed_button.pressed.connect(func() -> void: speed_requested.emit())
	range_button.toggled.connect(_on_range_button_toggled)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	bottom_info_toggle.pressed.connect(toggle_bottom_info)
	artifact_detail_button.pressed.connect(_toggle_artifact_details)
	%WarningTimer.timeout.connect(_hide_warning)
	UiStyleFactory.apply_hud_button(skill_button, UiTokens.ACCENT_GOLD)
	UiStyleFactory.apply_hud_button(speed_button, UiTokens.AXIS_SPEED)
	UiStyleFactory.apply_hud_button(range_button, UiTokens.AXIS_RANGE)
	UiStyleFactory.apply_hud_button(pause_button, UiTokens.INK_MUTED)
	UiStyleFactory.apply_hud_button(bottom_info_toggle, UiTokens.ACCENT_GOLD)
	UiStyleFactory.apply_hud_button(artifact_detail_button, UiTokens.ACCENT_GOLD)
	bottom_info_toggle.add_theme_font_size_override(&"font_size", 13)
	artifact_detail_button.add_theme_font_size_override(&"font_size", 12)
	result_overlay.hide_overlay()
	boss_panel.visible = false
	warning_label.visible = false
	prelude_label.visible = false
	event_frame.visible = false
	set_bottom_info_visible(false)
	update_artifacts([])
	set_touch_control_hint(DisplayServer.is_touchscreen_available())
	_refresh_safe_area()
	get_viewport().size_changed.connect(_refresh_safe_area)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		set_touch_control_hint(true)
	elif event is InputEventKey or event is InputEventMouseButton:
		set_touch_control_hint(false)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		if not get_tree().paused and not result_panel.visible:
			toggle_bottom_info()
			get_viewport().set_input_as_handled()

func toggle_bottom_info() -> void:
	set_bottom_info_visible(not bottom_info.visible)

func set_bottom_info_visible(enabled: bool) -> void:
	bottom_info.visible = enabled
	bottom_info_toggle.text = "설명 숨기기  [H]" if enabled else "설명 보기  [H]"
	bottom_info_toggle.tooltip_text = "편대·강화 현황과 조작 설명을 숨깁니다." if enabled else "편대·강화 현황과 조작 설명을 표시합니다."

func set_touch_control_hint(touch_enabled: bool) -> void:
	if touch_hint_active == touch_enabled and not instruction_label.text.is_empty():
		return
	touch_hint_active = touch_enabled
	var key := &"hud.input_touch" if touch_enabled else &"hud.input_desktop"
	var fallback := (
		"터치/드래그: 이동 목적지 지정·자동 공격·경험치 회수 · 상단 버튼: {skill} / 배속 / 사거리 / 일시정지"
		if touch_enabled else
		"클릭/드래그: 이동 목적지 지정·자동 공격·경험치 회수 · SPACE: {skill} · F: 배속 · G: 사거리 · ESC: 일시정지"
	)
	instruction_label.text = ConceptService.ui_text(key, {&"skill": _skill_label()}, fallback)

func _skill_label() -> String:
	return ConceptService.ui_text(&"hud.skill", {&"core": ConceptService.term(&"core")}, "%s 스킬" % ConceptService.term(&"core"))

func set_run_identity(core_name: String, cursor_name: String, challenge_level: int = 0, decree_name: String = "") -> void:
	%RunIdentity.text = "도전 %d%s" % [
		ChallengeRules.clamp_level(challenge_level),
		" · 칙령 %s" % decree_name if not decree_name.is_empty() else "",
	]
	%RunIdentity.tooltip_text = "%s · %s" % [core_name, cursor_name]

func set_tutorial_mode(enabled: bool) -> void:
	tutorial_mode = enabled
	speed_button.visible = not enabled
	range_button.visible = not enabled
	prelude_label.visible = false
	governance_audience.visible = false
	artifact_panel.visible = not enabled
	artifact_detail_panel.visible = false
	_refresh_safe_area()
	if enabled:
		%RunIdentity.text = "튜토리얼 · 파르태손 / 칸다"
		instruction_label.text = "안내에 따라 이동·배치·성장·보스·필살 공약을 익힙니다."
	_sync_event_frame()

func set_tutorial_step(step_index: int, step_count: int, instruction: String) -> void:
	if not tutorial_mode:
		return
	warning_label.text = "훈련 %d/%d  ·  %s" % [step_index + 1, step_count, instruction]
	warning_label.modulate = Color("8fe8ff")
	warning_label.visible = true
	%WarningTimer.stop()
	_sync_event_frame()

func set_governance_reaction(reaction: GovernanceReactionData, approval: int) -> void:
	governance_audience.visible = reaction != null
	if reaction == null:
		_sync_event_frame()
		return
	var marks := ""
	for index in 5:
		marks += "●" if index < reaction.audience_strength else "○"
	governance_audience.text = "관객석 %s · 통치 %s %d · %s" % [marks, reaction.display_name, clampi(approval, 0, 100), reaction.battle_chant]
	governance_audience.add_theme_color_override("font_color", reaction.color)
	if UiMotion.should_animate():
		governance_audience.modulate = Color(1.0, 1.0, 1.0, 0.0)
		create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).tween_property(governance_audience, "modulate", Color.WHITE, 0.35)
	else:
		governance_audience.modulate = Color.WHITE
	_sync_event_frame()

func update_health(current: float, maximum: float) -> void:
	health_label.text = "%s  %d / %d" % [ConceptService.term(&"core").to_upper(), ceili(current), ceili(maximum)]
	var health_ratio := current / maximum if maximum > 0.0 else 0.0
	var target_color := Color("ff6b79") if health_ratio < 0.3 else (Color("ffd166") if health_ratio < 0.6 else Color("65e09e"))
	health_label.modulate = target_color
	if previous_health >= 0.0 and current < previous_health and UiMotion.should_animate():
		_punch(health_label, 1.1, 0.16)
		health_label.modulate = Color.WHITE
		create_tween().tween_property(health_label, "modulate", target_color, 0.22)
	previous_health = current

func update_time(elapsed: float, duration: float) -> void:
	var remaining := maxi(ceili(duration - elapsed), 0)
	time_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]

func update_faction_prelude(
	state: Dictionary,
	faction_name: String = "",
	accent: Color = Color("e4bd67"),
	marker_style: StringName = &"",
	primary: Color = Color.WHITE,
	secondary: Color = Color.WHITE
) -> void:
	prelude_active = bool(state.get("active", false))
	if not prelude_active:
		prelude_marker.clear()
		_sync_event_frame()
		return
	var remaining := maxi(ceili(float(state.get("end_seconds", 0.0)) - float(state.get("current_seconds", 0.0))), 0)
	prelude_label.text = "예고 T%d · %s · %d:%02d" % [
		maxi(int(state.get("tier", 0)), 1),
		faction_name if not faction_name.is_empty() else String(state.get("faction_id", "진영")),
		remaining / 60,
		remaining % 60,
	]
	prelude_label.add_theme_color_override("font_color", accent.lightened(0.18))
	prelude_marker.configure(marker_style, primary, secondary)
	prelude_label.tooltip_text = "이 진영의 공식 난입이 다가옵니다. 예고 종료 전에는 해당 진영 병력이 공용 스폰 예산 일부를 대체합니다."
	_sync_event_frame()

func update_target_position(target_position: Vector2, battle_rect: Rect2, _lane_count: int = Battlefield.LANE_COUNT) -> void:
	var normalized := (target_position - battle_rect.position) / battle_rect.size
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	lane_label.text = "%s  X%02d · Y%02d" % [ConceptService.term(&"cursor").to_upper(), roundi(normalized.x * 99.0), roundi(normalized.y * 99.0)]

func update_experience(current: float, required: float, level: int) -> void:
	experience_label.text = "LV.%d   %d / %d XP" % [level, floori(current), ceili(required)]
	experience_bar.max_value = required
	experience_bar.value = current
	if previous_level >= 0 and level > previous_level:
		_punch(experience_label, 1.12, 0.2)
	previous_level = level

func update_skill_charge(current: float, maximum: float) -> void:
	if skill_casting:
		return
	var ratio := current / maximum if maximum > 0.0 else 0.0
	skill_button.text = "%s  %d%%%s" % [_skill_label(), floori(ratio * 100.0), "" if compact_layout else "  [SPACE]"]
	var is_ready := ratio >= 1.0
	skill_button.disabled = not is_ready
	if is_ready and not skill_was_ready and UiMotion.should_animate():
		_punch(skill_button, 1.08, 0.2)
		skill_button.modulate = Color("9dffd8")
		create_tween().tween_property(skill_button, "modulate", Color.WHITE, 0.34)
	skill_was_ready = is_ready

func update_skill_cast(remaining: float, total: float) -> void:
	skill_casting = remaining > 0.0
	if skill_casting:
		skill_button.text = "%s 시전  %.1f초" % [_skill_label(), remaining]
		skill_button.disabled = true
		skill_button.modulate = Color("fff1a6").lerp(Color.WHITE, 1.0 - remaining / maxf(total, 0.01))
		return
	skill_button.text = "%s 발동!" % _skill_label()
	skill_button.disabled = true
	skill_button.modulate = Color.WHITE
	skill_was_ready = false

func update_game_speed(multiplier: float, enabled: bool = true) -> void:
	speed_button.text = "%d×%s" % [roundi(multiplier), "" if compact_layout else " [F]"]
	speed_button.disabled = not enabled
	if previous_speed > 0.0 and not is_equal_approx(previous_speed, multiplier):
		_punch(speed_button, 1.08, 0.15)
	previous_speed = multiplier

func update_range_overlay(enabled: bool) -> void:
	range_button.set_pressed_no_signal(enabled)
	range_button.text = ("확인 종료" if enabled else "사거리") + ("" if compact_layout else " [G]")
	range_button.modulate = Color("8fe8ff") if enabled else Color.WHITE

func _on_range_button_toggled(enabled: bool) -> void:
	update_range_overlay(enabled)
	range_overlay_requested.emit(enabled)

func update_build(summary: String) -> void:
	build_label.text = summary

func update_effects(global_effects: Array) -> void:
	global_count.text = str(global_effects.size())
	_rebuild_effect_list(global_list, global_effects)

func update_artifacts(artifacts: Array) -> void:
	artifact_count.text = "%d/6" % mini(artifacts.size(), 6)
	var slots: Array[Dictionary] = []
	for index in 6:
		if index < artifacts.size():
			slots.append((artifacts[index] as Dictionary).duplicate(true))
		else:
			slots.append({"name": "빈 슬롯", "description": "아티팩트를 획득하면 이 슬롯을 사용합니다.", "icon": &"default", "color": Color("536672"), "empty": true})
	_rebuild_effect_list(artifact_list, slots)
	var detail_lines: Array[String] = []
	for index in artifacts.size():
		var artifact := artifacts[index] as Dictionary
		detail_lines.append("%d. %s\n   %s%s" % [index + 1, artifact.get("name", "아티팩트"), artifact.get("description", ""), " · 장단점" if bool(artifact.get("trade_off", false)) else ""])
	artifact_detail_label.text = "\n\n".join(detail_lines) if not detail_lines.is_empty() else "보유한 아티팩트가 없습니다."
	if artifacts.is_empty():
		artifact_detail_panel.visible = false

func _toggle_artifact_details() -> void:
	artifact_detail_panel.visible = not artifact_detail_panel.visible
	artifact_detail_button.text = "상세 닫기" if artifact_detail_panel.visible else "유물 상세"

func _rebuild_effect_list(container: Container, effects: Array) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	if container is GridContainer:
		(container as GridContainer).columns = 3
	for effect_value in effects:
		var effect: Dictionary = effect_value
		container.add_child(_create_effect_icon(effect))

func _create_effect_icon(effect: Dictionary) -> PanelContainer:
	var color: Color = effect.get("color", Color("65e0c0"))
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(30.0, 30.0)
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.tooltip_text = "%s\n%s" % [effect.get("name", "효과"), effect.get("description", effect.get("subtitle", ""))]
	var style := UiStyleFactory.panel(Color(UiTokens.INK_DEEP, 0.78), Color(color, 0.82), 7, 1, 3.0)
	chip.add_theme_stylebox_override("panel", style)
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(canvas)
	var icon_key := StringName(effect.get("icon", &"default"))
	var icon := FLAT_EFFECT_ICON_SCRIPT.new().configure(icon_key, color)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(icon)
	var level := int(effect.get("level", 1))
	if level > 1:
		var badge := Label.new()
		badge.text = str(level)
		badge.anchor_left = 1.0
		badge.anchor_right = 1.0
		badge.offset_left = -15.0
		badge.offset_top = -2.0
		badge.offset_right = 1.0
		badge.offset_bottom = 14.0
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.07, 1))
		badge.add_theme_constant_override("outline_size", 4)
		badge.add_theme_font_size_override("font_size", 11)
		canvas.add_child(badge)
	return chip

func update_kills(kills: int, boss_kills: int) -> void:
	kill_label.text = "퇴장 %d · 난입 %d" % [kills, boss_kills]

func show_boss(
	display_name: String,
	accent: Color = Color("ffbf59"),
	marker_style: StringName = &"",
	primary: Color = Color.WHITE,
	secondary: Color = Color.WHITE
) -> void:
	_set_boss_mode(true)
	boss_label.text = display_name
	boss_label.add_theme_color_override("font_color", accent.lightened(0.18))
	boss_marker.configure(marker_style, primary, secondary)
	var fill := UiStyleFactory.panel(accent, accent, 5, 0, 0.0)
	boss_bar.add_theme_stylebox_override("fill", fill)
	boss_bar.value = 100.0
	warning_label.visible = false
	_sync_event_frame()

func update_boss_health(current: float, maximum: float, display_name: String) -> void:
	_set_boss_mode(true)
	boss_label.text = display_name
	boss_bar.max_value = maximum
	boss_bar.value = current
	_sync_event_frame()

func hide_boss() -> void:
	_set_boss_mode(false)
	boss_marker.clear()
	_sync_event_frame()

func _set_boss_mode(enabled: bool) -> void:
	boss_panel.visible = enabled
	experience_label.visible = not enabled
	experience_bar.visible = not enabled
	kill_label.visible = not enabled

func show_warning(
	message: String,
	accent: Color = Color("ffcf58"),
	marker_style: StringName = &"",
	primary: Color = Color.WHITE,
	secondary: Color = Color.WHITE
) -> void:
	warning_label.text = "⚠  %s" % message
	warning_label.modulate = accent.lightened(0.16)
	warning_label.visible = true
	warning_marker.configure(marker_style, primary, secondary)
	_punch(warning_label, 1.12, 0.18)
	%WarningTimer.start(6.0)
	_sync_event_frame()

func show_notice(message: String, duration: float = 2.2) -> void:
	warning_label.text = message
	warning_label.modulate = Color("8fe8ff")
	warning_label.visible = true
	warning_marker.clear()
	_punch(warning_label, 1.06, 0.14)
	%WarningTimer.start(duration)
	_sync_event_frame()

func _hide_warning() -> void:
	warning_label.visible = false
	warning_marker.clear()
	_sync_event_frame()

func _sync_event_frame() -> void:
	var show_prelude := prelude_active and not boss_panel.visible and not tutorial_mode
	prelude_label.visible = show_prelude
	prelude_marker.visible = show_prelude and prelude_marker.marker_style != &""
	event_frame.visible = prelude_label.visible or warning_label.visible or governance_audience.visible

func _punch(control: Control, peak_scale: float, duration: float) -> void:
	if UiMotion.is_reduced():
		control.scale = Vector2.ONE
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * peak_scale
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(control, "scale", Vector2.ONE, duration)

func show_result(result: Dictionary) -> void:
	result_overlay.show_overlay()
	set_combat_controls_enabled(false)
	var victory := bool(result.get("victory", false))
	result_title.text = ConceptService.ui_text(&"result.victory", {}, "방어 성공") if victory else ConceptService.ui_text(&"result.defeat", {}, "방어 실패")
	result_title.modulate = Color.WHITE
	result_title.add_theme_color_override(&"font_color", UiTokens.AXIS_SPEED.darkened(0.12) if victory else UiTokens.DANGER.darkened(0.08))
	var challenge_level := int(result.get("challenge_level", 0))
	var experience_bonus := roundi((float(result.get("challenge_experience_multiplier", 1.0)) - 1.0) * 100.0)
	result_subtitle.text = "%s  ·  도전 단계 %d  ·  경험치 +%d%%" % [String(result.get("stage_name", "10분 표준 스테이지")), challenge_level, experience_bonus]

	var duration := maxf(float(result.get("stage_duration_seconds", 600.0)), 1.0)
	var elapsed := clampf(float(result.get("elapsed", 0.0)), 0.0, duration)
	var progress_ratio := elapsed / duration
	result_timeline.configure(result, UiMotion.should_animate())
	_set_result_progress_text(0.0 if UiMotion.should_animate() else progress_ratio, elapsed, duration)

	var funds_earned := maxi(int(result.get("funds_earned", 0)), 0)
	var funds_total := maxi(int(result.get("defense_funds_total", 0)), 0)
	funds_earned_label.text = "+0  %s" % ConceptService.term(&"currency")
	funds_total_label.text = "0  %s" % ConceptService.term(&"currency")
	_set_reward_breakdown(result.get("funds_breakdown", {}))
	var support_required := maxi(int(result.get("candidate_support_required", 0)), 0)
	var support_earned := maxi(int(result.get("candidate_support_earned", 0)), 0)
	var support_total := maxi(int(result.get("candidate_support_total", 0)), 0)
	var has_candidate_support := not String(result.get("candidate_id", "")).is_empty() and support_required > 0
	candidate_support_section.visible = has_candidate_support
	if has_candidate_support:
		candidate_support_bar.max_value = support_required
		candidate_support_bar.value = maxi(support_total - support_earned, 0)
		candidate_support_label.text = "%s 지지도  +%d" % [String(result.get("candidate_name", "선택 후보")), support_earned]
		candidate_election_label.text = "당선 확정 · 마왕 등극" if bool(result.get("candidate_newly_elected", false)) else "%d / %d" % [support_total, support_required]
	var campaign := ConceptService.get_election_campaign()
	var approval := clampi(int(result.get("governance_approval", 0)), 0, 100)
	var governance_reaction := campaign.governance_reaction(approval) if campaign != null and bool(result.get("candidate_elected", false)) else null
	governance_result_label.visible = governance_reaction != null
	if governance_reaction != null:
		var result_line := governance_reaction.victory_line if victory else governance_reaction.defeat_line
		var approval_before := clampi(int(result.get("governance_approval_before", approval)), 0, 100)
		var approval_delta := int(result.get("governance_approval_delta", approval - approval_before))
		var approval_summary := "%d → %d (%s%d)" % [approval_before, approval, "+" if approval_delta > 0 else "", approval_delta] if approval_delta != 0 else str(approval)
		governance_result_label.text = "통치 %s %s · %s · “%s”" % [governance_reaction.display_name, approval_summary, governance_reaction.result_pose, result_line]
		governance_result_label.add_theme_color_override("font_color", governance_reaction.color)

	var boss_total := result_timeline.get_boss_count()
	var boss_kills := int(result.get("boss_kills", result_timeline.get_defeated_boss_count()))
	formation_board_preview.configure(
		result.get("formation_board", []) as Array,
		int(result.get("formation_board_width", 6)),
		int(result.get("formation_board_height", 4)),
		StringName(result.get("candidate_id", ""))
	)
	var retainer_contribution: Dictionary = result.get("retainer_contribution", {})
	var retainer_name := String(result.get("retainer_name", result.get("cursor", "심복")))
	var outcome_summary_text := _outcome_summary_text(result.get("outcome_summary", {}))
	var outcome_summary_block := "\n%s" % outcome_summary_text if not outcome_summary_text.is_empty() else ""
	var build_summary_text := _result_growth_summary(result.get("outcome_summary", {}), String(result.get("build", "없음")))
	result_detail.text = "Lv.%d  ·  퇴장 %s  ·  공식 난입 제압 %d/%d  ·  경험치 %s  ·  %s 연설 지속력 %s\n%s  ·  심복 %s%s\n%s  ·  최고 피해  %s%s\n신규 해금  %s\n최종 성장  %s" % [
		int(result.get("level", 1)), _format_number(int(result.get("kills", 0))), boss_kills, boss_total,
		_format_number(floori(float(result.get("experience", 0.0)))), ConceptService.term(&"core"), _format_number(ceili(float(result.get("core_health", 0.0)))),
		String(result.get("core", ConceptService.term(&"core"))), retainer_name,
		"  ·  칙령 %s" % String(result.get("decree_name", "")) if not String(result.get("decree_name", "")).is_empty() else "",
		_retainer_contribution_text(retainer_contribution),
		String(result.get("top_tower", "없음")),
		outcome_summary_block,
		String(result.get("unlocked", "없음")), build_summary_text,
	]
	_play_result_animation(progress_ratio, elapsed, duration, funds_earned, funds_total, support_total if has_candidate_support else -1)
	restart_button.grab_focus()

func _retainer_contribution_text(contribution: Dictionary) -> String:
	var parts: Array[String] = ["피해 %s" % _format_number(roundi(float(contribution.get("damage", 0.0))))]
	var control := int(contribution.get("control_applications", 0))
	var collection := float(contribution.get("collection_experience", 0.0))
	var executions := int(contribution.get("executions", 0))
	var unique_uses := int(contribution.get("unique_uses", 0))
	if control > 0: parts.append("제어 %d" % control)
	if collection > 0.0: parts.append("회수 %s XP" % _format_number(roundi(collection)))
	if executions > 0: parts.append("처형 %d" % executions)
	if unique_uses > 0: parts.append("고유 %d" % unique_uses)
	return "심복 기여 [%s] · %s" % [String(contribution.get("role", "전투 지원")), " · ".join(parts)]

func _outcome_summary_text(value: Variant) -> String:
	var summary: Dictionary = value if value is Dictionary else {}
	if summary.is_empty():
		return ""
	var lines: PackedStringArray = []
	var formation := summary.get("formation", {}) as Dictionary
	var regular_formations := maxi(int(formation.get("regular_formations", 0)), 0)
	var regular_units := maxi(int(formation.get("regular_units", 0)), 0)
	var guard_units := maxi(int(formation.get("guard_units", 0)), 0)
	var guard_damage := maxf(float(formation.get("guard_damage", 0.0)), 0.0)
	var formation_parts: PackedStringArray = []
	if regular_formations > 0:
		formation_parts.append("일반 %d세트/%d기" % [regular_formations, regular_units])
	if guard_units > 0:
		formation_parts.append("친위대 %d기" % guard_units)
	if guard_damage > 0.0:
		formation_parts.append("친위대 피해 %s" % _format_number(roundi(guard_damage)))
	if not formation_parts.is_empty():
		lines.append("편대 기여 · %s" % " · ".join(formation_parts))
	var status := summary.get("status", {}) as Dictionary
	var active_status_count := maxi(int(status.get("active_status_count", 0)), 0)
	if active_status_count > 0:
		var top_status_id := StringName(status.get("top_status_id", ""))
		var top_applications := maxi(int(status.get("top_applications", 0)), 0)
		var total_damage := maxf(float(status.get("total_damage", 0.0)), 0.0)
		var status_parts: PackedStringArray = ["%d종" % active_status_count]
		if top_status_id != &"":
			status_parts.append("주력 %s %d회" % [_result_status_name(top_status_id), top_applications])
		if total_damage > 0.0:
			status_parts.append("피해 %s" % _format_number(roundi(total_damage)))
		lines.append("상태 기여 · %s" % " · ".join(status_parts))
	var enemy_activity := summary.get("enemy", {}) as Dictionary
	if not enemy_activity.is_empty():
		var faction_spawns := 0
		for event_value in enemy_activity.get("spawns", []) as Array:
			var event := event_value as Dictionary
			if not String(event.get("faction_id", "")).is_empty():
				faction_spawns += 1
		var acceleration_count := (enemy_activity.get("accelerations", []) as Array).size()
		var disabled_targets := 0
		for disable_value in enemy_activity.get("defender_disables", []) as Array:
			disabled_targets += maxi(int((disable_value as Dictionary).get("target_count", 0)), 0)
		var breach_count := maxi(int(enemy_activity.get("breach_count", 0)), 0)
		if faction_spawns > 0 or acceleration_count > 0 or disabled_targets > 0 or breach_count > 0:
			lines.append("적 관측 · 팩션 %d · 돌파 %d · 가속 %d · 마비 %d" % [faction_spawns, breach_count, acceleration_count, disabled_targets])
	var artifacts := summary.get("artifacts", {}) as Dictionary
	if not artifacts.is_empty():
		var final_inventory := artifacts.get("final_inventory", {}) as Dictionary
		var artifact_count := maxi(int(final_inventory.get("count", 0)), 0)
		var offers := maxi(int(artifacts.get("offers", 0)), 0)
		var acquisitions := maxi(int(artifacts.get("acquisitions", 0)), 0)
		var discards := maxi(int(artifacts.get("discards", 0)), 0)
		var replacements := maxi(int(artifacts.get("replacements", 0)), 0)
		var contribution := artifacts.get("effect_contribution", {}) as Dictionary
		var estimated_delta := float(contribution.get("estimated_output_delta", 0.0))
		if artifact_count > 0 or offers > 0:
			var contribution_text := " · 추정 기여 %s" % _format_number(roundi(estimated_delta)) if not is_zero_approx(estimated_delta) else ""
			lines.append("아티팩트 · 보유 %d/6 · 제안 %d / 획득 %d / 포기 %d / 교체 %d%s" % [artifact_count, offers, acquisitions, discards, replacements, contribution_text])
	var spawn := summary.get("spawn", {}) as Dictionary
	var base_count := maxi(int(spawn.get("base_count", 0)), 0)
	var bonus_count := maxi(int(spawn.get("bonus_count", 0)), 0)
	var packet_parts: PackedStringArray = []
	for packet_value in spawn.get("packets", []) as Array:
		var packet := packet_value as Dictionary
		packet_parts.append("%s %d" % [String(packet.get("display_name", packet.get("packet_id", "패킷"))), maxi(int(packet.get("count", 0)), 0)])
	if base_count > 0 or bonus_count > 0 or not packet_parts.is_empty():
		var spawn_parts: PackedStringArray = ["기본 %d / 추가 %d (XP %d%%)" % [base_count, bonus_count, roundi(clampf(float(spawn.get("bonus_experience_ratio", 0.0)), 0.0, 1.0) * 100.0)]]
		spawn_parts.append_array(packet_parts)
		lines.append("Spawn 처리 · %s" % " · ".join(spawn_parts))
	return "\n".join(lines)

func _result_status_name(status_id: StringName) -> String:
	match status_id:
		&"slow": return "둔화"
		&"mark": return "취약"
		&"fear": return "공포"
		&"stun": return "기절"
		&"charm": return "환혹"
	return CommonStatusCatalog.display_name(status_id)

func _result_growth_summary(value: Variant, fallback: String) -> String:
	var summary: Dictionary = value if value is Dictionary else {}
	if summary.is_empty():
		return fallback
	var growth := summary.get("growth", {}) as Dictionary
	var formation := summary.get("formation", {}) as Dictionary
	return "후보 %d/3 · 친위대 %d/3 · 심복 Lv.%d · 일반 편대 %d세트 · 아티팩트 %d/6" % [
		clampi(int(growth.get("candidate_slots", 0)), 0, 3),
		clampi(int(growth.get("guard_stage", 0)), 0, 3),
		maxi(int(growth.get("retainer_level", 1)), 1),
		maxi(int(formation.get("regular_formations", 0)), 0),
		clampi(int(growth.get("artifact_count", 0)), 0, 6),
	]

func _set_reward_breakdown(value: Variant) -> void:
	var breakdown: Dictionary = value if value is Dictionary else {}
	var progress_funds := int(breakdown.get("progress_funds", 0))
	var boss_funds := int(breakdown.get("boss_funds", 0))
	var victory_funds := int(breakdown.get("victory_funds", 0))
	var challenge_multiplier := float(breakdown.get("challenge_multiplier", 1.0))
	var first_clear_funds := int(breakdown.get("first_clear_funds", 0))
	reward_breakdown_label.text = "진행 +%s  ·  공식 난입 제압 +%s  ·  완주 +%s  ·  도전 ×%.2f%s" % [
		_format_number(progress_funds), _format_number(boss_funds), _format_number(victory_funds), challenge_multiplier,
		"  ·  첫 클리어 +%s" % _format_number(first_clear_funds) if first_clear_funds > 0 else "",
	]

func _play_result_animation(progress_ratio: float, elapsed: float, duration: float, funds_earned: int, funds_total: int, support_total: int = -1) -> void:
	for tween in result_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	result_tweens.clear()
	if UiMotion.is_reduced():
		result_panel.scale = Vector2.ONE
		result_panel.modulate = Color.WHITE
		_set_result_progress_text(progress_ratio, elapsed, duration)
		funds_earned_label.text = "+%s  %s" % [_format_number(funds_earned), ConceptService.term(&"currency")]
		funds_total_label.text = "%s  %s" % [_format_number(funds_total), ConceptService.term(&"currency")]
		if support_total >= 0:
			candidate_support_bar.value = support_total
		return

	result_panel.pivot_offset = result_panel.size * 0.5
	result_panel.scale = Vector2.ONE * 0.96
	result_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var entrance := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	entrance.tween_property(result_panel, "scale", Vector2.ONE, 0.28)
	entrance.tween_property(result_panel, "modulate", Color.WHITE, 0.22)
	result_tweens.append(entrance)

	var counters := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	counters.tween_method(func(value: float) -> void: _set_result_progress_text(value, elapsed, duration), 0.0, progress_ratio, 1.0).set_delay(0.16)
	counters.tween_method(func(value: float) -> void: funds_earned_label.text = "+%s  %s" % [_format_number(roundi(value)), ConceptService.term(&"currency")], 0.0, float(funds_earned), 0.72).set_delay(0.32)
	counters.tween_method(func(value: float) -> void: funds_total_label.text = "%s  %s" % [_format_number(roundi(value)), ConceptService.term(&"currency")], 0.0, float(funds_total), 0.82).set_delay(0.38)
	if support_total >= 0:
		counters.tween_property(candidate_support_bar, "value", float(support_total), 0.82).set_delay(0.42)
	result_tweens.append(counters)

func _set_result_progress_text(ratio: float, elapsed: float, duration: float) -> void:
	var displayed_elapsed := floori(elapsed * ratio / maxf(elapsed / duration, 0.0001)) if ratio > 0.0 else 0
	if elapsed <= 0.0:
		displayed_elapsed = 0
	displayed_elapsed = mini(displayed_elapsed, floori(elapsed))
	var duration_seconds := floori(duration)
	result_progress_label.text = "%d%%  ·  %02d:%02d / %02d:%02d" % [
		roundi(ratio * 100.0), displayed_elapsed / 60, displayed_elapsed % 60,
		duration_seconds / 60, duration_seconds % 60,
	]

func _format_number(value: int) -> String:
	var negative := value < 0
	var digits := str(absi(value))
	var formatted := ""
	while digits.length() > 3:
		formatted = ",%s%s" % [digits.right(3), formatted]
		digits = digits.left(digits.length() - 3)
	formatted = digits + formatted
	return "-%s" % formatted if negative else formatted

func set_combat_controls_enabled(enabled: bool) -> void:
	if not enabled:
		skill_button.disabled = true
	speed_button.disabled = not enabled
	range_button.disabled = not enabled
	pause_button.disabled = not enabled

func apply_safe_area(viewport_size: Vector2i, safe_rect: Rect2i) -> void:
	var normalized_safe := safe_rect.intersection(Rect2i(Vector2i.ZERO, viewport_size))
	var has_safe_rect := normalized_safe.size.x > 0 and normalized_safe.size.y > 0
	var left := maxf(18.0, float(normalized_safe.position.x)) if has_safe_rect else 18.0
	var top := maxf(8.0, float(normalized_safe.position.y)) if has_safe_rect else 8.0
	var right := maxf(18.0, float(viewport_size.x - normalized_safe.end.x)) if has_safe_rect else 18.0
	var bottom := maxf(12.0, float(viewport_size.y - normalized_safe.end.y)) if has_safe_rect else 12.0
	top_bar.offset_left = left
	top_bar.offset_top = top
	top_bar.offset_right = -right
	top_bar.offset_bottom = maxf(98.0, top + 90.0)
	effect_panels.offset_left = left
	effect_panels.offset_right = left + 124.0
	effect_panels.offset_top = maxf(108.0, top + 100.0)
	event_frame.offset_top = maxf(108.0, top + 100.0)
	event_frame.offset_right = -right
	event_frame.offset_left = -right - (522.0 if tutorial_mode else 312.0)
	bottom_info.offset_right = -right
	bottom_info.offset_bottom = -bottom
	bottom_info_toggle.offset_left = left
	bottom_info_toggle.offset_right = left + 124.0
	bottom_info_toggle.offset_top = -bottom - 48.0
	bottom_info_toggle.offset_bottom = -bottom
	_apply_responsive_layout(viewport_size.x)

func set_safe_area_override(safe_rect: Rect2i) -> void:
	_safe_rect_override = safe_rect
	_has_safe_rect_override = true
	_refresh_safe_area()

func clear_safe_area_override() -> void:
	_has_safe_rect_override = false
	_refresh_safe_area()

func _refresh_safe_area() -> void:
	if not is_node_ready():
		return
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size.round())
	var safe_rect := _safe_rect_override if _has_safe_rect_override else UiSafeAreaLayout.current_safe_rect(viewport_size)
	apply_safe_area(viewport_size, safe_rect)

func _apply_responsive_layout(viewport_width: int) -> void:
	var next_compact := viewport_width < COMPACT_LAYOUT_WIDTH
	compact_layout = next_compact
	run_context_panel.custom_minimum_size.x = 220.0 if compact_layout else 286.0
	combat_actions_panel.custom_minimum_size.x = 358.0 if compact_layout else 442.0
	skill_button.custom_minimum_size.x = 126.0 if compact_layout else 166.0
	speed_button.custom_minimum_size.x = 64.0 if compact_layout else 78.0
	range_button.custom_minimum_size.x = 84.0 if compact_layout else 112.0
	pause_button.custom_minimum_size.x = UiTokens.TOUCH_TARGET_MIN if compact_layout else 52.0
	lane_label.visible = not compact_layout
	kill_label.visible = not compact_layout
	if compact_layout:
		skill_button.text = skill_button.text.replace("  [SPACE]", "")
		speed_button.text = speed_button.text.replace(" [F]", "")
		range_button.text = range_button.text.replace(" [G]", "")
