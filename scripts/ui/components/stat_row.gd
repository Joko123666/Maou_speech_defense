class_name UiStatRow
extends HBoxContainer

@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel
@onready var change_label: Label = %ChangeLabel

func _ready() -> void:
	custom_minimum_size.y = UiTokens.TAG_HEIGHT
	change_label.visible = not change_label.text.is_empty()

func configure(label_text: String, value_text: String, change_text: String = "", accent: Color = UiTokens.INK_ROYAL) -> void:
	name_label.text = label_text
	value_label.text = value_text
	change_label.text = change_text
	change_label.visible = not change_text.is_empty()
	change_label.add_theme_color_override(&"font_color", accent)
