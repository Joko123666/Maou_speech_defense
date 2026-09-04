class_name UiModalShell
extends Control

signal close_requested

@onready var safe_area: MarginContainer = %SafeArea
@onready var dimmer: ColorRect = %Dimmer
@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %Title
@onready var close_button: Button = %CloseButton
@onready var body_scroll: ScrollContainer = %BodyScroll
@onready var body_container: VBoxContainer = %Body
@onready var footer_container: HBoxContainer = %Footer

var dismissible := true
var _focus_before_open: Control
var _preferred_panel_minimum_size := Vector2(640.0, 360.0)
var _safe_rect_override := Rect2i()
var _has_safe_rect_override := false

func _ready() -> void:
	panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT, UiTokens.INK_ROYAL, UiTokens.RADIUS_MODAL, 3, float(UiTokens.SPACE_6)))
	UiStyleFactory.apply_button(close_button)
	close_button.tooltip_text = "대화상자를 닫고 이전 항목으로 돌아갑니다."
	close_button.pressed.connect(_request_close)
	_refresh_safe_area()
	get_viewport().size_changed.connect(_refresh_safe_area)

func configure(title: String, can_dismiss: bool = true) -> void:
	title_label.text = title
	set_dismissible(can_dismiss)

func set_panel_minimum_size(value: Vector2) -> void:
	_preferred_panel_minimum_size = value
	_refresh_safe_area()

func show_modal(initial_focus: Control = null) -> void:
	_focus_before_open = get_viewport().gui_get_focus_owner()
	body_scroll.scroll_vertical = 0
	visible = true
	refresh_focus_cycle()
	if initial_focus != null and initial_focus.is_visible_in_tree() and initial_focus.focus_mode != Control.FOCUS_NONE:
		initial_focus.grab_focus.call_deferred()

func hide_modal(restore_focus: bool = true) -> void:
	visible = false
	if restore_focus and is_instance_valid(_focus_before_open) and _focus_before_open.is_inside_tree():
		_focus_before_open.grab_focus.call_deferred()
	_focus_before_open = null

func set_dismissible(value: bool) -> void:
	dismissible = value
	close_button.visible = value

func apply_safe_area(viewport_size: Vector2i, safe_rect: Rect2i) -> void:
	var margins := UiSafeAreaLayout.resolve_margins(viewport_size, safe_rect)
	UiSafeAreaLayout.apply_to(safe_area, margins)
	panel.custom_minimum_size = _preferred_panel_minimum_size.min(UiSafeAreaLayout.available_size(viewport_size, margins))

func set_safe_area_override(safe_rect: Rect2i) -> void:
	_safe_rect_override = safe_rect
	_has_safe_rect_override = true
	_refresh_safe_area()

func clear_safe_area_override() -> void:
	_has_safe_rect_override = false
	_refresh_safe_area()

func refresh_focus_cycle(preferred: Control = null) -> void:
	UiFocusFlow.link_cycle(self)
	if preferred != null and preferred.is_visible_in_tree() and preferred.focus_mode != Control.FOCUS_NONE:
		preferred.grab_focus.call_deferred()

func get_body() -> VBoxContainer:
	return body_container

func get_body_scroll() -> ScrollContainer:
	return body_scroll

func get_footer() -> HBoxContainer:
	return footer_container

func _unhandled_key_input(event: InputEvent) -> void:
	if dismissible and event.is_action_pressed(&"ui_cancel"):
		_request_close()
		get_viewport().set_input_as_handled()

func _request_close() -> void:
	if dismissible:
		close_requested.emit()

func _refresh_safe_area() -> void:
	if not is_node_ready():
		return
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size.round())
	var safe_rect := _safe_rect_override if _has_safe_rect_override else UiSafeAreaLayout.current_safe_rect(viewport_size)
	apply_safe_area(viewport_size, safe_rect)
