class_name UiPageShell
extends MarginContainer

signal back_requested

@onready var back_button: Button = %BackButton
@onready var header_container: HBoxContainer = %Header
@onready var eyebrow_label: Label = %Eyebrow
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var status_label: Label = %Status
@onready var surface_panel: PanelContainer = %Surface
@onready var body_container: VBoxContainer = %Body

var _remembered_focus: Control
var _safe_rect_override := Rect2i()
var _has_safe_rect_override := false

func _ready() -> void:
	_refresh_safe_area()
	get_viewport().size_changed.connect(_refresh_safe_area)
	UiStyleFactory.apply_button(back_button)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	surface_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(
		UiTokens.SURFACE_PARCHMENT,
		UiTokens.INK_ROYAL,
		UiTokens.RADIUS_MODAL,
		2,
		float(UiTokens.SPACE_4)
	))

func configure(
	title: String,
	subtitle: String = "",
	show_back: bool = true,
	eyebrow: String = "",
	status: String = ""
) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.visible = not subtitle.is_empty()
	back_button.visible = show_back
	eyebrow_label.text = eyebrow
	eyebrow_label.visible = not eyebrow.is_empty()
	status_label.text = status
	status_label.visible = not status.is_empty()

func set_header_visible(value: bool) -> void:
	header_container.visible = value

func set_surface_style(style: StyleBox) -> void:
	surface_panel.add_theme_stylebox_override(&"panel", style)

func apply_safe_area(viewport_size: Vector2i, safe_rect: Rect2i) -> void:
	UiSafeAreaLayout.apply_to(self, UiSafeAreaLayout.resolve_margins(viewport_size, safe_rect))

func set_safe_area_override(safe_rect: Rect2i) -> void:
	_safe_rect_override = safe_rect
	_has_safe_rect_override = true
	_refresh_safe_area()

func clear_safe_area_override() -> void:
	_has_safe_rect_override = false
	_refresh_safe_area()

func get_body() -> VBoxContainer:
	return body_container

func remember_focus(control: Control = null) -> void:
	var focused := control if control != null else get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused) and not focused.is_queued_for_deletion() and is_ancestor_of(focused):
		_remembered_focus = focused

func restore_focus(fallback: Control = null) -> void:
	var target := _remembered_focus if is_instance_valid(_remembered_focus) and _remembered_focus.is_visible_in_tree() else fallback
	if target != null and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus.call_deferred()

func reset_scroll_positions(root: Node = null) -> void:
	if root == null:
		root = body_container
	if root is ScrollContainer:
		(root as ScrollContainer).scroll_horizontal = 0
		(root as ScrollContainer).scroll_vertical = 0
	for child in root.get_children():
		reset_scroll_positions(child)

func _refresh_safe_area() -> void:
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size.round())
	var safe_rect := _safe_rect_override if _has_safe_rect_override else UiSafeAreaLayout.current_safe_rect(viewport_size)
	apply_safe_area(viewport_size, safe_rect)
