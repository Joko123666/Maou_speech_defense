class_name GamePhaseCoordinator
extends RefCounted

var current_phase: GameTypes.GamePhase = GameTypes.GamePhase.PREPARATION
var pause_open: bool = false
var phase_before_pause: GameTypes.GamePhase = GameTypes.GamePhase.RUNNING

func enter_preparation() -> void:
	current_phase = GameTypes.GamePhase.PREPARATION

func enter_running() -> void:
	current_phase = GameTypes.GamePhase.RUNNING

func enter_boss_warning() -> void:
	current_phase = GameTypes.GamePhase.BOSS_WARNING

func enter_boss_battle() -> void:
	current_phase = GameTypes.GamePhase.BOSS_BATTLE

func enter_level_up() -> void:
	current_phase = GameTypes.GamePhase.LEVEL_UP

func resume_combat(has_active_boss: bool, has_boss_warning: bool) -> GameTypes.GamePhase:
	if has_active_boss:
		enter_boss_battle()
	elif has_boss_warning:
		enter_boss_warning()
	else:
		enter_running()
	return current_phase

func open_pause() -> bool:
	if pause_open:
		return false
	pause_open = true
	phase_before_pause = current_phase
	current_phase = GameTypes.GamePhase.PAUSED
	return true

func close_pause() -> bool:
	if not pause_open:
		return false
	pause_open = false
	current_phase = phase_before_pause
	return true

func finish(victory: bool) -> void:
	pause_open = false
	current_phase = GameTypes.GamePhase.VICTORY if victory else GameTypes.GamePhase.DEFEAT

func clear_pause() -> void:
	pause_open = false
