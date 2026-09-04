class_name CombatMotionProfileContractTest
extends RefCounted

const TOWER_BEHAVIORS := [
	&"rapid", &"area", &"pierce", &"slow", &"knockback", &"execute", &"mark", &"chain",
	&"unique_single", &"unique_pierce", &"unique_radial", &"unique_random",
]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var tower_signatures: Dictionary = {}
	for behavior in TOWER_BEHAVIORS:
		var pose := CombatMotionProfile.tower_pose(behavior, 1.0, 0.7)
		_validate_pose(pose, "tower behavior '%s'" % behavior, failures)
		var scale: Vector2 = pose.scale
		var offset: Vector2 = pose.offset
		var signature := "%0.3f/%0.3f/%0.3f/%0.3f/%0.3f" % [scale.x, scale.y, offset.x, offset.y, float(pose.rotation)]
		tower_signatures[signature] = true
	_expect(tower_signatures.size() >= 7, "tower attack motion must expose at least seven visibly distinct pose signatures", failures)
	var rapid := CombatMotionProfile.tower_pose(&"rapid", 1.0, 0.0)
	var blast := CombatMotionProfile.tower_pose(&"area", 1.0, 0.0)
	var saw := CombatMotionProfile.tower_pose(&"knockback", 1.0, 0.0)
	var rapid_offset: Vector2 = rapid.offset
	var rapid_scale: Vector2 = rapid.scale
	var blast_scale: Vector2 = blast.scale
	_expect(rapid_offset.x < 0.0 and rapid_scale.x < rapid_scale.y, "rapid attacks must recoil backward and compress horizontally", failures)
	_expect(blast_scale.y > 1.1 and float(blast.rotation) < 0.0, "blast attacks must use a tall compression pose with barrel kick", failures)
	_expect(absf(float(saw.rotation)) >= 0.15, "saw attacks must visibly rotate the tower body", failures)
	var core_signatures: Dictionary = {}
	for skill_type in [&"beam", &"radial", &"wall", &"barrage"]:
		var pose := CombatMotionProfile.core_pose(skill_type, 0.58, 0.0, 0.0, 0.0)
		_validate_pose(pose, "core skill '%s'" % skill_type, failures)
		var scale: Vector2 = pose.scale
		var offset: Vector2 = pose.offset
		core_signatures["%0.3f/%0.3f/%0.3f/%0.3f" % [scale.x, scale.y, float(pose.rotation), offset.y]] = true
	_expect(core_signatures.size() == 4, "the four core skill motion families must use distinct anticipation poses", failures)
	var idle := CombatMotionProfile.core_pose(&"beam", 0.0, 0.0, 0.0, 0.0)
	var released := CombatMotionProfile.core_pose(&"beam", 0.0, 0.0, 1.0, 0.0)
	var idle_scale: Vector2 = idle.scale
	var released_scale: Vector2 = released.scale
	_expect(released_scale.length() > idle_scale.length() and float(released.rotation) > 0.0, "core skill release must overshoot beyond the idle pose", failures)
	return failures

static func _validate_pose(pose: Dictionary, label: String, failures: Array[String]) -> void:
	var scale: Vector2 = pose.get("scale", Vector2.ZERO)
	var offset: Vector2 = pose.get("offset", Vector2.ZERO)
	var rotation := float(pose.get("rotation", 0.0))
	_expect(is_finite(scale.x) and is_finite(scale.y) and scale.x >= 0.75 and scale.x <= 1.3 and scale.y >= 0.75 and scale.y <= 1.3, "%s must keep a finite readable scale" % label, failures)
	_expect(is_finite(offset.x) and is_finite(offset.y) and offset.length() <= 10.0, "%s must keep motion inside its battlefield slot" % label, failures)
	_expect(is_finite(rotation) and absf(rotation) <= 0.25, "%s must keep rotation subtle enough for sprite readability" % label, failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
