class_name UiTagChip
extends PanelContainer

@onready var text_label: Label = %Text

var _configured_text := "태그"
var _configured_accent := UiTokens.INK_ROYAL

func _ready() -> void:
	custom_minimum_size.y = UiTokens.TAG_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	configure(_configured_text, _configured_accent)

func configure(label_text: String, accent: Color = UiTokens.INK_ROYAL) -> void:
	_configured_text = label_text
	_configured_accent = accent
	if not is_node_ready():
		return
	text_label.text = label_text
	text_label.add_theme_color_override(&"font_color", accent.darkened(0.2))
	add_theme_stylebox_override(&"panel", UiStyleFactory.tag(accent))
