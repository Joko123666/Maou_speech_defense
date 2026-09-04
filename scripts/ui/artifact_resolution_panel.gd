class_name ArtifactResolutionPanel
extends UiModalShell

signal replacement_requested(slot_index: int)
signal discard_requested

@onready var slot_buttons: Array[Button] = [%Slot1, %Slot2, %Slot3, %Slot4, %Slot5, %Slot6]
@onready var discard_button: Button = %DiscardButton
@onready var incoming_name: Label = %IncomingName
@onready var incoming_effect: Label = %IncomingEffect
@onready var hint: Label = %Hint

var pending_artifact: ArtifactData
var modal_shell: UiModalShell
var discard_dialog: ConfirmationDialog

func _ready() -> void:
	super._ready()
	modal_shell = self
	configure("아티팩트 슬롯 교체", false)
	set_panel_minimum_size(Vector2(1120.0, 610.0))
	visible = false
	incoming_name.add_theme_font_size_override(&"font_size", UiTokens.FONT_CARD_TITLE)
	incoming_name.add_theme_color_override(&"font_color", UiTokens.DANGER)
	incoming_effect.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	hint.add_theme_color_override(&"font_color", UiTokens.INK_MUTED)
	for index in slot_buttons.size():
		slot_buttons[index].pressed.connect(_request_replacement.bind(index))
		slot_buttons[index].focus_mode = Control.FOCUS_ALL
	UiStyleFactory.apply_button(discard_button, UiTokens.DANGER, false, true)
	discard_button.pressed.connect(_request_discard)
	_install_discard_confirmation()
func _install_discard_confirmation() -> void:
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "신규 아티팩트 포기"
	discard_dialog.dialog_text = "이 아티팩트를 포기하시겠습니까?\n\n포기하면 현재 보상은 소멸하고 대기 중인 다음 보상으로 진행합니다."
	discard_dialog.ok_button_text = "아티팩트 포기"
	discard_dialog.cancel_button_text = "교체 화면으로"
	discard_dialog.confirmed.connect(_confirm_discard)
	add_child(discard_dialog)
	UiStyleFactory.apply_button(discard_dialog.get_ok_button(), UiTokens.DANGER, false, true)
	UiStyleFactory.apply_button(discard_dialog.get_cancel_button(), UiTokens.INK_ROYAL)

func show_resolution(artifact: ArtifactData, equipped: Array[ArtifactData]) -> void:
	pending_artifact = artifact
	if artifact == null:
		hide_panel()
		return
	incoming_name.text = "신규 제안 · %s" % artifact.display_name
	incoming_name.add_theme_color_override("font_color", artifact.color.darkened(0.18))
	incoming_effect.text = "%s%s" % [artifact.description, "\n⚠ 장점과 단점이 함께 적용됩니다." if artifact.has_trade_off() else ""]
	for index in slot_buttons.size():
		var button := slot_buttons[index]
		if index >= equipped.size() or equipped[index] == null:
			button.visible = false
			button.disabled = true
			continue
		var current := equipped[index]
		button.visible = true
		button.disabled = false
		button.text = "%d · 보유 중\n%s\n\n%s\n\n[%d] 교체" % [index + 1, current.display_name, current.description, index + 1]
		button.tooltip_text = "%s\n%s\n→ %s로 교체" % [current.display_name, current.description, artifact.display_name]
		_apply_slot_style(button, current.color)
	show_modal(slot_buttons[0])

func hide_panel() -> void:
	pending_artifact = null
	if discard_dialog != null:
		discard_dialog.hide()
	hide_modal()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	if event.is_action_pressed(&"ui_cancel"):
		_request_discard()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_6:
		_request_replacement(event.keycode - KEY_1)
		get_viewport().set_input_as_handled()

func _request_replacement(slot_index: int) -> void:
	if not visible or pending_artifact == null or slot_index < 0 or slot_index >= slot_buttons.size() or not slot_buttons[slot_index].visible:
		return
	replacement_requested.emit(slot_index)

func _request_discard() -> void:
	if not visible or pending_artifact == null:
		return
	discard_dialog.popup_centered(Vector2i(620, 260))

func _confirm_discard() -> void:
	if not visible or pending_artifact == null:
		return
	discard_requested.emit()

func _apply_slot_style(button: Button, color: Color) -> void:
	var styles := UiStyleFactory.card(color)
	for key in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(key, styles[key] as StyleBox)
	button.add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	button.add_theme_color_override(&"font_hover_color", UiTokens.INK_DEEP)
	button.add_theme_color_override(&"font_pressed_color", UiTokens.INK_DEEP)
	button.add_theme_color_override(&"font_focus_color", UiTokens.INK_DEEP)
	button.add_theme_color_override(&"font_disabled_color", UiTokens.DISABLED_INK)
