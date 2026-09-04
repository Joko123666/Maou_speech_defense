class_name BalanceAuditActivePolicy
extends RefCounted

var id: StringName = &"high"
var core_ready_since: float = -1.0
var low_cast_serial: int = 0

func _init(policy_id: StringName = &"high") -> void:
	id = policy_id if policy_id in BalanceAuditSkillPolicy.IDS else &"high"

func should_cast_core_skill(ready: bool, elapsed: float) -> bool:
	if not ready:
		core_ready_since = -1.0
		return false
	if core_ready_since < 0.0:
		core_ready_since = elapsed
	var delay: float = float({&"high": 0.0, &"average": 1.5, &"low": 8.0}.get(id, 1.5))
	if elapsed - core_ready_since < delay:
		return false
	if id == &"low":
		low_cast_serial += 1
		if low_cast_serial % 2 == 1:
			core_ready_since = elapsed
			return false
	core_ready_since = -1.0
	return true
