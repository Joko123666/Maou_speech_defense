class_name UiIconChip
extends Button

@onready var icon_rect: TextureRect = %Icon
@onready var text_label: Label = %Text

var accent_color := UiTokens.INK_ROYAL
var selected_state := false

func _ready() -> void:
	custom_minimum_size.x = maxf(custom_minimum_size.x, UiTokens.TOUCH_TARGET_MIN)
	custom_minimum_size.y = maxf(custom_minimum_size.y, UiTokens.TOUCH_TARGET_MIN)
	UiStyleFactory.apply_button(self, accent_color, selected_state)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(label_text: String, icon_texture: Texture2D = null, accent: Color = UiTokens.INK_ROYAL, selected: bool = false) -> void:
	text_label.text = label_text
	icon_rect.texture = icon_texture
	icon_rect.visible = icon_texture != null
	accent_color = accent
	selected_state = selected
	UiStyleFactory.apply_button(self, accent_color, selected_state)
	tooltip_text = label_text

func set_selected_state(value: bool) -> void:
	selected_state = value
	UiStyleFactory.apply_button(self, accent_color, selected_state)
