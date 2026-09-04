class_name UnitInfoPopover
extends Control

signal close_requested

const TAG_SCENE := preload("res://scenes/ui/components/tag_chip.tscn")
const STAT_ROW_SCENE := preload("res://scenes/ui/components/stat_row.tscn")
const CORE_PANEL_SIZE := Vector2(360.0, 552.0)
const TOWER_PANEL_SIZE := Vector2(360.0, 500.0)
const ANCHOR_GAP := 52.0

@onready var panel: PanelContainer = %Panel
@onready var portrait_frame: PanelContainer = %PortraitFrame
@onready var portrait: TextureRect = %Portrait
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var faction_label: Label = %Faction
@onready var close_button: Button = %CloseButton
@onready var tags: HBoxContainer = %Tags
@onready var status_panel: PanelContainer = %StatusPanel
@onready var status_label: Label = %Status
@onready var health_container: VBoxContainer = %HealthContainer
@onready var health_label: Label = %HealthLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var stats: VBoxContainer = %Stats
@onready var details_panel: PanelContainer = %DetailsPanel
@onready var details_label: Label = %Details
@onready var interaction_hint: Label = %InteractionHint

var current_snapshot: Dictionary = {}
var anchor_screen_position := Vector2.ZERO
var layout_viewport_size := Vector2i(1280, 720)
var layout_safe_rect := Rect2i()
var current_panel_size := TOWER_PANEL_SIZE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = TOWER_PANEL_SIZE
	panel.size = TOWER_PANEL_SIZE
	close_button.pressed.connect(func() -> void: close_requested.emit())
	visible = false

func show_snapshot(snapshot: Dictionary, anchor_position: Vector2, viewport_size: Vector2i, safe_rect: Rect2i = Rect2i()) -> void:
	if snapshot.is_empty() or int(snapshot.get("schema_version", 0)) != UnitInfoPresenter.SCHEMA_VERSION:
		hide_popover()
		return
	current_snapshot = snapshot.duplicate(true)
	anchor_screen_position = anchor_position
	layout_viewport_size = viewport_size
	layout_safe_rect = safe_rect
	_apply_snapshot()
	visible = true
	_position_panel()

func hide_popover() -> void:
	current_snapshot.clear()
	visible = false

func apply_safe_rect(viewport_size: Vector2i, safe_rect: Rect2i) -> void:
	layout_viewport_size = viewport_size
	layout_safe_rect = safe_rect
	if visible:
		_position_panel()

func get_snapshot() -> Dictionary:
	return current_snapshot.duplicate(true)

func get_panel_rect() -> Rect2:
	return Rect2(panel.position, current_panel_size)

func get_safe_bounds() -> Rect2:
	var margins := UiSafeAreaLayout.resolve_margins(layout_viewport_size, layout_safe_rect)
	return Rect2(
		Vector2(margins.x, margins.y),
		Vector2(layout_viewport_size) - Vector2(margins.x + margins.z, margins.y + margins.w)
	)

func _apply_snapshot() -> void:
	var accent: Color = current_snapshot.get("accent", UiTokens.FACTION_ALLY) as Color
	panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(Color(UiTokens.INK_DEEP, 0.97), Color(accent, 0.92), UiTokens.RADIUS_CARD, 2, float(UiTokens.SPACE_4)))
	portrait_frame.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(Color(accent, 0.16), Color(accent, 0.9), UiTokens.RADIUS_SMALL, 2, 6.0))
	status_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(Color(accent, 0.12), Color(accent, 0.7), UiTokens.RADIUS_SMALL, 1, 8.0))
	details_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(Color(UiTokens.SURFACE_PARCHMENT, 0.08), Color(UiTokens.ACCENT_GOLD, 0.54), UiTokens.RADIUS_SMALL, 1, 10.0))
	UiStyleFactory.apply_hud_button(close_button, accent)
	title_label.text = String(current_snapshot.get("title", "대상 정보"))
	subtitle_label.text = String(current_snapshot.get("subtitle", ""))
	faction_label.text = String(current_snapshot.get("faction_label", "소속 · 확인 필요"))
	portrait.texture = current_snapshot.get("texture") as Texture2D
	portrait.visible = portrait.texture != null
	status_label.text = "상태 · %s" % String(current_snapshot.get("status_label", "확인 필요"))
	var status_color := UiTokens.semantic_color(current_snapshot.get("status_role", &"ally") as StringName, accent)
	status_label.add_theme_color_override(&"font_color", status_color.lightened(0.28))
	_apply_tags(current_snapshot.get("role_tags", []) as Array, accent)
	_apply_health()
	_apply_stats(current_snapshot.get("stats", []) as Array)
	var detail_lines: Array = current_snapshot.get("detail_lines", []) as Array
	details_label.text = "\n".join(detail_lines)
	details_panel.visible = not detail_lines.is_empty()
	var pinned := bool(current_snapshot.get("pinned", false))
	interaction_hint.text = "고정됨 · 바깥 탭 또는 ESC로 닫기" if pinned else "미리보기 · 클릭하거나 사거리 모드에서 탭해 고정"
	close_button.visible = pinned
	close_button.disabled = not pinned
	close_button.tooltip_text = "선택 정보 닫기"
	panel.tooltip_text = "%s · %s" % [title_label.text, status_label.text]

func _apply_tags(tag_values: Array, accent: Color) -> void:
	for child in tags.get_children():
		child.free()
	for tag_index in tag_values.size():
		var tag := TAG_SCENE.instantiate() as UiTagChip
		tags.add_child(tag)
		tag.configure(String(tag_values[tag_index]), accent if tag_index == 0 else UiTokens.ACCENT_GOLD)

func _apply_health() -> void:
	var maximum := float(current_snapshot.get("health_maximum", 0.0))
	var current := clampf(float(current_snapshot.get("health_current", 0.0)), 0.0, maximum)
	health_container.visible = maximum > 0.0
	if not health_container.visible:
		return
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "생존력 · %.0f / %.0f" % [current, maximum]

func _apply_stats(stat_values: Array) -> void:
	for child in stats.get_children():
		child.free()
	for stat_value in stat_values:
		var stat := stat_value as Dictionary
		var row := STAT_ROW_SCENE.instantiate() as UiStatRow
		stats.add_child(row)
		var accent := UiTokens.semantic_color(stat.get("role", &"ink") as StringName)
		row.configure(String(stat.get("label", "수치")), String(stat.get("value", "-")), "", accent)
		row.name_label.add_theme_color_override(&"font_color", Color(UiTokens.SURFACE_PARCHMENT, 0.72))
		row.value_label.add_theme_color_override(&"font_color", accent.lightened(0.26))

func _position_panel() -> void:
	current_panel_size = CORE_PANEL_SIZE if current_snapshot.get("kind", &"") == &"core" else TOWER_PANEL_SIZE
	panel.custom_minimum_size = current_panel_size
	panel.size = current_panel_size
	var safe_bounds := get_safe_bounds()
	var preferred := anchor_screen_position + Vector2(ANCHOR_GAP, -current_panel_size.y * 0.15)
	if preferred.x + current_panel_size.x > safe_bounds.end.x:
		preferred.x = anchor_screen_position.x - current_panel_size.x - ANCHOR_GAP
	if preferred.y + current_panel_size.y > safe_bounds.end.y:
		preferred.y = safe_bounds.end.y - current_panel_size.y
	preferred.x = clampf(preferred.x, safe_bounds.position.x, safe_bounds.end.x - current_panel_size.x)
	preferred.y = clampf(preferred.y, safe_bounds.position.y, safe_bounds.end.y - current_panel_size.y)
	panel.position = preferred.round()
