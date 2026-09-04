class_name GameInputPolicy
extends RefCounted

const COMBAT_PHASES: Array[GameTypes.GamePhase] = [
	GameTypes.GamePhase.RUNNING,
	GameTypes.GamePhase.BOSS_WARNING,
	GameTypes.GamePhase.BOSS_BATTLE,
]

func allows_combat_action(phase: GameTypes.GamePhase) -> bool:
	return phase in COMBAT_PHASES

func allows_pause(phase: GameTypes.GamePhase) -> bool:
	return allows_combat_action(phase)

func allows_speed_change(phase: GameTypes.GamePhase) -> bool:
	return allows_combat_action(phase)

func allows_range_inspection(phase: GameTypes.GamePhase) -> bool:
	return allows_combat_action(phase)

func allows_core_skill(phase: GameTypes.GamePhase) -> bool:
	return allows_combat_action(phase)

func allows_restart(phase: GameTypes.GamePhase) -> bool:
	return phase in [GameTypes.GamePhase.VICTORY, GameTypes.GamePhase.DEFEAT]
