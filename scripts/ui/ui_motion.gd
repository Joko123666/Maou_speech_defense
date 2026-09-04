class_name UiMotion
extends RefCounted

static func is_reduced() -> bool:
	return GameSession.reduced_motion_enabled

static func should_animate() -> bool:
	return not is_reduced()
