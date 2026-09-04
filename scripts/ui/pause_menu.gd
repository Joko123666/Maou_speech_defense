class_name PauseMenu
extends UiModalShell

signal resume_requested
signal quit_requested
signal shake_toggled(enabled: bool)
signal flash_toggled(enabled: bool)
signal reduced_motion_toggled(enabled: bool)

@onready var main_page: VBoxContainer = %MainPage
@onready var options_page: VBoxContainer = %OptionsPage
@onready var sound_toggle: CheckButton = %SoundToggle
@onready var shake_toggle: CheckButton = %ShakeToggle
@onready var flash_toggle: CheckButton = %FlashToggle
@onready var reduced_motion_toggle: CheckButton = %ReducedMotionToggle

var persist_options: bool = true
var modal_shell: UiModalShell
var quit_dialog: ConfirmationDialog

func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS
	modal_shell = self
	configure("일시정지", false)
	set_panel_minimum_size(Vector2(520.0, 650.0))
	%QuitButton.text = "출격 포기"
	main_page.get_node("Status").text = "공식 난입 제압 시점마다 진행 보상이 확정됩니다."
	main_page.get_node("QuitHint").text = "포기하면 마지막 공식 난입 체크포인트까지만 정산하고 유세 본부로 돌아갑니다."
	main_page.get_node("Title").hide()
	options_page.get_node("Title").hide()
	for page in [main_page, options_page]:
		for label in (page as Control).find_children("*", "Label", true, false):
			(label as Label).add_theme_color_override(&"font_color", UiTokens.INK_MUTED)
	var main_eyebrow := main_page.get_node("Eyebrow") as Label
	var options_eyebrow := options_page.get_node("Eyebrow") as Label
	main_eyebrow.add_theme_color_override(&"font_color", UiTokens.ACCENT_GOLD_TEXT)
	options_eyebrow.add_theme_color_override(&"font_color", UiTokens.ACCENT_GOLD_TEXT)
	for button in [%ContinueButton, %OptionsButton, %OptionsBackButton]:
		UiStyleFactory.apply_button(button as Button, UiTokens.INK_ROYAL)
	UiStyleFactory.apply_button(%ContinueButton as Button, UiTokens.ACCENT_GOLD, true)
	UiStyleFactory.apply_button(%QuitButton as Button, UiTokens.DANGER, false, true)
	for toggle in [sound_toggle, shake_toggle, flash_toggle, reduced_motion_toggle]:
		(toggle as CheckButton).custom_minimum_size.y = UiTokens.TOUCH_TARGET_MIN
		(toggle as CheckButton).focus_mode = Control.FOCUS_ALL
		for color_key in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
			(toggle as CheckButton).add_theme_color_override(color_key, UiTokens.INK_ROYAL)
	for option_panel in options_page.find_children("*", "PanelContainer", true, false):
		(option_panel as PanelContainer).add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED, UiTokens.INK_MUTED, UiTokens.RADIUS_SMALL, 1, float(UiTokens.SPACE_3)))
	_install_quit_confirmation()
	%ContinueButton.pressed.connect(func() -> void: resume_requested.emit())
	%OptionsButton.pressed.connect(show_options)
	%QuitButton.pressed.connect(_request_quit)
	%OptionsBackButton.pressed.connect(show_main)
	sound_toggle.toggled.connect(_on_sound_toggled)
	shake_toggle.toggled.connect(_on_shake_toggled)
	flash_toggle.toggled.connect(_on_flash_toggled)
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	hide_menu()
func _install_quit_confirmation() -> void:
	quit_dialog = ConfirmationDialog.new()
	quit_dialog.title = "출격 포기"
	quit_dialog.dialog_text = "현재 출격을 포기하시겠습니까?\n\n마지막 공식 난입 체크포인트까지만 정산하고 유세 본부로 돌아갑니다."
	quit_dialog.ok_button_text = "출격 포기"
	quit_dialog.cancel_button_text = "전투 계속"
	quit_dialog.confirmed.connect(func() -> void: quit_requested.emit())
	add_child(quit_dialog)
	UiStyleFactory.apply_button(quit_dialog.get_ok_button(), UiTokens.DANGER, false, true)
	UiStyleFactory.apply_button(quit_dialog.get_cancel_button(), UiTokens.INK_ROYAL)

func _request_quit() -> void:
	quit_dialog.popup_centered(Vector2i(620, 260))

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed(&"ui_cancel"):
		return
	if options_page.visible:
		show_main()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()

func show_menu() -> void:
	visible = true
	sound_toggle.set_pressed_no_signal(not AudioManager.muted)
	shake_toggle.set_pressed_no_signal(GameSession.screen_shake_enabled)
	flash_toggle.set_pressed_no_signal(GameSession.screen_flash_enabled)
	reduced_motion_toggle.set_pressed_no_signal(GameSession.reduced_motion_enabled)
	show_main(false)
	modal_shell.show_modal(%ContinueButton)

func hide_menu() -> void:
	if quit_dialog != null:
		quit_dialog.hide()
	if modal_shell != null:
		modal_shell.hide_modal()
	visible = false
	main_page.visible = true
	options_page.visible = false

func show_main(play_sound: bool = true) -> void:
	modal_shell.configure("일시정지", false)
	modal_shell.set_panel_minimum_size(Vector2(520.0, 520.0))
	main_page.visible = true
	options_page.visible = false
	modal_shell.get_body_scroll().scroll_vertical = 0
	if play_sound:
		AudioManager.play_ui()
	%ContinueButton.grab_focus.call_deferred()
	modal_shell.refresh_focus_cycle(%ContinueButton)

func show_options() -> void:
	modal_shell.configure("전투 옵션", false)
	modal_shell.set_panel_minimum_size(Vector2(520.0, 650.0))
	main_page.visible = false
	options_page.visible = true
	modal_shell.get_body_scroll().scroll_vertical = 0
	AudioManager.play_ui()
	modal_shell.refresh_focus_cycle(sound_toggle)

func _on_sound_toggled(enabled: bool) -> void:
	AudioManager.muted = not enabled
	if persist_options:
		SaveManager.set_sound_enabled(enabled)
	if enabled:
		AudioManager.play_ui()

func _on_shake_toggled(enabled: bool) -> void:
	GameSession.screen_shake_enabled = enabled
	if persist_options:
		SaveManager.set_screen_shake_enabled(enabled)
	shake_toggled.emit(enabled)
	AudioManager.play_ui()

func _on_flash_toggled(enabled: bool) -> void:
	GameSession.screen_flash_enabled = enabled
	if persist_options:
		SaveManager.set_screen_flash_enabled(enabled)
	flash_toggled.emit(enabled)
	AudioManager.play_ui()

func _on_reduced_motion_toggled(enabled: bool) -> void:
	GameSession.reduced_motion_enabled = enabled
	if persist_options:
		SaveManager.set_reduced_motion_enabled(enabled)
	reduced_motion_toggled.emit(enabled)
	AudioManager.play_ui()
