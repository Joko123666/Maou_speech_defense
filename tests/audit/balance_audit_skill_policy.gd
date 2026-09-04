class_name BalanceAuditSkillPolicy
extends RefCounted

const IDS: Array[StringName] = [&"high", &"average", &"low"]

var id: StringName = &"high"

func _init(policy_id: StringName = &"high") -> void:
	id = policy_id if policy_id in IDS else &"high"

func component_ids() -> Dictionary:
	return {"movement": String(id), "active": String(id), "placement": String(id)}
