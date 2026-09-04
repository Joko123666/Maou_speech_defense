class_name CombatEffectBudget
extends RefCounted

enum Priority { MINOR, STANDARD, IMPORTANT, CRITICAL }

const LIMIT_AT_1X: int = 64
const LIMIT_AT_2X: int = 52
const LIMIT_AT_3X: int = 40
const MINOR_RESERVE: int = 16
const STANDARD_RESERVE: int = 8
const ABSOLUTE_LIMIT: int = 80

static func active_limit(speed: float) -> int:
	if speed >= 2.5:
		return LIMIT_AT_3X
	if speed >= 1.5:
		return LIMIT_AT_2X
	return LIMIT_AT_1X

static func can_spawn(active_effects: int, speed: float, priority: int) -> bool:
	var active := maxi(active_effects, 0)
	if priority == Priority.CRITICAL:
		return active < ABSOLUTE_LIMIT
	var limit := active_limit(speed)
	if priority == Priority.MINOR:
		limit = maxi(limit - MINOR_RESERVE, 1)
	elif priority == Priority.STANDARD:
		limit = maxi(limit - STANDARD_RESERVE, 1)
	return active < limit

static func priority_for_intensity(intensity: float) -> int:
	if intensity >= 0.9:
		return Priority.IMPORTANT
	if intensity >= 0.5:
		return Priority.STANDARD
	return Priority.MINOR

static func priority_name(priority: int) -> StringName:
	match priority:
		Priority.MINOR: return &"minor"
		Priority.STANDARD: return &"standard"
		Priority.IMPORTANT: return &"important"
		Priority.CRITICAL: return &"critical"
	return &"unknown"
