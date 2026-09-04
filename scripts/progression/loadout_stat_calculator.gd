class_name LoadoutStatCalculator
extends RefCounted

var _curves: Dictionary = {}
var _core_state: GrowthTrackState
var _cursor_state: GrowthTrackState
var _active_decree: CandidateDecreeData

func configure(curves: Dictionary, core_state: GrowthTrackState, cursor_state: GrowthTrackState, active_decree: CandidateDecreeData) -> void:
	_curves = curves
	_core_state = core_state
	_cursor_state = cursor_state
	_active_decree = active_decree

func tower_damage_multiplier(global_upgrade_level: int) -> float:
	return (1.0 + global_upgrade_level * 0.07) * decree_multiplier(&"tower_damage")

func tower_speed_multiplier(global_upgrade_level: int) -> float:
	return CombatModifierResolver.additive_multiplier([
		1.0 + global_upgrade_level * 0.035,
		decree_multiplier(&"tower_speed"),
	])

func core_damage_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"core_damage", _core_state) * float(branch_modifiers.get("damage", 1.0)) * decree_multiplier(&"core_damage")

func core_health_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"core_health", _core_state) * float(branch_modifiers.get("health", 1.0)) * decree_multiplier(&"core_health")

func core_regeneration_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"core_regeneration", _core_state) * float(branch_modifiers.get("regeneration", 1.0))

func core_skill_damage_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"core_skill", _core_state) * float(branch_modifiers.get("damage", 1.0)) * decree_multiplier(&"core_skill_damage")

func core_attack_speed_multiplier(branch_modifiers: Dictionary) -> float:
	return CombatModifierResolver.additive_multiplier([
		float(branch_modifiers.get("overheat_speed", 1.0)),
		decree_multiplier(&"core_attack_speed"),
	])

func cursor_damage_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"cursor_damage", _cursor_state) * float(branch_modifiers.get("damage", 1.0)) * decree_multiplier(&"cursor_damage")

func cursor_movement_speed_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"cursor_movement", _cursor_state) * float(branch_modifiers.get("movement", 1.0)) * decree_multiplier(&"cursor_movement")

func cursor_area_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"cursor_area", _cursor_state) * float(branch_modifiers.get("area", 1.0)) * decree_multiplier(&"cursor_area")

func cursor_control_multiplier(branch_modifiers: Dictionary) -> float:
	return _track_curve(&"cursor_control", _cursor_state) * float(branch_modifiers.get("knockback", 1.0)) * decree_multiplier(&"cursor_control")

func decree_multiplier(stat_key: StringName) -> float:
	return _active_decree.multiplier(stat_key) if _active_decree != null else 1.0

func level_curve_value(curve: Array[float], level: int) -> float:
	return curve[clampi(level, 1, curve.size() - 1)]

func _track_curve(curve_id: StringName, state: GrowthTrackState) -> float:
	var curve: Array[float] = _curves.get(curve_id, [1.0, 1.0])
	return level_curve_value(curve, state.current_level if state != null else 1)
