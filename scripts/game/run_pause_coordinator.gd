class_name RunPauseCoordinator
extends RefCounted

var phase_coordinator: GamePhaseCoordinator
var scene_tree: SceneTree
var pause_menu: PauseMenu

func configure(target_phase: GamePhaseCoordinator, target_tree: SceneTree, target_menu: PauseMenu) -> void:
	phase_coordinator = target_phase
	scene_tree = target_tree
	pause_menu = target_menu

func is_configured() -> bool:
	return phase_coordinator != null and is_instance_valid(scene_tree) and is_instance_valid(pause_menu)

func open(before_pause: Callable = Callable()) -> bool:
	if not is_configured() or not phase_coordinator.open_pause():
		return false
	if before_pause.is_valid():
		before_pause.call()
	pause_menu.show_menu()
	scene_tree.paused = true
	return true

func close() -> bool:
	if not is_configured() or not phase_coordinator.close_pause():
		return false
	scene_tree.paused = false
	pause_menu.hide_menu()
	return true

func finish_run(victory: bool) -> void:
	if not is_configured():
		return
	phase_coordinator.finish(victory)
	pause_menu.hide_menu()
	scene_tree.paused = false

func clear_for_navigation() -> void:
	if not is_configured():
		return
	if phase_coordinator.pause_open:
		phase_coordinator.close_pause()
	else:
		phase_coordinator.clear_pause()
	scene_tree.paused = false
	pause_menu.hide_menu()
