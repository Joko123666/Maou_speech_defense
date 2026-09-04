extends SceneTree

const MAIN_MENU_PATH := "res://scenes/main/main_menu.tscn"

func _initialize() -> void:
	Input.set_emulate_touch_from_mouse(true)
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node("SaveManager")
	var progression_service := root.get_node("MetaProgressionService")
	var audio_manager := root.get_node("AudioManager")
	audio_manager.set("muted", true)
	save_manager.set("tutorial_completed", true)
	progression_service.call("set_testing_content_lock_bypass", true)
	if change_scene_to_file(MAIN_MENU_PATH) != OK:
		_fail("main menu scene could not load")
		return
	await process_frame
	await process_frame
	var menu := current_scene

	var pointer_press := InputEventMouseButton.new()
	pointer_press.button_index = MOUSE_BUTTON_LEFT
	pointer_press.pressed = true
	menu.call("_input", pointer_press)
	menu.call("_enter_main_hub")
	await process_frame
	await process_frame
	if bool(menu.get("directional_focus_active")) or root.gui_get_focus_owner() != null:
		_fail("pointer navigation left a keyboard focus highlight in the hub")
		return

	menu.call("show_page", 3, false)
	await process_frame
	await process_frame
	await process_frame
	var browser: Control = menu.get("achievement_browser") as Control
	var scroll := browser.get("scroll_container") as ScrollContainer
	if scroll == null or scroll.get_v_scroll_bar().max_value <= scroll.size.y:
		_fail("achievement list is not vertically scrollable in the probe viewport")
		return
	var start := scroll.get_global_rect().get_center() + Vector2(0.0, 120.0)
	_push_mouse_button(start, true)
	for step in range(1, 7):
		var motion := InputEventMouseMotion.new()
		motion.position = start - Vector2(0.0, step * 55.0)
		motion.global_position = motion.position
		motion.relative = Vector2(0.0, -55.0)
		root.push_input(motion, false)
		await process_frame
	_push_mouse_button(start - Vector2(0.0, 330.0), false)
	await process_frame
	await process_frame
	if scroll.scroll_vertical <= 0:
		_fail("drag gesture did not move the achievement ScrollContainer")
		return

	var key_press := InputEventKey.new()
	key_press.keycode = KEY_TAB
	key_press.pressed = true
	menu.call("_input", key_press)
	menu.call("show_page", 0, false)
	await process_frame
	await process_frame
	if not bool(menu.get("directional_focus_active")) or root.gui_get_focus_owner() == null:
		_fail("keyboard navigation did not restore an accessible focus target")
		return

	print("MOBILE INPUT RUNTIME PASS")
	call_deferred("_finish", 0)

func _finish(exit_code: int) -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.call("stop_all")
	unload_current_scene()
	await process_frame
	await process_frame
	quit(exit_code)

func _push_mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	root.push_input(event, false)

func _fail(message: String) -> void:
	print("MOBILE INPUT RUNTIME FAIL: %s" % message)
	call_deferred("_finish", 1)
