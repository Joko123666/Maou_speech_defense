class_name UiChoiceCard
extends Button

signal details_requested

const TAG_SCENE := preload("res://scenes/ui/components/tag_chip.tscn")

@onready var icon_rect: TextureRect = %Icon
@onready var fallback_icon: FlatEffectIcon = %FallbackIcon
@onready var icon_frame: PanelContainer = %IconFrame
@onready var header_panel: PanelContainer = %HeaderPanel
@onready var header: VBoxContainer = %Header
@onready var eyebrow_label: Label = %Eyebrow
@onready var title_label: Label = %Title
@onready var change_panel: PanelContainer = %ChangePanel
@onready var effect_label: RichTextLabel = %Effect
@onready var visual_host: HBoxContainer = %VisualHost
@onready var tags_container: HBoxContainer = %Tags
@onready var description_panel: PanelContainer = %DescriptionPanel
@onready var description_label: Label = %Description
@onready var detail_rail: Control = %DetailRail
@onready var selection_panel: PanelContainer = %SelectionPanel
@onready var selection_label: Label = %SelectionLabel

var accent_color := UiTokens.INK_ROYAL
var selected_state := false
var selection_text := "선택"

func _ready() -> void:
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 280.0), maxf(custom_minimum_size.y, 460.0))
	UiStyleFactory.apply_button(self, accent_color, selected_state)
	for child in find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(data: Dictionary) -> void:
	accent_color = data.get("accent", UiTokens.INK_ROYAL) as Color
	eyebrow_label.text = String(data.get("eyebrow", ""))
	eyebrow_label.visible = not eyebrow_label.text.is_empty()
	title_label.text = String(data.get("title", "선택 항목"))
	effect_label.text = String(data.get("effect", ""))
	if effect_label.text.is_empty():
		effect_label.text = "[center]효과 정보는 상세에서 확인할 수 있습니다.[/center]"
	effect_label.visible = true
	var compact_content := bool(data.get("compact", false))
	var effect_font_size := 14 if compact_content else UiTokens.FONT_BODY
	effect_label.add_theme_font_size_override(&"normal_font_size", effect_font_size)
	effect_label.add_theme_font_size_override(&"bold_font_size", effect_font_size)
	description_label.text = String(data.get("description", ""))
	if description_label.text.is_empty():
		description_label.text = "선택 즉시 이 변화가 적용됩니다."
	description_label.visible = true
	description_label.add_theme_font_size_override(&"font_size", 13)
	icon_rect.texture = data.get("icon", null) as Texture2D
	icon_rect.visible = icon_rect.texture != null
	fallback_icon.configure(StringName(data.get("icon_key", &"global")), data.get("icon_color", accent_color) as Color)
	fallback_icon.visible = icon_rect.texture == null
	icon_frame.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED.lerp(accent_color, 0.10), accent_color, UiTokens.RADIUS_SMALL, 2, 4.0))
	set_tags(data.get("tags", []) as Array)
	tags_container.visible = true
	selection_text = String(data.get("selection_label", "선택"))
	selection_label.text = "선택됨" if selected_state else selection_text
	tooltip_text = String(data.get("tooltip", "%s\n%s" % [title_label.text, description_label.text]))
	_apply_state_style()

func set_tags(tags: Array) -> void:
	for child in tags_container.get_children():
		tags_container.remove_child(child)
		child.queue_free()
	for tag_value in tags:
		var chip := TAG_SCENE.instantiate() as UiTagChip
		tags_container.add_child(chip)
		chip.configure(String(tag_value), accent_color)

func clear_visuals() -> void:
	for child in visual_host.get_children():
		visual_host.remove_child(child)
		child.queue_free()

func get_visual_host() -> HBoxContainer:
	return visual_host

func set_selected_state(value: bool) -> void:
	selected_state = value
	selection_label.text = "선택됨" if value else selection_text
	_apply_state_style()

func set_locked(value: bool, reason: String = "") -> void:
	disabled = value
	if value:
		selection_label.text = "잠김"
		if not reason.is_empty():
			tooltip_text = reason
	else:
		selection_label.text = "선택됨" if selected_state else selection_text

func _apply_state_style() -> void:
	if not is_node_ready():
		return
	var styles := UiStyleFactory.card(accent_color, selected_state)
	for key in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(key, styles[key] as StyleBox)
	add_theme_color_override(&"font_color", styles.font_color)
	add_theme_color_override(&"font_disabled_color", styles.font_disabled_color)
	var priority_background := UiTokens.INK_MUTED.darkened(0.18) if disabled else UiTokens.INK_DEEP.lerp(accent_color, 0.34 if selected_state else 0.24)
	var priority_border := Color(UiTokens.DISABLED_INK, 0.72) if disabled else accent_color
	header_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(priority_background, priority_border, UiTokens.RADIUS_SMALL, 2, 4.0))
	selection_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(priority_background, priority_border, UiTokens.RADIUS_SMALL, 2, 6.0))
	title_label.add_theme_color_override(&"font_color", UiTokens.SURFACE_PARCHMENT)
	eyebrow_label.add_theme_color_override(&"font_color", UiTokens.SURFACE_PARCHMENT.lerp(accent_color.lightened(0.35), 0.48))
	selection_label.add_theme_color_override(&"font_color", UiTokens.SURFACE_PARCHMENT)
	var content_background := UiTokens.SURFACE_PARCHMENT_MUTED.lerp(accent_color, 0.08)
	var content_border := Color(accent_color, 0.34)
	change_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(content_background, content_border, UiTokens.RADIUS_SMALL, 1, 4.0))
	description_panel.add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED, Color(accent_color, 0.24), UiTokens.RADIUS_SMALL, 1, 4.0))
	effect_label.add_theme_color_override(&"default_color", UiTokens.INK_ROYAL)
	description_label.add_theme_color_override(&"font_color", UiTokens.INK_MUTED)
