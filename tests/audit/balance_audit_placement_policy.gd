class_name BalanceAuditPlacementPolicy
extends RefCounted

var id: StringName = &"high"

func _init(policy_id: StringName = &"high") -> void:
	id = policy_id if policy_id in BalanceAuditSkillPolicy.IDS else &"high"

func placement_index(placements: Array) -> int:
	if placements.is_empty():
		return -1
	return placements.size() / 2 if id == &"high" else 0

func selection_reason() -> String:
	return "center visible valid placement" if id == &"high" else "first visible valid placement"
