class_name UiUxM3CombatHudContractTest
extends RefCounted

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	var hud := (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate() as GameHUD
	root.add_child(hud)
	var top_bar := hud.get_node("TopBar") as HBoxContainer
	var effect_rail := hud.get_node("EffectPanels") as VBoxContainer
	var battle_rect := Rect2(150.0, 105.0, 1060.0, 540.0)
	_expect(top_bar.offset_bottom <= battle_rect.position.y, "M3 top groups must stay above the frozen battlefield rect", failures)
	_expect(effect_rail.offset_right <= battle_rect.position.x and effect_rail.mouse_filter == Control.MOUSE_FILTER_IGNORE, "M3 status and artifact rail must stay in the left peripheral margin without blocking input", failures)
	_expect(not hud.bottom_info.visible and hud.bottom_info_toggle.position.x < battle_rect.position.x and hud.bottom_info_toggle.position.y >= battle_rect.end.y and hud.bottom_info_toggle.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN, "M3 long build help must be folded behind a touch-sized control in the lower-left peripheral margin by default", failures)
	_expect(top_bar.has_node("RunContextPanel") and top_bar.has_node("CenterStatusPanel") and top_bar.has_node("CombatActionsPanel"), "M3 top HUD must separate run rules, time/boss status, and combat actions", failures)
	_expect([hud.skill_button, hud.speed_button, hud.range_button, hud.pause_button].all(func(button: Button) -> bool: return button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and button.focus_mode == Control.FOCUS_ALL), "M3 combat actions must remain touch and keyboard focus targets", failures)
	_expect(hud.global_list.columns == 3 and hud.artifact_list.columns == 3, "M3 peripheral effects must use compact three-column icon rails", failures)
	hud.set_run_identity("죽음교주 주다긴다", "죽음교 돌격부대", 3, "심판의 종")
	_expect((hud.get_node("%RunIdentity") as Label).text.begins_with("도전 3 · 칙령 심판의 종"), "M3 run badge must prioritize challenge and decree before long actor names", failures)

	for multiplier in [1.0, 2.0, 3.0]:
		hud.update_game_speed(multiplier)
		_expect(hud.speed_button.text.contains("%d×" % roundi(multiplier)), "M3 speed control must stay synchronized at %d×" % roundi(multiplier), failures)
	hud.update_faction_prelude({"active": true, "tier": 3, "current_seconds": 30.0, "end_seconds": 90.0}, "마왕 정통파", UiTokens.ACCENT_GOLD)
	_expect(hud.event_frame.visible and hud.prelude_label.visible and hud.prelude_label.text.contains("T3"), "M3 right event frame must surface the active faction Prelude", failures)
	hud.show_boss("파르태손 8세", UiTokens.FACTION_BOSS)
	_expect(hud.boss_panel.visible and not hud.prelude_label.visible and not hud.experience_bar.visible and top_bar.get_combined_minimum_size().y <= top_bar.size.y, "M3 boss status must replace regular progress inside the fixed top group without overflow", failures)
	hud.hide_boss()
	_expect(not hud.boss_panel.visible and hud.prelude_label.visible and hud.experience_bar.visible, "M3 regular progress and Prelude status must restore after the boss panel closes", failures)
	hud.show_warning("Y34 지점 공식 난입", UiTokens.DANGER)
	_expect(hud.event_frame.visible and hud.warning_label.visible and hud.warning_label.text.contains("공식 난입"), "M3 spawn warnings must use the non-blocking right event frame", failures)

	hud.set_tutorial_mode(true)
	_expect(not hud.speed_button.visible and not hud.range_button.visible and not hud.artifact_panel.visible and not hud.prelude_label.visible, "M3 tutorial HUD must preserve prohibited-control visibility rules", failures)
	hud.set_tutorial_step(0, 6, "후보를 보호하며 심복을 이동하세요.")
	_expect(hud.warning_label.visible and hud.warning_label.text.contains("훈련 1/6"), "M3 tutorial step guidance must remain visible in the event frame", failures)
	hud.set_tutorial_mode(false)

	_expect(hud.result_overlay.scene_file_path == "res://scenes/ui/components/combat_result_overlay.tscn" and hud.result_overlay.is_ancestor_of(hud.result_panel), "M3 result presentation must be separated from the combat HUD scene", failures)
	_expect(not hud.result_panel.visible and hud.restart_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and hud.menu_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN, "the separated result overlay must retain hidden initial state and touch-sized navigation", failures)
	hud.queue_free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
