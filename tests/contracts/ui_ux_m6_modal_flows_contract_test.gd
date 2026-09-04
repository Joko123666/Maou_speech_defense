class_name UiUxM6ModalFlowsContractTest
extends RefCounted

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_test_preparation_modal(root, failures)
	_test_artifact_modal(root, failures)
	_test_pause_modal(root, failures)
	_test_result_modal(root, failures)
	_test_static_modal_scene_structure(failures)
	_test_settlement_boundary(failures)
	return failures

static func _test_preparation_modal(root: Node, failures: Array[String]) -> void:
	var panel := PreparationPanel.new()
	root.add_child(panel)
	_expect(panel.modal_shell != null and panel.modal_shell.get_body().is_ancestor_of(panel.grid), "M6 preparation must mount its board inside ModalShell's scrollable body", failures)
	_expect(panel.modal_shell.get_footer().is_ancestor_of(panel.confirm_button) and panel.modal_shell.get_footer().is_ancestor_of(panel.abandon_button), "M6 preparation must keep confirm and abandon actions in the fixed modal footer", failures)
	_expect(panel.confirm_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN and panel.abandon_button.custom_minimum_size.y >= UiTokens.TOUCH_TARGET_MIN, "M6 preparation actions must preserve touch-sized focus targets", failures)
	_expect(panel.abandon_dialog != null and panel.abandon_dialog.get_ok_button().text == "배치 포기", "M6 formation abandonment must retain an explicit confirmation step", failures)
	panel.queue_free()

static func _test_artifact_modal(root: Node, failures: Array[String]) -> void:
	var catalog := load(ArtifactEffectResolver.CATALOG_PATH) as ArtifactCatalogData
	var panel := (load("res://scenes/ui/artifact_resolution_panel.tscn") as PackedScene).instantiate() as ArtifactResolutionPanel
	root.add_child(panel)
	var equipped: Array[ArtifactData] = []
	for artifact in catalog.artifacts.slice(0, 6):
		equipped.append(artifact)
	panel.show_resolution(catalog.artifacts[6], equipped)
	var discards := {"count": 0}
	panel.discard_requested.connect(func() -> void: discards.count += 1)
	panel.discard_button.pressed.emit()
	_expect(panel.modal_shell.get_body().is_ancestor_of(panel.slot_buttons[0]) and panel.modal_shell.get_footer().is_ancestor_of(panel.discard_button), "M6 artifact replacement must use the shared modal body and fixed danger footer", failures)
	_expect(panel.discard_dialog.visible and int(discards.count) == 0 and panel.pending_artifact != null, "M6 artifact discard must pause the reward decision until confirmation", failures)
	panel.discard_dialog.confirmed.emit()
	_expect(int(discards.count) == 1, "M6 confirmed artifact discard must emit exactly one existing discard signal", failures)
	panel.hide_panel()
	panel.queue_free()

