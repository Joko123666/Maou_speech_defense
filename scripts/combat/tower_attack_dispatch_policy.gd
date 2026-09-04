class_name TowerAttackDispatchPolicy
extends RefCounted

const PROJECTILE_BEHAVIORS: Array[StringName] = [&"rapid", &"area", &"unique_single"]
const PIERCE_BEHAVIORS: Array[StringName] = [&"pierce", &"unique_pierce"]
const CONTROL_BEHAVIORS: Array[StringName] = [&"slow", &"knockback", &"golem"]
const PRECISION_BEHAVIORS: Array[StringName] = [&"execute", &"mark"]
const NETWORK_BEHAVIORS: Array[StringName] = [&"chain"]
const UNIQUE_FIELD_BEHAVIORS: Array[StringName] = [&"unique_radial", &"unique_random"]

func family_for(behavior: StringName) -> StringName:
	if behavior in PROJECTILE_BEHAVIORS:
		return &"projectile"
	if behavior in PIERCE_BEHAVIORS:
		return &"pierce"
	if behavior in CONTROL_BEHAVIORS:
		return &"control"
	if behavior in PRECISION_BEHAVIORS:
		return &"precision"
	if behavior in NETWORK_BEHAVIORS:
		return &"network"
	if behavior in UNIQUE_FIELD_BEHAVIORS:
		return &"unique_field"
	return &"direct"

func uses_projectile(behavior: StringName) -> bool:
	return family_for(behavior) == &"projectile"
