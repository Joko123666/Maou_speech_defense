class_name RetainerMotionProfileContractTest
extends RefCounted

const CURSOR_IDS := [&"iron", &"silver", &"gold", &"platinum", &"vanguard"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var attack_signatures: Dictionary = {}
	for cursor_id in CURSOR_IDS:
		var pose := RetainerMotionProfile.pose(cursor_id, 0.0, Vector2.ZERO, 1.0, &"ready", 1.0, 0.7)
		_validate_pose(pose, "retainer '%s' attack" % cursor_id, failures)
		var scale: Vector2 = pose.scale
		var offset: Vector2 = pose.offset
		attack_signatures["%0.3f/%0.3f/%0.3f/%0.3f/%0.3f" % [scale.x, scale.y, offset.x, offset.y, float(pose.rotation)]] = true
	_expect(attack_signatures.size() == CURSOR_IDS.size(), "all five retainers must expose distinct attack pose signatures", failures)
	var iron_move := RetainerMotionProfile.pose(&"iron", 1.0, Vector2(1.0, 0.5), 0.0, &"ready", 1.0, 0.0)
	var platinum_attack := RetainerMotionProfile.pose(&"platinum", 0.0, Vector2.ZERO, 1.0, &"ready", 1.0, 0.0)
	var vanguard_attack := RetainerMotionProfile.pose(&"vanguard", 0.0, Vector2.ZERO, 1.0, &"ready", 1.0, 0.0)
	var iron_offset: Vector2 = iron_move.offset
	var platinum_offset: Vector2 = platinum_attack.offset
	_expect(iron_offset.x > 0.0 and absf(float(iron_move.rotation)) > 0.0, "Iron movement must lean toward the commanded direction", failures)
	_expect(platinum_offset.x > 0.0 and float(platinum_attack.rotation) >= -0.01, "Platinum must lunge forward during its combo-oriented attack", failures)
	_expect(float(vanguard_attack.rotation) < -0.05, "Vanguard must use a readable marching strike rotation", failures)
	var broken := RetainerMotionProfile.pose(&"platinum", 0.0, Vector2.ZERO, 0.0, &"reconstructing", 0.0, 0.0)
	var assembled := RetainerMotionProfile.pose(&"platinum", 0.0, Vector2.ZERO, 0.0, &"reconstructing", 1.0, 0.0)
	_validate_pose(broken, "retainer reconstruction start", failures)
	_validate_pose(assembled, "retainer reconstruction finish", failures)
	var broken_scale: Vector2 = broken.scale
	var assembled_scale: Vector2 = assembled.scale
	_expect(float(broken.alpha) < 0.5 and broken_scale.y < assembled_scale.y and is_equal_approx(float(assembled.alpha), 1.0), "reconstruction must visibly assemble from a faded collapsed pose into the ready body", failures)
	return failures

static func _validate_pose(pose: Dictionary, label: String, failures: Array[String]) -> void:
	var scale: Vector2 = pose.get("scale", Vector2.ZERO)
	var offset: Vector2 = pose.get("offset", Vector2.ZERO)
	var rotation := float(pose.get("rotation", 0.0))
	var alpha := float(pose.get("alpha", 0.0))
	_expect(is_finite(scale.x) and is_finite(scale.y) and scale.x >= 0.65 and scale.x <= 1.3 and scale.y >= 0.65 and scale.y <= 1.3, "%s must keep a finite readable scale" % label, failures)
	_expect(is_finite(offset.x) and is_finite(offset.y) and offset.length() <= 10.0, "%s must stay inside the retainer command marker" % label, failures)
	_expect(is_finite(rotation) and absf(rotation) <= 0.25, "%s must keep rotation readable" % label, failures)
	_expect(is_finite(alpha) and alpha >= 0.3 and alpha <= 1.0, "%s must preserve a visible silhouette" % label, failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