static func _test_pause_modal(root: Node, failures: Array[String]) -> void:
	var menu := (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	menu.persist_options = false
	root.add_child(menu)
	var resumes := {"count": 0}
	var quits := {"count": 0}
	menu.resume_requested.connect(func() -> void: resumes.count += 1)
	menu.quit_requested.connect(func() -> void: quits.count += 1)
	menu.show_menu()
	(menu.get_node("%QuitButton") as Button).pressed.emit()
	_expect(menu.modal_shell.get_body().is_ancestor_of(menu.main_page) and menu.modal_shell.get_body().is_ancestor_of(menu.options_page), "M6 pause and options pages must share one ModalShell body", failures)
	_expect(menu.quit_dialog.visible and int(quits.count) == 0, "M6 run abandonment must require confirmation before returning to the title", failures)
	menu.quit_dialog.confirmed.emit()
	(menu.get_node("%ContinueButton") as Button).pressed.emit()
	_expect(int(quits.count) == 1 and int(resumes.count) == 1, "M6 pause modal must preserve the existing quit and resume signals exactly once", failures)
	menu.hide_menu()
	var phase_coordinator := GamePhaseCoordinator.new()
	phase_coordinator.enter_boss_battle()
	var pause_coordinator := RunPauseCoordinator.new()
	pause_coordinator.configure(phase_coordinator, root.get_tree(), menu)
	var before_pause := {"count": 0}
	_expect(pause_coordinator.open(func() -> void: before_pause.count += 1), "the run pause coordinator must accept a manual pause from active combat", failures)
	var duplicate_opened := pause_coordinator.open(func() -> void: before_pause.count += 1)
	_expect(not duplicate_opened and int(before_pause.count) == 1 and root.get_tree().paused and menu.visible and phase_coordinator.current_phase == GameTypes.GamePhase.PAUSED and phase_coordinator.phase_before_pause == GameTypes.GamePhase.BOSS_BATTLE, "manual pause must atomically preserve the previous phase and reject duplicate cleanup or menu transitions", failures)
	_expect(pause_coordinator.close() and not root.get_tree().paused and not menu.visible and phase_coordinator.current_phase == GameTypes.GamePhase.BOSS_BATTLE, "closing manual pause must restore the captured combat phase and unpause the scene tree", failures)
	phase_coordinator.enter_running()
	pause_coordinator.open()
	pause_coordinator.finish_run(true)
	_expect(phase_coordinator.current_phase == GameTypes.GamePhase.VICTORY and not phase_coordinator.pause_open and not root.get_tree().paused and not menu.visible, "terminal run settlement must clear manual pause, hide its modal, and leave the result interactive", failures)
	phase_coordinator.enter_running()
	pause_coordinator.open()
	pause_coordinator.clear_for_navigation()
	_expect(not phase_coordinator.pause_open and phase_coordinator.current_phase == GameTypes.GamePhase.RUNNING and not root.get_tree().paused and not menu.visible, "scene navigation cleanup must restore the captured phase and clear every manual pause surface before reloading or leaving the run", failures)
	menu.queue_free()

static func _test_result_modal(root: Node, failures: Array[String]) -> void:
	var overlay := (load("res://scenes/ui/components/combat_result_overlay.tscn") as PackedScene).instantiate() as CombatResultOverlay
	root.add_child(overlay)
	var restart_count := {"value": 0}
	var menu_count := {"value": 0}
	overlay.restart_button.pressed.connect(func() -> void: restart_count.value += 1)
	overlay.menu_button.pressed.connect(func() -> void: menu_count.value += 1)
	overlay.detail_label.text = "긴 결과 표본\n".repeat(48)
	overlay.show_overlay()
	overlay.restart_button.pressed.emit()
	overlay.menu_button.pressed.emit()
	_expect(overlay.panel == overlay.modal_shell.panel and overlay.backdrop == overlay.modal_shell.dimmer, "M6 result overlay must expose the shared ModalShell panel and backdrop to the HUD", failures)
	_expect(overlay.modal_shell.get_body().is_ancestor_of(overlay.detail_label) and overlay.modal_shell.get_footer().is_ancestor_of(overlay.restart_button), "M6 result details must scroll independently from fixed navigation actions", failures)
	_expect(overlay.modal_shell.get_body_scroll().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and overlay.modal_shell.panel.custom_minimum_size.y <= 650.0, "M6 long result samples must use bounded vertical scrolling within the 720p modal", failures)
	_expect(int(restart_count.value) == 1 and int(menu_count.value) == 1, "M6 result modal must preserve restart and title-navigation signals", failures)
	overlay.hide_overlay()
	overlay.queue_free()

static func _test_static_modal_scene_structure(failures: Array[String]) -> void:
	var scripts := "\n".join([
		FileAccess.get_file_as_string("res://scripts/ui/artifact_resolution_panel.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/pause_menu.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/components/combat_result_overlay.gd"),
	])
	var scenes := "\n".join([
		FileAccess.get_file_as_string("res://scenes/ui/artifact_resolution_panel.tscn"),
		FileAccess.get_file_as_string("res://scenes/ui/pause_menu.tscn"),
		FileAccess.get_file_as_string("res://scenes/ui/components/combat_result_overlay.tscn"),
	])
	_expect(not scripts.contains(".reparent("), "M6 artifact, pause, and result modals must not reparent legacy scene content at runtime", failures)
	_expect(not scenes.contains("ResultBackdrop") and not scenes.contains("ResultPanel") and not scenes.contains("ResultTitle"), "M6 result modal scene must not retain its retired backdrop, panel, or duplicate title shell", failures)
	_expect(not scenes.contains("[node name=\"Dim\"") and not scenes.contains("[node name=\"Dimmer\" type=\"ColorRect\" parent=\".\"]"), "M6 artifact and pause modal scenes must inherit the shared dimmer instead of declaring legacy copies", failures)

static func _test_settlement_boundary(failures: Array[String]) -> void:
	var presentation_sources := "\n".join([
		FileAccess.get_file_as_string("res://scripts/ui/preparation_panel.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/artifact_resolution_panel.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/components/combat_result_overlay.gd"),
		FileAccess.get_file_as_string("res://scripts/ui/hud.gd"),
	])
	_expect(not presentation_sources.contains("RunCheckpointService") and not presentation_sources.contains("_apply_run_settlement"), "M6 presentation components must remain isolated from run checkpoint and settlement authority", failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
